import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/services/rdp_service.dart';
import '../../core/services/storage_service.dart';
import '../../data/models/rdp_connection.dart';

class HomeController extends GetxController {
  final StorageService _storageService = StorageService();
  final RdpService _rdpService = RdpService();

  final connections = <RdpConnection>[].obs;
  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final filterdConnections = <RdpConnection>[].obs;

  // Status for each connection.
  final connectionStatuses = <String, RdpStatus>{}.obs;

  @override
  void onInit() {
    super.onInit();

    loadConnections();

    searchController.addListener(() {
      searchQuery.value = searchController.text.trim();
      filterdConnections();
    });

    _rdpService.status.listen((status) {
      final activeConnection = _rdpService.activeConnection;

      if (activeConnection != null) {
        connectionStatuses[activeConnection.name] = status;
        connectionStatuses.refresh();
      }
    });
  }

  void filterConnections() {
    final query = searchQuery.value.toLowerCase();

    if (query.isEmpty) {
      filterdConnections.assignAll(connections);
      return;
    }

    filterdConnections.assignAll(
      connections.where((connection) {
        return connection.name.toLowerCase().contains(query) ||
            connection.host.toLowerCase().contains(query) ||
            connection.username.toLowerCase().contains(query);
      }),
    );
  }

  void loadConnections() {
    final data = _storageService.getConnections();
    final loadedConnections = data
        .map((item) => RdpConnection.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    loadedConnections.sort((a, b) {
      if (a.favorite == b.favorite) {
        return 0;
      }

      return a.favorite ? -1 : 1;
    });

    connections.assignAll(loadedConnections);
    filterdConnections.assignAll(connections);

    for (final connection in connections) {
      connectionStatuses[connection.name] = RdpStatus.disconnected;
    }

    connectionStatuses.refresh();
  }

  RdpStatus getStatus(RdpConnection connection) {
    return connectionStatuses[connection.name] ?? RdpStatus.disconnected;
  }

  Future<void> connect(RdpConnection connection) async {
    try {
      await _rdpService.connect(connection);
    } catch (e) {
      connectionStatuses[connection.name] = RdpStatus.failed;
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

  Future<void> toggleFavorite(int index) async {
    final connection = connections[index];

    final updatedConnection = RdpConnection(
      name: connection.name,
      host: connection.host,
      username: connection.username,
      password: connection.password,
      domain: connection.domain,
      fullscreen: connection.fullscreen,
      clipboard: connection.clipboard,
      audio: connection.audio,
      width: connection.width,
      height: connection.height,
      favorite: !connection.favorite,
    );

    connections[index] = updatedConnection;

    await _storageService.saveConnections(
      connections.map((e) => e.toJson()).toList(),
    );

    connections.refresh();
  }

  Future<void> editConnection(int index) async {
    final result = await Get.toNamed(
      AppRoutes.connection,
      arguments: connections[index],
    );

    if (result != null) {
      connections[index] = result;

      await _storageService.saveConnections(
        connections.map((e) => e.toJson()).toList(),
      );

      connections.refresh();
    }
  }

  Future<void> deleteConnection(int index) async {
    final connection = connections[index];

    await _rdpService.disconnect();

    connections.removeAt(index);
    connectionStatuses.remove(connection.name);

    await _storageService.saveConnections(
      connections.map((e) => e.toJson()).toList(),
    );

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
