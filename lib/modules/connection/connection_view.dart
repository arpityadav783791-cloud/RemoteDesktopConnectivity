import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'connection_controller.dart';

class ConnectionView extends GetView<ConnectionController> {
  const ConnectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.isEditing ? 'Edit Connection' : 'Add Connection',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: controller.nameController,
              decoration: const InputDecoration(labelText: 'Connection Name'),
            ),
            TextField(
              controller: controller.hostController,
              decoration: const InputDecoration(
                labelText: 'IP Address / Hostname',
              ),
            ),
            TextField(
              controller: controller.usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: controller.passwordController,
              decoration: const InputDecoration(labelText: 'password'),
            ),
            TextField(
              controller: controller.domainController,
              decoration: const InputDecoration(labelText: 'Domain (Optional)'),
            ),

            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'RDP Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            Obx(
              () => SwitchListTile(
                title: const Text('Fullscreen'),
                value: controller.fullscreen.value,
                onChanged: (value) {
                  controller.fullscreen.value = value;
                },
              ),
            ),

            Obx(
              () => SwitchListTile(
                title: const Text('Clipboard'),
                value: controller.clipboard.value,
                onChanged: (value) {
                  controller.clipboard.value = value;
                },
              ),
            ),

            Obx(
              () => SwitchListTile(
                title: const Text('Audio'),
                value: controller.audio.value,
                onChanged: (value) {
                  controller.audio.value = value;
                },
              ),
            ),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Resolution',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 8),

            Obx(
              () => DropdownButtonFormField<String>(
                initialValue:
                    '${controller.width.value}x${controller.height.value}',
                decoration: const InputDecoration(
                  labelText: 'Screen Resolution',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: '1280x720',
                    child: Text('1280 × 720'),
                  ),
                  DropdownMenuItem(
                    value: '1366x768',
                    child: Text('1366 × 768'),
                  ),
                  DropdownMenuItem(
                    value: '1920x1080',
                    child: Text('1920 × 1080'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  final parts = value.split('x');

                  controller.width.value = int.parse(parts[0]);
                  controller.height.value = int.parse(parts[1]);
                },
              ),
            ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: controller.saveConnection,
              child: const Text('Save Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
