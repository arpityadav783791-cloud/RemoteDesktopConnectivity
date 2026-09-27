import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/rdp_connection.dart';

class StorageService {
  final GetStorage _storage = GetStorage();
  final Uuid _uuid = const Uuid();

  static const String connectionsKey = 'rdp_connections';

  List<dynamic> getConnections() {
    return _storage.read<List<dynamic>>(connectionsKey) ?? [];
  }

  /// Loads all connections through the migration layer (Phase 1, item 4).
  ///
  /// - Legacy records without a stable id receive a freshly generated id.
  /// - Migrated data is persisted back so the new ids become permanent.
  /// - Malformed/legacy values that cannot be parsed are skipped instead of
  ///   crashing; parseable records are never dropped.
  Future<List<RdpConnection>> loadConnections() async {
    final raw = getConnections();
    final migrated = <RdpConnection>[];
    var changed = false;

    for (final item in raw) {
      try {
        if (item is! Map) {
          // Unrecoverable legacy value: cannot be represented as a
          // connection. Skip it instead of losing the rest of the data.
          changed = true;
          continue;
        }

        final json = Map<String, dynamic>.from(item);
        final connection = RdpConnection.fromJson(json);

        if (connection.id.isEmpty) {
          changed = true;
          migrated.add(connection.copyWith(id: _uuid.v4()));
        } else {
          migrated.add(connection);
        }
      } catch (_) {
        // Malformed record: skip without dropping the remaining records.
        changed = true;
        continue;
      }
    }

    if (changed) {
      await saveConnections(migrated.map((c) => c.toJson()).toList());
    }

    return migrated;
  }

  Future<void> saveConnections(List<Map<String, dynamic>> connections) async {
    await _storage.write(connectionsKey, connections);
  }

  Future<void> saveConnectionList(List<RdpConnection> connections) async {
    await saveConnections(connections.map((c) => c.toJson()).toList());
  }
}
