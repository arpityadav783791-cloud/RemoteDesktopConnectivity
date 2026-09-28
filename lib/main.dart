import 'package:flutter/material.dart';

import 'core/native/rdp_bridge.dart';

void main() {
  final bridge = RdpBridge();

  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Remote Desktop Connectivity'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              final connected = bridge.connect(
                host: '127.0.0.1',
                port: 3389,
                username: 'YOUR_USERNAME',
                password: 'YOUR_PASSWORD',
              );

              debugPrint('RDP connect result: $connected');
              debugPrint('RDP connected: ${bridge.isConnected}');
            },
            child: const Text('Test RDP Connection'),
          ),
        ),
      ),
    ),
  );
}
