import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/services/rdp_service.dart';
import '../../core/services/storage_service.dart';
import '../../data/models/rdp_connection.dart';

class HomeController extends GetxController {
  HomeController({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  final StorageService _storageService;
  final RdpService _rdpService = RdpService();

  final connections = <RdpConnection>[].obs;
  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final filteredConnections = <RdpConnection>[].obs;

  /// Connection status keyed by the STABLE connection [RdpConnection.id].
  ///
  /// Never keyed by list index (filtering changes indexes) and never by
  /// name/host (they can change through edit).
  final connectionStatuses = <String, RdpStatus>{}.obs;

  @override
  void onInit() {
    super.onInit();

    loadConnections();

    searchController.addListener(() {
      searchQuery.value = searchController.text.trim();
      filterConnections();
    });

    _rdpService.status.listen((status) {
      final activeConnection = _rdpService.activeConnection;

      if (activeConnection != null) {
        connectionStatuses[activeConnection.id] = status;
        connectionStatuses.refresh();
      }
    });
  }

  void filterConnections() {
    final query = searchQuery.value.toLowerCase();

    if (query.isEmpty) {
      filteredConnections.assignAll(connections);
      return;
    }

    filteredConnections.assignAll(
      connections.where((connection) {
        return connection.name.toLowerCase().contains(query) ||
            connection.host.toLowerCase().contains(query) ||
            connection.username.toLowerCase().contains(query);
      }),
    );
  }

  /// Loads connections through the storage migration layer so legacy
  /// records receive stable ids, then refreshes status bookkeeping.
  Future<void> loadConnections() async {
    final loadedConnections = await _storageService.loadConnections();

    loadedConnections.sort((a, b) {
      if (a.favorite == b.favorite) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }

      return a.favorite ? -1 : 1;
    });

    connections.assignAll(loadedConnections);
    filterConnections();

    for (final connection in connections) {
      connectionStatuses[connection.id] = RdpStatus.disconnected;
    }

    // Drop statuses of connections that no longer exist.
    connectionStatuses.removeWhere(
      (id, _) => connections.every((connection) => connection.id != id),
    );

    connectionStatuses.refresh();
  }

  RdpStatus getStatus(RdpConnection connection) {
    return connectionStatuses[connection.id] ?? RdpStatus.disconnected;
  }

  /// Reads the live favorite state of this record from the connections
  /// list (matched by stable id), so the UI never depends on a stale
  /// object or a filtered-list index.
  bool isFavorite(RdpConnection connection) {
    final current = findById(connection.id, fallback: connection);
    return current.favorite;
  }

  /// Finds the current record with this stable id in the live list, or
  /// returns [fallback] when it is no longer present.
  RdpConnection findById(String id, {RdpConnection? fallback}) {
    for (final connection in connections) {
      if (connection.id == id) {
        return connection;
      }
    }

    return fallback ?? connectionFromId(id);
  }

  RdpConnection connectionFromId(String id) {
    for (final connection in connections) {
      if (connection.id == id) {
        return connection;
      }
    }

    throw StateError('No connection with id $id');
  }

  Future<void> connect(RdpConnection connection) async {
    final current = getStatus(connection);

    // Prevent starting a second session for an already
    // connecting/connected connection.
    if (current == RdpStatus.connecting || current == RdpStatus.connected) {
      return;
    }

    connectionStatuses[connection.id] = RdpStatus.connecting;
    connectionStatuses.refresh();

    try {
      await _rdpService.connect(connection);
    } catch (e) {
      connectionStatuses[connection.id] = RdpStatus.failed;
      connectionStatuses.refresh();
      Get.snackbar(
        'Connection Failed',
        _rdpService.lastError ?? 'Unable to establish the RDP connection.',
      );
    }
  }

  Future<void> disconnect(RdpConnection connection) async {
    await _rdpService.disconnect();
  }

  /// Toggles favorite on the record identified by the connection's stable
  /// id — never by a (filter-dependent) list index.
  Future<void> toggleFavorite(RdpConnection connection) async {
    final index = connections.indexWhere((c) => c.id == connection.id);

    if (index == -1) {
      return;
    }

    connections[index] =
        connections[index].copyWith(favorite: !connection.favorite);

    await _storageService.saveConnectionList(connections);

    connections.refresh();
    filterConnections();
  }

  Future<void> editConnection(RdpConnection connection) async {
    final result = await Get.toNamed(
      AppRoutes.connection,
      arguments: connection,
    );

    if (result is RdpConnection) {
      await updateConnection(result);
    }
  }

  /// Replaces the stored record with [updated], matched by stable id, and
  /// persists the change. Editing never duplicates or shifts other records.
  Future<void> updateConnection(RdpConnection updated) async {
    final index = connections.indexWhere((c) => c.id == updated.id);

    if (index == -1) {
      return;
    }

    connections[index] = updated;

    await _storageService.saveConnectionList(connections);

    connections.refresh();
    filterConnections();
  }

  Future<void> deleteConnection(RdpConnection connection) async {
    final index = connections.indexWhere((c) => c.id == connection.id);

    if (index == -1) {
      return;
    }

    final status = getStatus(connection);

    if (status == RdpStatus.connected || status == RdpStatus.connecting) {
      await _rdpService.disconnect();
    }

    connections.removeAt(index);
    connectionStatuses.remove(connection.id);

    await _storageService.saveConnectionList(connections);

    filterConnections();
    connectionStatuses.refresh();

    Get.snackbar('Deleted', 'Connection removed.');
  }

  @override
  void onClose() {
    _rdpService.dispose();
    searchController.dispose();
    super.onClose();
  }
}
