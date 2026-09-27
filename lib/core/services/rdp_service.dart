import 'dart:async';
import 'dart:io';
import '../../data/models/rdp_connection.dart';
import '../utils/rdp_error_mapper.dart';

enum RdpStatus { disconnected, connecting, connected, disconnecting, failed }

class RdpService {
  Process? _process;
  RdpConnection? _activeConnection;
  final _statusController = StreamController<RdpStatus>.broadcast();
  RdpStatus _status = RdpStatus.disconnected;
  String? _lastError;

  Stream<RdpStatus> get status => _statusController.stream;
  RdpStatus get currentStatus => _status;
  RdpConnection? get activeConnection => _activeConnection;
  String? get lastError => _lastError;

  Future<bool> isBackendAvailable() async {
    if (!Platform.isLinux) return true;
    for (final executable in ['xfreerdp3', 'xfreerdp']) {
      try {
        final result = await Process.run('which', [executable]);
        if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) return true;
      } catch (_) {}
    }
    return false;
  }

  Future<void> connect(RdpConnection connection, {String? passwordOverride}) async {
    await disconnect();
    _lastError = null;
    _activeConnection = connection;
    _setStatus(RdpStatus.connecting);

    if (!Platform.isLinux) {
      _lastError = 'Windows/native RDP adapter is not implemented in this generated lib yet.';
      _setStatus(RdpStatus.failed);
      return;
    }

    final executable = await _findLinuxExecutable();
    if (executable == null) {
      _lastError = 'FreeRDP was not found. Install FreeRDP and try again.';
      _setStatus(RdpStatus.failed);
      return;
    }

    final password = passwordOverride ?? connection.password;
    final args = <String>[
      '/v:${connection.host}',
      '/u:${connection.username}',
      if (connection.domain?.isNotEmpty == true) '/d:${connection.domain}',
      '/p:$password',
      '/cert:tofu',
    ];

    // Strict isolation: no clipboard, drive, printer, microphone, USB,
    // smart-card or other local-resource redirection arguments are added.

    if (connection.fullscreen) {
      args.add('/f');
    } else {
      args.add('/w:${connection.width}');
      args.add('/h:${connection.height}');
    }

    try {
      final process = await Process.start(executable, args, runInShell: false);
      _process = process;
      process.stdout.transform(const SystemEncoding().decoder).listen(_handleOutput);
      process.stderr.transform(const SystemEncoding().decoder).listen(_handleOutput);

      final exitCode = await process.exitCode;
      if (identical(_process, process)) _process = null;

      if (_status != RdpStatus.disconnecting) {
        if (exitCode == 0 || exitCode == 12) {
          _setStatus(RdpStatus.disconnected);
        } else {
          _lastError ??= 'RDP session ended with exit code $exitCode.';
          _setStatus(RdpStatus.failed);
        }
      }
      _activeConnection = null;
    } catch (e) {
      _lastError = RdpErrorMapper.message(e.toString());
      _process = null;
      _activeConnection = null;
      _setStatus(RdpStatus.failed);
    }
  }

  Future<String?> _findLinuxExecutable() async {
    for (final executable in ['xfreerdp3', 'xfreerdp']) {
      try {
        final result = await Process.run('which', [executable]);
        if (result.exitCode == 0) {
          final path = result.stdout.toString().trim();
          if (path.isNotEmpty) return path;
        }
      } catch (_) {}
    }
    return null;
  }

  void _handleOutput(String output) {
    if (output.contains('Local framebuffer format') ||
        output.contains('Remote framebuffer format') ||
        output.contains('Connected to')) {
      _setStatus(RdpStatus.connected);
    }
    if (output.toLowerCase().contains('authentication failure') ||
        output.toLowerCase().contains('logon failure')) {
      _lastError = RdpErrorMapper.message(output);
    }
  }

  Future<void> disconnect() async {
    final process = _process;
    if (process == null) {
      _activeConnection = null;
      if (_status != RdpStatus.disconnected) _setStatus(RdpStatus.disconnected);
      return;
    }

    _setStatus(RdpStatus.disconnecting);
    try {
      process.kill(ProcessSignal.sigterm);
      await process.exitCode.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
    } catch (_) {
      try {
        process.kill(ProcessSignal.sigkill);
      } catch (_) {}
    } finally {
      _process = null;
      _activeConnection = null;
      _setStatus(RdpStatus.disconnected);
    }
  }

  void _setStatus(RdpStatus value) {
    _status = value;
    if (!_statusController.isClosed) _statusController.add(value);
  }

  Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
  }
}
