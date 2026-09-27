import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/credential_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../data/models/rdp_connection.dart';

class ConnectionController extends GetxController {
  final _storage = StorageService();
  final _credentials = CredentialService();

  final name = TextEditingController();
  final host = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final domain = TextEditingController();

  final rememberMe = false.obs;
  final fullscreen = false.obs;
  final width = 1280.obs;
  final height = 720.obs;

  RdpConnection? editing;
  bool get isEditing => editing != null;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is RdpConnection) {
      editing = arg;
      name.text = arg.name;
      host.text = arg.host;
      username.text = arg.username;
      password.text = arg.password;
      domain.text = arg.domain ?? '';
      rememberMe.value = arg.rememberMe;
      fullscreen.value = arg.fullscreen;
      width.value = arg.width;
      height.value = arg.height;
      if (arg.rememberMe && password.text.isEmpty) {
        password.text = _credentials.read(arg.id) ?? '';
      }
    }
  }

  String? validate() {
    if (name.text.trim().isEmpty) return 'Connection name is required.';
    if (host.text.trim().isEmpty) return 'Host or IP is required.';
    if (username.text.trim().isEmpty) return 'Username is required.';
    if (password.text.isEmpty) return 'Password is required.';
    return null;
  }

  Future<void> save() async {
    final error = validate();
    if (error != null) {
      Get.snackbar('Invalid Connection', error);
      return;
    }

    final existing = _storage.loadConnections();
    final duplicate = existing.any((c) =>
        c.host.toLowerCase() == host.text.trim().toLowerCase() &&
        c.username.toLowerCase() == username.text.trim().toLowerCase() &&
        c.id != editing?.id);

    if (duplicate) {
      Get.snackbar('Already Exists',
          'A connection with this host and username already exists.');
      return;
    }

    final connection = isEditing
        ? editing!.copyWith(
            name: name.text.trim(),
            host: host.text.trim(),
            username: username.text.trim(),
            password: rememberMe.value ? password.text : '',
            domain: domain.text.trim().isEmpty ? null : domain.text.trim(),
            rememberMe: rememberMe.value,
            fullscreen: fullscreen.value,
            width: width.value,
            height: height.value,
          )
        : RdpConnection.create(
            name: name.text.trim(),
            host: host.text.trim(),
            username: username.text.trim(),
            password: rememberMe.value ? password.text : '',
            domain: domain.text.trim().isEmpty ? null : domain.text.trim(),
            rememberMe: rememberMe.value,
            fullscreen: fullscreen.value,
            width: width.value,
            height: height.value,
          );

    final list = existing.where((c) => c.id != connection.id).toList()
      ..add(connection);

    await _storage.saveConnections(list);

    if (connection.rememberMe) {
      await _credentials.save(connection);
    } else {
      await _credentials.delete(connection.id);
    }

    Get.back();
  }

  @override
  void onClose() {
    name.dispose();
    host.dispose();
    username.dispose();
    password.dispose();
    domain.dispose();
    super.onClose();
  }
}
