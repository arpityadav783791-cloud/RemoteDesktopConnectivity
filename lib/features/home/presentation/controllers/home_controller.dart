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
    rdpService.status.listen((status) {
      final active = rdpService.activeConnection;
      if (active != null) {
        statuses[active.id] = status;
        statuses.refresh();
      }
    });
  }

  void loadConnections() {
    final list = _storage.loadConnections();
    list.sort((a, b) {
      if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    connections.assignAll(list);
    _filter();
    for (final c in list) {
      statuses[c.id] = RdpStatus.disconnected;
    }
  }

  void _filter() {
    final q = query.value.toLowerCase();
    filteredConnections.assignAll(
      q.isEmpty
          ? connections
          : connections.where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.host.toLowerCase().contains(q) ||
              c.username.toLowerCase().contains(q)),
    );
  }

  RdpStatus statusOf(RdpConnection c) =>
      statuses[c.id] ?? RdpStatus.disconnected;

  Future<void> addConnection() async {
    await Get.toNamed(AppRoutes.connection);
    loadConnections();
  }

  Future<void> editConnection(RdpConnection c) async {
    await Get.toNamed(AppRoutes.connection, arguments: c);
    loadConnections();
  }

  Future<void> deleteConnection(RdpConnection c) async {
    await rdpService.disconnect();
    await _credentials.delete(c.id);
    await _storage.saveConnections(
      connections.where((x) => x.id != c.id).toList(),
    );
    loadConnections();
  }

  Future<void> toggleFavorite(RdpConnection c) async {
    await _storage.saveConnections(
      connections.map((x) => x.id == c.id
          ? x.copyWith(favorite: !x.favorite)
          : x).toList(),
    );
    loadConnections();
  }

  Future<void> connect(RdpConnection c) async {
    var password = c.password;
    if (c.rememberMe) password = _credentials.read(c.id) ?? password;

    if (password.isEmpty) {
      Get.snackbar('Password Required', 'Enter the password before connecting.');
      await editConnection(c);
      return;
    }

    await rdpService.connect(c, passwordOverride: password);
    if (rdpService.currentStatus == RdpStatus.failed) {
      Get.snackbar('Connection Failed',
          rdpService.lastError ?? 'Unable to connect.');
    }
  }

  Future<void> disconnect() => rdpService.disconnect();

  @override
  void onClose() {
    rdpService.dispose();
    searchController.dispose();
    super.onClose();
  }
}
