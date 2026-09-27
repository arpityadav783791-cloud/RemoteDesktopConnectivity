import '../../data/models/rdp_connection.dart';

/// Duplicate detection must be based on a sensible identity rule
/// (host + username) and must never flag the connection currently being
/// edited as its own duplicate — hence [excludeId], the stable id of the
/// record being saved.
bool isDuplicateConnection(
  List<RdpConnection> connections, {
  required String host,
  required String username,
  String? excludeId,
}) {
  return connections.any(
    (connection) =>
        connection.id != excludeId &&
        connection.host == host &&
        connection.username == username,
  );
}
