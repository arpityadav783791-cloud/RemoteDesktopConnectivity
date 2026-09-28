import 'dart:async';
import 'dart:typed_data';

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

class RdpFrame {
  const RdpFrame({
    required this.width,
    required this.height,
    required this.pixels,
  });

  final int width;
  final int height;
  final Uint8List pixels;
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

  Future<bool> isBackendAvailable() async => true;

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
      final started = _bridge.connect(
        host: connection.host,
        port: 3389,
        username: connection.username,
        password: password,
        domain: connection.domain ?? '',
        width: connection.fullscreen ? 1920 : connection.width,
        height: connection.fullscreen ? 1080 : connection.height,
      );

      if (!started) {
        _lastError = RdpErrorMapper.message(_bridge.lastError);
        _activeConnection = null;
        _setStatus(RdpStatus.failed);
        return false;
      }

      const timeout = Duration(seconds: 30);
      final stopwatch = Stopwatch()..start();

      while (stopwatch.elapsed < timeout) {
        switch (_bridge.connectionState) {
          case 2:
            _setStatus(RdpStatus.connected);
            return true;

          case 3:
            _lastError = RdpErrorMapper.message(_bridge.lastError);
            await _bridge.disconnect();
            _activeConnection = null;
            _setStatus(RdpStatus.failed);
            return false;

          default:
            await Future<void>.delayed(
              const Duration(milliseconds: 100),
            );
        }
      }

      _lastError = 'The connection timed out.';
      await _bridge.disconnect();
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
    final hasNativeSession = _bridge.connectionState != 0;

    if (!hasNativeSession && _activeConnection == null) {
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

  RdpFrame? readFrame() {
    final info = _bridge.getFrameInfo();
    if (info == null) return null;

    final pixels = _bridge.copyFrame(info);
    if (pixels == null) return null;

    return RdpFrame(
      width: info.width,
      height: info.height,
      pixels: pixels,
    );
  }

  bool sendKey({
    required int flags,
    required int code,
  }) =>
      _bridge.sendKey(flags: flags, code: code);

  bool sendUnicode({
    required int flags,
    required int code,
  }) =>
      _bridge.sendUnicode(flags: flags, code: code);

  bool sendMouse({
    required int flags,
    required int x,
    required int y,
  }) =>
      _bridge.sendMouse(flags: flags, x: x, y: y);

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
}
