import 'dart:async';

import '../../data/models/rdp_connection.dart';
import '../native/rdp_bridge.dart';
import '../utils/rdp_error_mapper.dart';

enum RdpStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  failed,
}

class RdpService {
  RdpService({RdpBridge? bridge}) : _bridge = bridge ?? RdpBridge();

  final RdpBridge _bridge;

  RdpConnection? _activeConnection;

  final StreamController<RdpStatus> _statusController =
      StreamController<RdpStatus>.broadcast();

  RdpStatus _status = RdpStatus.disconnected;
  String? _lastError;

  Stream<RdpStatus> get status => _statusController.stream;

  RdpStatus get currentStatus => _status;

  RdpConnection? get activeConnection => _activeConnection;

  String? get lastError => _lastError;

  bool get isConnected => _bridge.isConnected;

  Future<bool> isBackendAvailable() async {
    return true;
  }

  Future<bool> connect(
    RdpConnection connection, {
    String? passwordOverride,
  }) async {
    await disconnect();

    _lastError = null;
    _activeConnection = connection;
    _setStatus(RdpStatus.connecting);

    final password = passwordOverride ?? connection.password;

    if (password.isEmpty) {
      _lastError = 'Password is required.';
      _activeConnection = null;
      _setStatus(RdpStatus.failed);
      return false;
    }

    try {
      final connected = _bridge.connect(
        host: connection.host,
        port: 3389,
        username: connection.username,
        password: password,
        domain: connection.domain ?? '',
      );

      if (connected) {
        _setStatus(RdpStatus.connected);
        return true;
      }
      final nativeError = _bridge.lastError;

      _lastError = RdpErrorMapper.message(nativeError);
      _activeConnection = null;
      _setStatus(RdpStatus.failed);
      return false;
    } catch (e) {
      _lastError = RdpErrorMapper.message(e.toString());
      _activeConnection = null;
      _setStatus(RdpStatus.failed);
      return false;
    }
  }

  Future<void> disconnect() async {
    if (!_bridge.isConnected) {
      _activeConnection = null;

      if (_status != RdpStatus.disconnected) {
        _setStatus(RdpStatus.disconnected);
      }

      return;
    }

    _setStatus(RdpStatus.disconnecting);

    try {
      _bridge.disconnect();
    } catch (e) {
      _lastError = RdpErrorMapper.message(e.toString());
    } finally {
      _activeConnection = null;
      _setStatus(RdpStatus.disconnected);
    }
  }

  void _setStatus(RdpStatus value) {
    _status = value;

    if (!_statusController.isClosed) {
      _statusController.add(value);
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
  }

  bool isLibraryAvailable() {
    return true;
  }
}
