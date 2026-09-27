import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/credential_service.dart';
import 'core/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.initialize();
  await CredentialService.initialize();
  runApp(const RemoteDesktopConnectivityApp());
}
