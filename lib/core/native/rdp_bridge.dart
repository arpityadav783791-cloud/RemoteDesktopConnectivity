import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

class RdpBridge {
  late final ffi.DynamicLibrary _library;

  late final _ConnectDart _connect;
  late final _DisconnectDart _disconnect;
  late final _IsConnectedDart _isConnected;
  late final _ConnectionStateDart _connectionState;
  late final _LastErrorDart _lastError;
  late final _GetFrameInfoDart _getFrameInfo;
  late final _CopyFrameDart _copyFrame;
  late final _SendKeyDart _sendKey;
  late final _SendUnicodeDart _sendUnicode;
  late final _SendMouseDart _sendMouse;

  RdpBridge() {
    _library = _loadLibrary();

    _connect =
        _library.lookupFunction<_ConnectNative, _ConnectDart>('rdc_connect');

    _disconnect = _library
        .lookupFunction<_DisconnectNative, _DisconnectDart>('rdc_disconnect');

    _isConnected =
        _library.lookupFunction<_IsConnectedNative, _IsConnectedDart>(
      'rdc_is_connected',
    );

    _connectionState =
        _library.lookupFunction<_ConnectionStateNative, _ConnectionStateDart>(
      'rdc_connection_state',
    );

    _lastError = _library.lookupFunction<_LastErrorNative, _LastErrorDart>(
      'rdc_last_error',
    );

    _getFrameInfo =
        _library.lookupFunction<_GetFrameInfoNative, _GetFrameInfoDart>(
      'rdc_get_frame_info',
    );

    _copyFrame = _library.lookupFunction<_CopyFrameNative, _CopyFrameDart>(
      'rdc_copy_frame',
    );

    _sendKey = _library.lookupFunction<_SendKeyNative, _SendKeyDart>(
      'rdc_send_key',
    );

    _sendUnicode =
        _library.lookupFunction<_SendUnicodeNative, _SendUnicodeDart>(
      'rdc_send_unicode',
    );

    _sendMouse = _library.lookupFunction<_SendMouseNative, _SendMouseDart>(
      'rdc_send_mouse',
    );
  }

  ffi.DynamicLibrary _loadLibrary() {
    if (!Platform.isLinux) {
      throw UnsupportedError(
        'RDP bridge is not supported on ${Platform.operatingSystem}',
      );
    }

    final executableDir = File(
      Platform.resolvedExecutable,
    ).parent.path;

    final bundledPath = '$executableDir/lib/librdc_bridge.so';

    if (File(bundledPath).existsSync()) {
      return ffi.DynamicLibrary.open(bundledPath);
    }

    return ffi.DynamicLibrary.open(
      'native/rdp_bridge/build/librdc_bridge.so',
    );
  }

  bool connect({
    required String host,
    required int port,
    required String username,
    required String password,
    String domain = '',
    int width = 1280,
    int height = 720,
  }) {
    final hostPtr = host.toNativeUtf8();
    final usernamePtr = username.toNativeUtf8();
    final passwordPtr = password.toNativeUtf8();
    final domainPtr = domain.toNativeUtf8();

    try {
      return _connect(
            hostPtr,
            port,
            usernamePtr,
            passwordPtr,
            domainPtr,
            width,
            height,
          ) !=
          0;
    } finally {
      calloc.free(hostPtr);
      calloc.free(usernamePtr);
      calloc.free(passwordPtr);
      calloc.free(domainPtr);
    }
  }

  bool disconnect() => _disconnect() != 0;

  bool get isConnected => _isConnected() != 0;

  int get connectionState => _connectionState();

  String get lastError {
    final pointer = _lastError();

    if (pointer == ffi.nullptr) {
      return '';
    }

    return pointer.toDartString();
  }

  RdpFrameInfo? getFrameInfo() {
    final width = calloc<ffi.Uint32>();
    final height = calloc<ffi.Uint32>();
    final size = calloc<ffi.Uint32>();

    try {
      if (_getFrameInfo(width, height, size) == 0) {
        return null;
      }

      return RdpFrameInfo(
        width: width.value,
        height: height.value,
        size: size.value,
      );
    } finally {
      calloc.free(width);
      calloc.free(height);
      calloc.free(size);
    }
  }

  Uint8List? copyFrame(RdpFrameInfo info) {
    final buffer = calloc<ffi.Uint8>(info.size);

    try {
      final copied = _copyFrame(buffer, info.size);

      if (copied <= 0) {
        return null;
      }

      return Uint8List.fromList(
        buffer.asTypedList(copied),
      );
    } finally {
      calloc.free(buffer);
    }
  }

  bool sendKey({
    required int flags,
    required int code,
  }) =>
      _sendKey(flags, code) != 0;

  bool sendUnicode({
    required int flags,
    required int code,
  }) =>
      _sendUnicode(flags, code) != 0;

  bool sendMouse({
    required int flags,
    required int x,
    required int y,
  }) =>
      _sendMouse(flags, x, y) != 0;
}

class RdpFrameInfo {
  const RdpFrameInfo({
    required this.width,
    required this.height,
    required this.size,
  });

  final int width;
  final int height;
  final int size;
}

typedef _ConnectNative = ffi.Int32 Function(
  ffi.Pointer<Utf8>,
  ffi.Int32,
  ffi.Pointer<Utf8>,
  ffi.Pointer<Utf8>,
  ffi.Pointer<Utf8>,
  ffi.Int32,
  ffi.Int32,
);

typedef _ConnectDart = int Function(
  ffi.Pointer<Utf8>,
  int,
  ffi.Pointer<Utf8>,
  ffi.Pointer<Utf8>,
  ffi.Pointer<Utf8>,
  int,
  int,
);

typedef _DisconnectNative = ffi.Int32 Function();
typedef _DisconnectDart = int Function();

typedef _IsConnectedNative = ffi.Int32 Function();
typedef _IsConnectedDart = int Function();

typedef _ConnectionStateNative = ffi.Int32 Function();
typedef _ConnectionStateDart = int Function();

typedef _LastErrorNative = ffi.Pointer<Utf8> Function();
typedef _LastErrorDart = ffi.Pointer<Utf8> Function();

typedef _GetFrameInfoNative = ffi.Int32 Function(
  ffi.Pointer<ffi.Uint32>,
  ffi.Pointer<ffi.Uint32>,
  ffi.Pointer<ffi.Uint32>,
);

typedef _GetFrameInfoDart = int Function(
  ffi.Pointer<ffi.Uint32>,
  ffi.Pointer<ffi.Uint32>,
  ffi.Pointer<ffi.Uint32>,
);

typedef _CopyFrameNative = ffi.Int32 Function(
  ffi.Pointer<ffi.Uint8>,
  ffi.Uint32,
);

typedef _CopyFrameDart = int Function(
  ffi.Pointer<ffi.Uint8>,
  int,
);

typedef _SendKeyNative = ffi.Int32 Function(
  ffi.Uint16,
  ffi.Uint8,
);

typedef _SendKeyDart = int Function(
  int,
  int,
);

typedef _SendUnicodeNative = ffi.Int32 Function(
  ffi.Uint16,
  ffi.Uint16,
);

typedef _SendUnicodeDart = int Function(
  int,
  int,
);

typedef _SendMouseNative = ffi.Int32 Function(
  ffi.Uint16,
  ffi.Uint16,
  ffi.Uint16,
);

typedef _SendMouseDart = int Function(
  int,
  int,
  int,
);
