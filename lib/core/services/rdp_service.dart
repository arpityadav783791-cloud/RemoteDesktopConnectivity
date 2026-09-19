import 'dart:async';
import 'dart:io';

import '../../data/models/rdp_connection.dart';
import '../utils/rdp_error_mapper.dart';

enum RdpStatus { disconnected, connecting, connected, failed }

class RdpService {
  Process? _process;

  RdpConnection? _activeConnection;

  RdpConnection? get activeConnection => _activeConnection;

  String? _lastError;

  String? get lastError => _lastError;

  final StreamController<RdpStatus> _statusController =
      StreamController<RdpStatus>.broadcast();

  Stream<RdpStatus> get status => _statusController.stream;

  RdpStatus _currentStatus = RdpStatus.disconnected;

  RdpStatus get currentStatus => _currentStatus;

  Future<void> connect(RdpConnection connection) async {
    _lastError = null;

    // Disconnect existing session.
    if (_process != null) {
      await disconnect();
    }

    _activeConnection = connection;

    _setStatus(RdpStatus.connecting);

    try {
      // --------------------------------
      // Check RDP server reachability
      // --------------------------------
      final reachable = await _isRdpServerReachable(connection.host);

      if (!reachable) {
        _lastError = 'Unable to reach the RDP server on ${connection.host}.';

        _setStatus(RdpStatus.failed);

        _activeConnection = null;

        return;
      }

      // --------------------------------
      // Build FreeRDP arguments
      // --------------------------------

      final arguments = [
        '/v:${connection.host}',
        '/u:${connection.username}',
        '/p:${connection.password}',
        '/cert:ignore',
      ];

      // Display settings
      if (connection.fullscreen) {
        arguments.add('/f');
      } else {
        arguments.add('/w:${connection.width}');
        arguments.add('/h:${connection.height}');
      }

      // Clipboard
      if (connection.clipboard) {
        arguments.add('/clipboard');
      }

      // Audio
      if (connection.audio) {
        arguments.add('/audio-mode:0');
      }

      // Domain
      if (connection.domain != null && connection.domain!.trim().isNotEmpty) {
        arguments.add('/d:${connection.domain}');
      }

      // --------------------------------
      // Safe debug output
      // --------------------------------

      final safeArguments = arguments.map((argument) {
        if (argument.startsWith('/p:')) {
          return '/p:********';
        }

        return argument;
      }).toList();

      print('FreeRDP arguments: $safeArguments');

      // --------------------------------
      // Start FreeRDP
      // --------------------------------

      _process = await Process.start(
        '/usr/bin/xfreerdp',
        arguments,
        runInShell: false,
      );

      // --------------------------------
      // STDOUT
      // --------------------------------

      _process!.stdout.transform(const SystemEncoding().decoder).listen((
        output,
      ) {
        print('FreeRDP: $output');

        _checkConnectionEstablished(output);
      });

      // --------------------------------
      // STDERR
      // --------------------------------

      _process!.stderr.transform(const SystemEncoding().decoder).listen((
        error,
      ) {
        print('FreeRDP Error: $error');

        _checkConnectionEstablished(error);

        // Ignore this harmless timezone warning.
        if (!error.contains('Unable to find a match for unix timezone')) {
          _lastError = RdpErrorMapper.getMessage(error);
        }
      });

      // --------------------------------
      // Wait for FreeRDP
      // --------------------------------

      final process = _process;

      if (process == null) {
        return;
      }

      final exitCode = await process.exitCode;

      print('FreeRDP exited with code: $exitCode');

      _process = null;

      // --------------------------------
      // Handle exit
      // --------------------------------

      if (exitCode == 0 || exitCode == 12) {
        _setStatus(RdpStatus.disconnected);
      } else {
        _setStatus(RdpStatus.failed);
      }

      _activeConnection = null;
    } catch (e) {
      _process = null;

      _lastError ??= e.toString();

      _setStatus(RdpStatus.failed);

      _activeConnection = null;

      rethrow;
    }
  }

  // --------------------------------
  // Detect successful RDP connection
  // --------------------------------

  void _checkConnectionEstablished(String output) {
    if (_currentStatus == RdpStatus.connected) {
      return;
    }

    if (output.contains('Local framebuffer format') ||
        output.contains('Remote framebuffer format')) {
      _setStatus(RdpStatus.connected);
    }
  }

  // --------------------------------
  // Check TCP port before FreeRDP
  // --------------------------------

  Future<bool> _isRdpServerReachable(String host) async {
    String hostname = host;
    int port = 3389;

    if (host.contains(':')) {
      final parts = host.split(':');

      hostname = parts.first;
      port = int.tryParse(parts.last) ?? 3389;
    }

    try {
      final socket = await Socket.connect(
        hostname,
        port,
        timeout: const Duration(seconds: 5),
      );

      await socket.close();

      return true;
    } catch (_) {
      return false;
    }
  }

  // --------------------------------
  // Disconnect
  // --------------------------------

  Future<void> disconnect() async {
    final process = _process;

    if (process == null) {
      return;
    }

    _setStatus(RdpStatus.disconnected);

    process.kill(ProcessSignal.sigterm);

    _process = null;
    _activeConnection = null;
  }

  // --------------------------------
  // Update status
  // --------------------------------

  void _setStatus(RdpStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  // --------------------------------
  // Dispose
  // --------------------------------

  Future<void> dispose() async {
    await disconnect();

    await _statusController.close();
  }
}
