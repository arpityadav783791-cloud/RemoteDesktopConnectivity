import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/connection_controller.dart';

class ConnectionPage extends GetView<ConnectionController> {
  const ConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final editing = controller.isEditing;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit Connection' : 'Add Connection')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: controller.name,
              decoration: const InputDecoration(labelText: 'Connection Name')),
          const SizedBox(height: 16),
          TextField(controller: controller.host,
              decoration: const InputDecoration(labelText: 'Host / IP')),
          const SizedBox(height: 16),
          TextField(controller: controller.username,
              decoration: const InputDecoration(labelText: 'Username')),
          const SizedBox(height: 16),
          TextField(
            controller: controller.password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 16),
          TextField(controller: controller.domain,
              decoration: const InputDecoration(labelText: 'Domain (optional)')),
          const SizedBox(height: 8),
          Obx(() => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Remember Me'),
                subtitle: const Text('Store the password securely for future connections.'),
                value: controller.rememberMe.value,
                onChanged: (v) => controller.rememberMe.value = v,
              )),
          const Divider(height: 32),
          Obx(() => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fullscreen'),
                value: controller.fullscreen.value,
                onChanged: (v) => controller.fullscreen.value = v,
              )),
          Obx(() => controller.fullscreen.value
              ? const SizedBox.shrink()
              : Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: controller.width.value,
                        decoration: const InputDecoration(labelText: 'Width'),
                        items: const [1024, 1280, 1366, 1600, 1920]
                            .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                            .toList(),
                        onChanged: (v) { if (v != null) controller.width.value = v; },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: controller.height.value,
                        decoration: const InputDecoration(labelText: 'Height'),
                        items: const [600, 720, 768, 900, 1080]
                            .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                            .toList(),
                        onChanged: (v) { if (v != null) controller.height.value = v; },
                      ),
                    ),
                  ],
                )),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: controller.save,
            icon: const Icon(Icons.save_outlined),
            label: Text(editing ? 'Save Changes' : 'Save Connection'),
          ),
        ],
      ),
    );
  }
}
