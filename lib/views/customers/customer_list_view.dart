import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/constants/app_colors.dart';
import '../../models/customer.dart';
import '../../providers/providers.dart';
import 'customer_detail_view.dart';
import 'customer_form_view.dart';
import '../appointments/appointment_form_view.dart';

class CustomerListView extends ConsumerWidget {
  const CustomerListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(filteredCustomersProvider);
    final query = ref.watch(customerSearchProvider);
    final isLoading = ref.watch(customersNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Müşteriler'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TapRegion(
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              child: CupertinoSearchTextField(
                placeholder: 'İsim veya telefon ara...',
                onChanged: (v) =>
                    ref.read(customerSearchProvider.notifier).state = v,
                onSubmitted: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : customers.isEmpty
          ? _EmptyState(hasQuery: query.isNotEmpty)
          : ListView.separated(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              itemCount: customers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _CustomerTile(customer: customers[i]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customers-fab',
        onPressed: () => Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const CustomerFormView()),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        label: const Text(
          'Müşteri Ekle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
    );
  }
}

class _CustomerTile extends ConsumerWidget {
  final Customer customer;

  const _CustomerTile({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAppointments = ref.watch(appointmentsNotifierProvider).value ?? [];
    final count = allAppointments
        .where((a) => a.customerId == customer.id && !a.isCancelled)
        .length;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Slidable(
        key: ValueKey(customer.id),
        // Sağa kaydırma: Randevu Ekle
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.25,
          dismissible: DismissiblePane(
            onDismissed: () {},
            confirmDismiss: () async {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => AppointmentFormView(
                    initialDate: DateTime.now(),
                    initialCustomer: customer,
                  ),
                ),
              );
              return false;
            },
          ),
          children: [
            SlidableAction(
              onPressed: (context) {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => AppointmentFormView(
                      initialDate: DateTime.now(),
                      initialCustomer: customer,
                    ),
                  ),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              icon: CupertinoIcons.calendar_badge_plus,
              label: 'Randevu',
            ),
          ],
        ),
        // Sola kaydırma: Silme
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.25,
          dismissible: DismissiblePane(
            onDismissed: () {},
            confirmDismiss: () async {
              final futureAppointments = await ref
                  .read(appointmentRepositoryProvider)
                  .getFutureByCustomer(customer.id);
              final hasFuture = futureAppointments.isNotEmpty;
              if (!context.mounted) return false;

              final proceed = await showCupertinoDialog<bool>(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: Text(
                    hasFuture ? 'Gelecek Randevular Var!' : 'Müşteriyi Sil',
                  ),
                  content: Text(
                    hasFuture
                        ? '${customer.name} isimli müşterinin ${futureAppointments.length} adet gelecek randevusu bulunuyor. Müşteriyi silerseniz bu randevular da silinecektir. Devam etmek istiyor musunuz?'
                        : '${customer.name} isimli müşteriyi silmek istediğinize emin misiniz? Geçmiş randevu kayıtları saklanacaktır.',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('Vazgeç'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: const Text('Sil'),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (proceed == true) {
                ref
                    .read(customersNotifierProvider.notifier)
                    .deleteCustomer(
                      customer.id,
                      deleteFutureAppointments: true,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${customer.name} silindi'),
                      action: SnackBarAction(
                        label: 'Geri Al',
                        onPressed: () {
                          ref
                              .read(customersNotifierProvider.notifier)
                              .addCustomer(customer);
                        },
                      ),
                    ),
                  );
                }
                return true;
              }
              return false;
            },
          ),
          children: [
            SlidableAction(
              onPressed: (context) async {
                final futureAppointments = await ref
                    .read(appointmentRepositoryProvider)
                    .getFutureByCustomer(customer.id);
                final hasFuture = futureAppointments.isNotEmpty;
                if (!context.mounted) return;

                final proceed = await showCupertinoDialog<bool>(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: Text(
                      hasFuture ? 'Gelecek Randevular Var!' : 'Müşteriyi Sil',
                    ),
                    content: Text(
                      hasFuture
                          ? '${customer.name} isimli müşterinin ${futureAppointments.length} adet gelecek randevusu bulunuyor. Müşteriyi silerseniz bu randevular da silinecektir. Devam etmek istiyor musunuz?'
                          : '${customer.name} isimli müşteriyi silmek istediğinize emin misiniz? Geçmiş randevu kayıtları saklanacaktır.',
                    ),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('Vazgeç'),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        child: const Text('Sil'),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ],
                  ),
                );

                if (proceed == true) {
                  ref
                      .read(customersNotifierProvider.notifier)
                      .deleteCustomer(
                        customer.id,
                        deleteFutureAppointments: true,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${customer.name} silindi'),
                        action: SnackBarAction(
                          label: 'Geri Al',
                          onPressed: () {
                            ref
                                .read(customersNotifierProvider.notifier)
                                .addCustomer(customer);
                          },
                        ),
                      ),
                    );
                  }
                }
              },
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              icon: CupertinoIcons.trash,
              label: 'Sil',
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => CustomerDetailView(customer: customer),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withAlpha(25),
                  child: Text(
                    customer.initials,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.phone,
                            size: 11,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            customer.phone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Text(
                      'randevu',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasQuery;

  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasQuery ? CupertinoIcons.search : CupertinoIcons.person_2,
            size: 56,
            color: AppColors.textSecondary.withAlpha(120),
          ),
          const SizedBox(height: 12),
          Text(
            hasQuery ? 'Sonuç bulunamadı' : 'Henüz müşteri yok',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasQuery
                ? 'Farklı bir arama deneyin.'
                : 'Yeni müşteri eklemek için + butonuna dokunun.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
