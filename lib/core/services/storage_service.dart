import 'package:get_storage/get_storage.dart';

class StorageService {
  final GetStorage _storage = GetStorage();

  static const String connectionsKey = 'rdp_connections';

  List<dynamic> getConnections() {
    return _storage.read<List<dynamic>>(connectionsKey) ?? [];
  }

  Future<void> saveConnections(List<Map<String, dynamic>> connections) async {
    await _storage.write(connectionsKey, connections);
  }
}
