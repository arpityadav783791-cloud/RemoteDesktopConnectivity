import 'package:flutter_test/flutter_test.dart';

import 'package:linux_rdp_client/core/utils/connection_utils.dart';
import 'package:linux_rdp_client/data/models/rdp_connection.dart';

RdpConnection conn(String id, String host, String username,
    {bool favorite = false}) {
  return RdpConnection(
    id: id,
    name: 'Connection $id',
    host: host,
    username: username,
    password: 'secret',
    favorite: favorite,
  );
}

void main() {
  group('duplicate detection', () {
    final connections = [
      conn('id-1', '10.0.0.5', 'alice'),
      conn('id-2', '10.0.0.6', 'bob', favorite: true),
    ];

    test('flags same host+username as duplicate', () {
      expect(
        isDuplicateConnection(
          connections,
          host: '10.0.0.5',
          username: 'alice',
        ),
        isTrue,
      );
    });

    test('different host or username is not a duplicate', () {
      expect(
        isDuplicateConnection(
          connections,
          host: '10.0.0.5',
          username: 'bob',
        ),
        isFalse,
      );
      expect(
        isDuplicateConnection(
          connections,
          host: '10.0.0.9',
          username: 'alice',
        ),
        isFalse,
      );
    });

    test('editing the same connection (same id) is not a duplicate', () {
      expect(
        isDuplicateConnection(
          connections,
          host: '10.0.0.5',
          username: 'alice',
          excludeId: 'id-1',
        ),
        isFalse,
        reason:
            'saving an edited connection must not be rejected as its own '
            'duplicate',
      );
    });

    test('another connection with same host+username is still a duplicate '
        'even when editing', () {
      expect(
        isDuplicateConnection(
          connections,
          host: '10.0.0.5',
          username: 'alice',
          excludeId: 'id-2',
        ),
        isTrue,
      );
    });
  });
}
