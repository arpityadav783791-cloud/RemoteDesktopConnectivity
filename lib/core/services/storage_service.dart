import 'package:get_storage/get_storage.dart';
import '../../data/models/rdp_connection.dart';

class StorageService {
  static const connectionsKey = 'rdp_connections';

  static Future<void> initialize() => GetStorage.init();

  final GetStorage _storage = GetStorage();

  List<RdpConnection> loadConnections() {
    final raw = _storage.read<List<dynamic>>(connectionsKey) ?? <dynamic>[];
    return raw.whereType<Map>().map(
      (e) => RdpConnection.fromJson(Map<String, dynamic>.from(e)),
    ).toList();
  }

  Future<void> saveConnections(List<RdpConnection> connections) =>
      _storage.write(connectionsKey, connections.map((e) => e.toJson()).toList());

  Future<void> deleteAll() => _storage.remove(connectionsKey);
}
