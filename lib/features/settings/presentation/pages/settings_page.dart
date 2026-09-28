import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionTitle(
            title: 'Security',
          ),

          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Local / Remote Isolation'),
            subtitle: const Text(
              'Clipboard, local drives, printers, microphone and '
              'unnecessary device redirection are disabled.',
            ),
            trailing: const Icon(
              Icons.check_circle_outline,
            ),
          ),

          const Divider(),

          const _SectionTitle(
            title: 'Connection',
          ),

          const ListTile(
            leading: Icon(Icons.lan_outlined),
            title: Text('RDP Port'),
            subtitle: Text('3389'),
          ),

          const ListTile(
            leading: Icon(Icons.desktop_windows_outlined),
            title: Text('Remote Desktop Backend'),
            subtitle: Text('FreeRDP'),
          ),

          const Divider(),

          const _SectionTitle(
            title: 'Application',
          ),

          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
            subtitle: Text(
              'RemoteDesktopConnectivity',
            ),
          ),

          const ListTile(
            leading: Icon(Icons.code_outlined),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}