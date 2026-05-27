import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/constants/app_colors.dart';
import '../../models/service.dart';
import '../../providers/providers.dart';
import 'service_form_view.dart';

class ServiceManagementView extends ConsumerWidget {
  const ServiceManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesNotifierProvider);
    final surface = Theme.of(context).colorScheme.surface;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Hizmet Yönetimi'),
        backgroundColor: surface,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add),
            onPressed: () => Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const ServiceFormView()),
            ),
          ),
        ],
      ),
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (services) => services.isEmpty
            ? _EmptyState(onAdd: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const ServiceFormView()),
                ))
            : ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: services.length,
                onReorderItem: (oldIdx, newIdx) {
                  final updated = [...services];
                  final item = updated.removeAt(oldIdx);
                  if (newIdx > oldIdx) newIdx -= 1;
                  updated.insert(newIdx, item);
                  ref
                      .read(servicesNotifierProvider.notifier)
                      .reorder(updated);
                },
                itemBuilder: (_, i) {
                  final svc = services[i];
                  return Padding(
                    key: ValueKey('container_${svc.id}'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: Slidable(
                      key: ValueKey('slidable_${svc.id}'),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.25,
                        dismissible: DismissiblePane(
                          onDismissed: () {},
                          confirmDismiss: () async {
                            final result = await _confirmDelete(context, ref, svc);
                            return result == true;
                          },
                        ),
                        children: [
                          SlidableAction(
                            onPressed: (context) async {
                              await _confirmDelete(context, ref, svc);
                            },
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            icon: CupertinoIcons.trash,
                            label: 'Sil',
                          ),
                        ],
                      ),
                      child: _ServiceTile(
                        service: svc,
                        onEdit: () => Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => ServiceFormView(service: svc),
                          ),
                        ),
                        onDelete: () => _confirmDelete(context, ref, svc),
                      ),
                    ),
                  ),
                );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'services-fab',
        onPressed: () => Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const ServiceFormView()),
        ),
        backgroundColor: primary,
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
    );
  }

  Future<bool?> _confirmDelete(
      BuildContext context, WidgetRef ref, Service service) async {
    final proceed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('"${service.name}" Silinsin mi?'),
        content: const Text(
            'Bu hizmet silinecek. Mevcut randevular etkilenmez.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (proceed == true) {
      await ref
          .read(servicesNotifierProvider.notifier)
          .deleteService(service.id);
    }
    return proceed;
  }
}

class _ServiceTile extends StatelessWidget {
  final Service service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceTile({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: service.color.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: service.color.withAlpha(80)),
        ),
        child: Icon(CupertinoIcons.briefcase, color: service.color, size: 16),
      ),
      title: Text(service.name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text('${service.durationMinutes} dakika',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.line_horizontal_3,
              size: 18, color: AppColors.textSecondary),
        ],
      ),
      onTap: onEdit,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.briefcase,
              size: 56,
              color: AppColors.textSecondary.withAlpha(120)),
          const SizedBox(height: 12),
          const Text('Henüz hizmet yok',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(CupertinoIcons.add, size: 16),
            label: const Text('Hizmet Ekle'),
          ),
        ],
      ),
    );
  }
}
