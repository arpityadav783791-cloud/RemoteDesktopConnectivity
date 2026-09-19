import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/storage_service.dart';
import '../../data/models/rdp_connection.dart';

class ConnectionController extends GetxController {
  final StorageService _storageService = StorageService();

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

    final existingConnections = _storageService.getConnections();

    final duplicate = existingConnections.any((item) {
      return item['host'] == hostController.text.trim() &&
          item['username'] == usernameController.text.trim();
    });

    if (duplicate && !isEditing) {
      Get.snackbar('Already Exists', 'This connection is already saved.');
      return;
    }

    final connection = RdpConnection(
      name: nameController.text.trim(),
      host: hostController.text.trim(),
      username: usernameController.text.trim(),
      password: passwordController.text,
      domain: domainController.text.trim().isEmpty
          ? null
          : domainController.text.trim(),
      fullscreen: fullscreen.value,
      clipboard: clipboard.value,
      audio: audio.value,
      width: width.value,
      height: height.value,
    );
    
    if (isEditing) {
      Get.back(result: connection);
      return;
    }

    final connections = _storageService.getConnections();

    connections.add(connection.toJson());

    await _storageService.saveConnections(
      connections.cast<Map<String, dynamic>>(),
    );

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
