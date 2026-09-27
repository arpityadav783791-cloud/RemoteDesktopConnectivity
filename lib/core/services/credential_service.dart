import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import '../../data/models/rdp_connection.dart';

/// Credential abstraction.
///
/// The production backend should be replaced by Linux Secret Service and
/// Windows Credential Manager (or equivalent secure platform storage).
class CredentialService {
  static const _prefix = 'credential_';

  static Future<void> initialize() async {}

  final GetStorage _storage = GetStorage();

  Future<void> save(RdpConnection connection) async {
    if (!connection.rememberMe) {
      await delete(connection.id);
      return;
    }
    await _storage.write(
      '$_prefix${connection.id}',
      jsonEncode({'password': connection.password}),
    );
  }

  String? read(String id) {
    final raw = _storage.read<String>('$_prefix$id');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw);
      return map is Map && map['password'] is String ? map['password'] as String : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String id) => _storage.remove('$_prefix$id');
}
