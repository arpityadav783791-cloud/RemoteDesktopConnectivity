import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/rdp_service.dart';
import '../../../../data/models/rdp_connection.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Remote Desktop'),
          actions: [
            IconButton(
              onPressed: () => Get.toNamed(AppRoutes.settings),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: controller.addConnection,
          icon: const Icon(Icons.add),
          label: const Text('Add Connection'),
        ),
        body: Obx(() {
          if (controller.connections.isEmpty) return _empty();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: controller.searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search connections',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: controller.filteredConnections.isEmpty
                    ? const Center(child: Text('No matching connections.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: controller.filteredConnections.length,
                        itemBuilder: (_, i) =>
                            _card(controller.filteredConnections[i]),
                      ),
              ),
            ],
          );
        }),
      );

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.desktop_windows_outlined, size: 64),
              const SizedBox(height: 16),
              const Text('No connections yet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Add an RDP connection to get started.'),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: controller.addConnection,
                icon: const Icon(Icons.add),
                label: const Text('Add Connection'),
              ),
            ],
          ),
        ),
      );

  Widget _card(RdpConnection c) => Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.computer),
        ),
        title: Text(c.name),
        subtitle: Obx(() {
          final status = controller.statusOf(c);

          if (status == RdpStatus.connected) {
            return Text(
              '${c.username}@${c.host} • Connected',
            );
          }

          if (status == RdpStatus.connecting) {
            return Text(
              '${c.username}@${c.host} • Connecting...',
            );
          }

          if (status == RdpStatus.failed) {
            return Text(
              '${c.username}@${c.host} • Connection failed',
            );
          }

          return Text(
            '${c.username}@${c.host}',
          );
        }),
        onTap: () => controller.connect(c),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              final status = controller.statusOf(c);

              switch (status) {
                case RdpStatus.connected:
                  return const Icon(
                    Icons.circle,
                    size: 12,
                    color: Colors.green,
                  );

                case RdpStatus.connecting:
                  return const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  );

                case RdpStatus.failed:
                  return const Icon(
                    Icons.error_outline,
                    size: 20,
                    color: Colors.red,
                  );

                case RdpStatus.disconnecting:
                  return const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  );

                case RdpStatus.disconnected:
                  return const Icon(
                    Icons.circle_outlined,
                    size: 12,
                  );
              }
            }),
            IconButton(
              onPressed: () => controller.toggleFavorite(c),
              icon: Icon(
                c.favorite ? Icons.star : Icons.star_border,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'connect') {
                  controller.connect(c);
                }

                if (v == 'disconnect') {
                  controller.disconnect();
                }

                if (v == 'edit') {
                  controller.editConnection(c);
                }

                if (v == 'delete') {
                  controller.deleteConnection(c);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'connect',
                  child: Text('Connect'),
                ),
                PopupMenuItem(
                  value: 'disconnect',
                  child: Text('Disconnect'),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
}
