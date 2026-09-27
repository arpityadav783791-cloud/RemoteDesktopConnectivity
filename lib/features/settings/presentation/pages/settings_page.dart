import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body:  ListView(
          children: [
            ListTile(
              leading: Icon(Icons.security_outlined),
              title: Text('Local / Remote Isolation'),
              subtitle: Text(
                'Clipboard, local drives, printers, microphone and unnecessary device redirection are disabled.',
              ),
            ),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('About'),
              subtitle: Text('RemoteDesktopConnectivity'),
            ),
          ],
        ),
      );
}
