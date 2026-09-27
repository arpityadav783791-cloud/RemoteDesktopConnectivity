import 'package:flutter_test/flutter_test.dart';

import 'package:linux_rdp_client/data/models/rdp_connection.dart';

void main() {
  group('RdpConnection stable identity', () {
    test('create() generates a unique id per connection', () {
      final a = RdpConnection.create(
        name: 'Work',
        host: '10.0.0.5',
        username: 'alice',
        password: 'secret',
      );
      final b = RdpConnection.create(
        name: 'Work',
        host: '10.0.0.5',
        username: 'alice',
        password: 'secret',
      );

      expect(a.id, isNotEmpty);
      expect(b.id, isNotEmpty);
      expect(a.id, isNot(equals(b.id)));
    });

    test('id persists through JSON round-trip', () {
      final original = RdpConnection.create(
        name: 'Work',
        host: '10.0.0.5',
        username: 'alice',
        password: 'secret',
        favorite: true,
      );

      final restored = RdpConnection.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.favorite, equals(true));
      expect(restored.name, equals('Work'));
      expect(restored.host, equals('10.0.0.5'));
    });

    test('copyWith changes name/host/username but never the id', () {
      final original = RdpConnection.create(
        name: 'Work',
        host: '10.0.0.5',
        username: 'alice',
        password: 'secret',
        favorite: false,
      );

      final edited = original.copyWith(
        name: 'Renamed',
        host: '192.168.1.10',
        username: 'bob',
        password: 'newsecret',
      );

      expect(edited.id, equals(original.id));
      expect(edited.name, 'Renamed');
      expect(edited.host, '192.168.1.10');
      expect(edited.username, 'bob');
      // Untouched fields are preserved.
      expect(edited.favorite, false);
      expect(edited.width, original.width);
      expect(edited.height, original.height);
      expect(edited.clipboard, original.clipboard);
    });

    test('copyWith preserves favorite unless explicitly changed', () {
      final original = RdpConnection.create(
        name: 'Work',
        host: '10.0.0.5',
        username: 'alice',
        password: 'secret',
        favorite: true,
      );

      final renamed = original.copyWith(name: 'Renamed');
      expect(renamed.favorite, true, reason: 'edit must keep favorite state');

      final unfavorited = original.copyWith(favorite: false);
      expect(unfavorited.favorite, false);
    });

    test('copyWith can set domain explicitly to null', () {
      final withDomain = RdpConnection.create(
        name: 'Work',
        host: '10.0.0.5',
        username: 'alice',
        password: 'secret',
        domain: 'CORP',
      );

      final cleared = withDomain.copyWith(domain: null);
      expect(cleared.domain, isNull);

      final kept = withDomain.copyWith(name: 'Renamed');
      expect(kept.domain, 'CORP');
    });

    test('equality is based on stable id, not field values', () {
      const a = RdpConnection(
        id: 'same-id',
        name: 'A',
        host: 'h1',
        username: 'u1',
        password: 'p',
      );
      const b = RdpConnection(
        id: 'same-id',
        name: 'B',
        host: 'h2',
        username: 'u2',
        password: 'p2',
        favorite: true,
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('toString never leaks the password', () {
      final connection = RdpConnection.create(
        name: 'Work',
        host: '10.0.0.5',
        username: 'alice',
        password: 'super-secret-value',
      );

      expect(connection.toString(), isNot(contains('super-secret-value')));
    });
  });
}
