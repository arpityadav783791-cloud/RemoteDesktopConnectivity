import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/services/rdp_service.dart';
import '../../../home/presentation/controllers/home_controller.dart';

class RemoteDesktopPage extends StatefulWidget {
  const RemoteDesktopPage({super.key});

  @override
  State<RemoteDesktopPage> createState() => _RemoteDesktopPageState();
}

class _RemoteDesktopPageState extends State<RemoteDesktopPage> {
  static const _move = 0x0800;
  static const _down = 0x8000;
  static const _left = 0x1000;
  static const _right = 0x2000;
  static const _middle = 0x4000;
  static const _wheel = 0x0200;
  static const _wheelNegative = 0x0100;
  static const _extended = 0x0100;
  static const _release = 0x8000;

  late final RdpService _service;
  late final FocusNode _focusNode;
  late final Timer _timer;

  ui.Image? _image;
  int _width = 1280;
  int _height = 720;
  bool _ended = false;

  @override
  void initState() {
    super.initState();

    _service = Get.find<HomeController>().rdpService;
    _focusNode = FocusNode();

    _timer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _poll(),
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  void _poll() {
    if (!mounted) return;

    if (!_service.isConnected) {
      if (!_ended) {
        setState(() => _ended = true);
      }
      return;
    }

    final frame = _service.readFrame();

    if (frame == null) return;

    _width = frame.width;
    _height = frame.height;

    ui.decodeImageFromPixels(
      frame.pixels,
      frame.width,
      frame.height,
      ui.PixelFormat.rgba8888,
      (image) {
        if (!mounted) {
          image.dispose();
          return;
        }

        final old = _image;

        setState(() {
          _image = image;
        });

        old?.dispose();
      },
      rowBytes: frame.width * 4,
    );
  }

  Future<void> _close() async {
    await _service.disconnect();

    if (mounted) {
      Get.back();
    }
  }

  int _x(double value, double width) {
    if (width <= 0) return 0;

    return (value / width * _width).round().clamp(0, _width - 1).toInt();
  }

  int _y(double value, double height) {
    if (height <= 0) return 0;

    return (value / height * _height).round().clamp(0, _height - 1).toInt();
  }

  void _mouse(
    PointerEvent event,
    int flags,
    BoxConstraints constraints,
  ) {
    _service.sendMouse(
      flags: flags,
      x: _x(
        event.localPosition.dx,
        constraints.maxWidth,
      ),
      y: _y(
        event.localPosition.dy,
        constraints.maxHeight,
      ),
    );
  }

  void _scroll(
    PointerSignalEvent event,
    BoxConstraints constraints,
  ) {
    if (event is! PointerScrollEvent) return;

    final delta = event.scrollDelta.dy;

    if (delta == 0) return;

    var flags = _wheel | delta.abs().round().clamp(1, 0x1FF).toInt();

    if (delta < 0) {
      flags |= _wheelNegative;
    }

    _mouse(event, flags, constraints);
  }

  void _key(KeyEvent event) {
    final key = _scan(event.physicalKey.usbHidUsage);

    if (key == null) return;

    var flags = key.extended ? _extended : 0;

    if (event is KeyUpEvent) {
      flags |= _release;
    }

    _service.sendKey(
      flags: flags,
      code: key.code,
    );
  }

  _RdpKey? _scan(int usage) {
    const letters = <int>[
      0x1E,
      0x30,
      0x2E,
      0x20,
      0x12,
      0x21,
      0x22,
      0x23,
      0x17,
      0x24,
      0x25,
      0x26,
      0x32,
      0x31,
      0x18,
      0x19,
      0x10,
      0x13,
      0x1F,
      0x14,
      0x16,
      0x2F,
      0x11,
      0x2D,
      0x15,
      0x2C,
    ];

    if (usage >= 0x04 && usage <= 0x1D) {
      return _RdpKey(
        letters[usage - 0x04],
      );
    }

    if (usage >= 0x1E && usage <= 0x27) {
      return _RdpKey(
        usage - 0x1C,
      );
    }

    const normal = <int, int>{
      0x28: 0x1C,
      0x29: 0x01,
      0x2A: 0x0E,
      0x2B: 0x0F,
      0x2C: 0x39,
      0x2D: 0x0C,
      0x2E: 0x0D,
      0x2F: 0x1A,
      0x30: 0x1B,
      0x31: 0x2B,
      0x33: 0x27,
      0x34: 0x28,
      0x35: 0x29,
      0x36: 0x33,
      0x37: 0x34,
      0x38: 0x35,
      0x39: 0x3A,
      0x46: 0x46,
      0x53: 0x45,
    };

    final code = normal[usage];

    if (code != null) {
      return _RdpKey(code);
    }

    if (usage >= 0x3A && usage <= 0x43) {
      return _RdpKey(
        0x3B + usage - 0x3A,
      );
    }

    if (usage == 0x44) {
      return const _RdpKey(0x57);
    }

    if (usage == 0x45) {
      return const _RdpKey(0x58);
    }

    const extended = <int, int>{
      0x49: 0x52,
      0x4A: 0x47,
      0x4B: 0x49,
      0x4C: 0x53,
      0x4D: 0x4F,
      0x4E: 0x51,
      0x4F: 0x4D,
      0x50: 0x4B,
      0x51: 0x50,
      0x52: 0x48,
      0x54: 0x35,
      0x58: 0x1C,
    };

    final extendedCode = extended[usage];

    if (extendedCode != null) {
      return _RdpKey(
        extendedCode,
        extended: true,
      );
    }

    const modifiers = <int, _RdpKey>{
      0xE0: _RdpKey(0x1D),
      0xE1: _RdpKey(0x2A),
      0xE2: _RdpKey(0x38),
      0xE3: _RdpKey(
        0x5B,
        extended: true,
      ),
      0xE4: _RdpKey(
        0x1D,
        extended: true,
      ),
      0xE5: _RdpKey(0x36),
      0xE6: _RdpKey(
        0x38,
        extended: true,
      ),
      0xE7: _RdpKey(
        0x5C,
        extended: true,
      ),
    };

    return modifiers[usage];
  }

  @override
  void dispose() {
    _timer.cancel();
    _focusNode.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _service.disconnect();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Remote Desktop Session',
          ),
          actions: [
            IconButton(
              tooltip: 'Disconnect',
              onPressed: _close,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        body: ColoredBox(
          color: Colors.black,
          child: Center(
            child: AspectRatio(
              aspectRatio: _width / _height,
              child: LayoutBuilder(
                builder: (
                  context,
                  constraints,
                ) {
                  return Focus(
                    focusNode: _focusNode,
                    autofocus: true,
                    onKeyEvent: (
                      _,
                      event,
                    ) {
                      _key(event);

                      return KeyEventResult.handled;
                    },
                    child: Listener(
                      onPointerMove: (event) {
                        var flags = _move;

                        if ((event.buttons & kPrimaryMouseButton) != 0) {
                          flags |= _left;
                        }

                        if ((event.buttons & kSecondaryMouseButton) != 0) {
                          flags |= _right;
                        }

                        if ((event.buttons & kMiddleMouseButton) != 0) {
                          flags |= _middle;
                        }

                        _mouse(
                          event,
                          flags,
                          constraints,
                        );
                      },
                      onPointerDown: (event) {
                        var flags = _down;

                        if (event.buttons == kPrimaryMouseButton) {
                          flags |= _left;
                        }

                        if (event.buttons == kSecondaryMouseButton) {
                          flags |= _right;
                        }

                        if (event.buttons == kMiddleMouseButton) {
                          flags |= _middle;
                        }

                        _mouse(
                          event,
                          flags,
                          constraints,
                        );
                      },
                      onPointerUp: (event) {
                        var flags = 0;

                        if (event.buttons == kPrimaryMouseButton) {
                          flags |= _left;
                        }

                        if (event.buttons == kSecondaryMouseButton) {
                          flags |= _right;
                        }

                        if (event.buttons == kMiddleMouseButton) {
                          flags |= _middle;
                        }

                        _mouse(
                          event,
                          flags,
                          constraints,
                        );
                      },
                      onPointerSignal: (event) {
                        _scroll(
                          event,
                          constraints,
                        );
                      },
                      child: _image == null
                          ? const Center(
                              child: Text(
                                'Waiting for remote desktop...',
                                style: TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            )
                          : RawImage(
                              image: _image,
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.low,
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RdpKey {
  const _RdpKey(
    this.code, {
    this.extended = false,
  });

  final int code;
  final bool extended;
}
