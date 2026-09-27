import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/storage_service.dart';
import '../../core/utils/connection_utils.dart';
import '../../data/models/rdp_connection.dart';

class ConnectionController extends GetxController {
  ConnectionController({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  final StorageService _storageService;

  final nameController = TextEditingController();
  final hostController = TextEditingController();
  final usernameController = TextEditingController();
  final domainController = TextEditingController();
  final passwordController = TextEditingController();

  final fullscreen = false.obs;
  final clipboard = true.obs;
  final audio = true.obs;

  final width = 1280.obs;
  final height = 720.obs;

  RdpConnection? editingConnection;

  bool get isEditing => editingConnection != null;

  @override
  void onInit() {
    super.onInit();
    final connection = Get.arguments;
    if (connection is RdpConnection) {
      editingConnection = connection;

      nameController.text = connection.name;
      hostController.text = connection.host;
      usernameController.text = connection.username;
      passwordController.text = connection.password;
      domainController.text = connection.domain ?? '';

      fullscreen.value = connection.fullscreen;
      clipboard.value = connection.clipboard;
      audio.value = connection.audio;

      width.value = connection.width;
      height.value = connection.height;
    }
  }

  Future<void> saveConnection() async {
    if (nameController.text.trim().isEmpty ||
        hostController.text.trim().isEmpty ||
        usernameController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar('Missing Information', 'Please fill all required fields.');
      return;
    }

    final host = hostController.text.trim();
    final username = usernameController.text.trim();
    final domain = domainController.text.trim();

    final existingConnections = await _storageService.loadConnections();

    // The record being edited is excluded by its STABLE id, so editing a
    // connection without changing host/username is not a duplicate.
    final duplicate = isDuplicateConnection(
      existingConnections,
      host: host,
      username: username,
      excludeId: editingConnection?.id,
    );

    if (duplicate) {
      Get.snackbar('Already Exists', 'This connection is already saved.');
      return;
    }

    if (isEditing) {
      // Editing preserves the connection's stable id, favorite state and
      // every property not exposed for editing here (copyWith keeps them).
      final updated = editingConnection!.copyWith(
        name: nameController.text.trim(),
        host: host,
        username: username,
        password: passwordController.text,
        domain: domain.isEmpty ? null : domain,
        fullscreen: fullscreen.value,
        clipboard: clipboard.value,
        audio: audio.value,
        width: width.value,
        height: height.value,
      );

      Get.back(result: updated);
      return;
    }

    final connection = RdpConnection.create(
      name: nameController.text.trim(),
      host: host,
      username: username,
      password: passwordController.text,
      domain: domain.isEmpty ? null : domain,
      fullscreen: fullscreen.value,
      clipboard: clipboard.value,
      audio: audio.value,
      width: width.value,
      height: height.value,
    );

    existingConnections.add(connection);

    await _storageService.saveConnectionList(existingConnections);

    Get.back();
  }

  @override
  void onClose() {
    nameController.dispose();
    hostController.dispose();
    usernameController.dispose();
    domainController.dispose();
    passwordController.dispose();

    super.onClose();
  }
}
