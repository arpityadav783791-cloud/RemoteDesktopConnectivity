import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/services/rdp_service.dart';
import '../../data/models/rdp_connection.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linux RDP Client'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'Search connections...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: controller.searchController.clear,
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remote Desktop',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Get.toNamed(AppRoutes.connection);
                    controller.loadConnections();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Connection'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Expanded(
              child: Obx(() {
                if (controller.filteredConnections.isEmpty) {
                  return Center(
                    child: Text(
                      controller.searchQuery.value.isNotEmpty
                          ? 'No connections match your search'
                          : 'No saved connections',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: controller.filteredConnections.length,
                  itemBuilder: (context, index) {
                    final connection =
                        controller.filteredConnections[index];

                    // The connection OBJECT is passed to every action —
                    // the filtered-list index is never used as an index
                    // into the unfiltered list.
                    return _buildConnectionCard(context, connection);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(
    BuildContext context,
    RdpConnection connection,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              children: [
                const CircleAvatar(child: Icon(Icons.desktop_windows_outlined)),
                const SizedBox(height: 4),
                Obx(() {
                  final isFavorite = controller.isFavorite(connection);

                  return IconButton(
                    tooltip: isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                    onPressed: () {
                      controller.toggleFavorite(connection);
                    },
                  );
                }),
              ],
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connection.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  const SizedBox(height: 4),

                  Text('${connection.username}@${connection.host}'),

                  const SizedBox(height: 8),

                  Obx(() {
                    final status = controller.getStatus(connection);

                    return _buildStatusText(status);
                  }),
                ],
              ),
            ),

            Obx(() {
              final status = controller.getStatus(connection);
              if (status == RdpStatus.connecting) {
                return ElevatedButton.icon(
                  onPressed: null,
                  icon: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  label: const Text('Connecting...'),
                );
              }

              if (status == RdpStatus.connected) {
                return ElevatedButton.icon(
                  onPressed: () {
                    controller.disconnect(connection);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Disconnect'),
                );
              }

              return ElevatedButton.icon(
                onPressed: () {
                  controller.connect(connection);
                },
                icon: const Icon(Icons.login),
                label: const Text('Connect'),
              );
            }),

            const SizedBox(width: 8),

            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                controller.editConnection(connection);
              },
            ),

            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                controller.deleteConnection(connection);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusText(RdpStatus status) {
    switch (status) {
      case RdpStatus.connecting:
        return const Text('Connecting...');

      case RdpStatus.connected:
        return const Text('Connected');

      case RdpStatus.failed:
        return const Text('Connection failed');

      case RdpStatus.disconnected:
        return const Text('Disconnected');
    }
  }
}
