import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';

class RdpBridge {
  late final ffi.DynamicLibrary _library;

  late final _ConnectDart _connect;
  late final _DisconnectDart _disconnect;
  late final _IsConnectedDart _isConnected;

  RdpBridge() {
    _library = _loadLibrary();

    _connect =
        _library.lookupFunction<_ConnectNative, _ConnectDart>('rdc_connect');

    _disconnect = _library
        .lookupFunction<_DisconnectNative, _DisconnectDart>('rdc_disconnect');

    _isConnected =
        _library.lookupFunction<_IsConnectedNative, _IsConnectedDart>(
            'rdc_is_connected');
  }

  ffi.DynamicLibrary _loadLibrary() {
    if (Platform.isLinux) {
      return ffi.DynamicLibrary.open(
        'native/rdp_bridge/build/librdc_bridge.so',
      );
    }

    throw UnsupportedError(
      'RDP bridge is not supported on ${Platform.operatingSystem}',
    );
  }

  bool connect({
    required String host,
    required int port,
    required String username,
    required String password,
    String domain = '',
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
          ) !=
          0;
    } finally {
      calloc.free(hostPtr);
      calloc.free(usernamePtr);
      calloc.free(passwordPtr);
      calloc.free(domainPtr);
    }
  }

  bool disconnect() {
    return _disconnect() != 0;
  }

  bool get isConnected {
    return _isConnected() != 0;
  }
}

typedef _ConnectNative = ffi.Int32 Function(
  ffi.Pointer<Utf8>,
  ffi.Int32,
  ffi.Pointer<Utf8>,
  ffi.Pointer<Utf8>,
  ffi.Pointer<Utf8>,
);

typedef _ConnectDart = int Function(
  ffi.Pointer<Utf8>,
  int,
  ffi.Pointer<Utf8>,
  ffi.Pointer<Utf8>,
  ffi.Pointer<Utf8>,
);

typedef _DisconnectNative = ffi.Int32 Function();

typedef _DisconnectDart = int Function();

typedef _IsConnectedNative = ffi.Int32 Function();

typedef _IsConnectedDart = int Function();
