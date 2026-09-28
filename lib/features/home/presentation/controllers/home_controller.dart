import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/credential_service.dart';
import '../../../../core/services/rdp_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../data/models/rdp_connection.dart';

class HomeController extends GetxController {
  final _storage = StorageService();
  final _credentials = CredentialService();
  final rdpService = RdpService();

  final connections = <RdpConnection>[].obs;
  final filteredConnections = <RdpConnection>[].obs;
  final statuses = <String, RdpStatus>{}.obs;

  final searchController = TextEditingController();
  final query = ''.obs;

  @override
  void onInit() {
    super.onInit();

    loadConnections();

    searchController.addListener(() {
      query.value = searchController.text.trim();
      _filter();
    });
  }

  void loadConnections() {
    final list = _storage.loadConnections();

    list.sort((a, b) {
      if (a.favorite != b.favorite) {
        return a.favorite ? -1 : 1;
      }

      return a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          );
    });

    connections.assignAll(list);
    _filter();

    for (final connection in list) {
      statuses.putIfAbsent(
        connection.id,
        () => RdpStatus.disconnected,
      );
    }

    statuses.refresh();
  }

  void _filter() {
    final q = query.value.toLowerCase();

    filteredConnections.assignAll(
      q.isEmpty
          ? connections
          : connections.where(
              (connection) =>
                  connection.name.toLowerCase().contains(q) ||
                  connection.host.toLowerCase().contains(q) ||
                  connection.username.toLowerCase().contains(q),
            ),
    );
  }

  RdpStatus statusOf(RdpConnection connection) {
    return statuses[connection.id] ?? RdpStatus.disconnected;
  }

  Future<void> addConnection() async {
    await Get.toNamed(AppRoutes.connection);
    loadConnections();
  }

  Future<void> editConnection(RdpConnection connection) async {
    await Get.toNamed(
      AppRoutes.connection,
      arguments: connection,
    );

    loadConnections();
  }

  Future<void> deleteConnection(RdpConnection connection) async {
    if (rdpService.activeConnection?.id == connection.id) {
      await rdpService.disconnect();
    }

    await _credentials.delete(connection.id);

    final updated =
        connections.where((item) => item.id != connection.id).toList();

    await _storage.saveConnections(updated);

    statuses.remove(connection.id);
    loadConnections();
  }

  Future<void> toggleFavorite(RdpConnection connection) async {
    final updated = connections
        .map(
          (item) => item.id == connection.id
              ? item.copyWith(
                  favorite: !item.favorite,
                )
              : item,
        )
        .toList();

    await _storage.saveConnections(updated);
    loadConnections();
  }

  Future<void> connect(RdpConnection connection) async {
    var password = connection.password;

    if (connection.rememberMe) {
      password = _credentials.read(connection.id) ?? password;
    }

    if (password.isEmpty) {
      Get.snackbar(
        'Password Required',
        'Enter the password before connecting.',
      );

      await editConnection(connection);
      return;
    }

    statuses[connection.id] = RdpStatus.connecting;
    statuses.refresh();

    final success = await rdpService.connect(
      connection,
      passwordOverride: password,
    );

    statuses[connection.id] = success ? RdpStatus.connected : RdpStatus.failed;

    statuses.refresh();

    if (!success) {
      Get.snackbar(
        'Connection Failed',
        rdpService.lastError ?? 'Unable to connect.',
      );
    }
  }

  Future<void> disconnect() async {
    final activeConnection = rdpService.activeConnection;

    await rdpService.disconnect();

    if (activeConnection != null) {
      statuses[activeConnection.id] = RdpStatus.disconnected;
      statuses.refresh();
    }
  }

  @override
  void onClose() {
    rdpService.dispose();
    searchController.dispose();
    super.onClose();
  }
}
