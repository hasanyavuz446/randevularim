import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../models/enums.dart';
import '../../providers/providers.dart';
import '../../core/constants/app_colors.dart';
import 'appointment_detail_view.dart';
import 'appointment_form_view.dart';

class AppointmentListView extends ConsumerWidget {
  const AppointmentListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsNotifierProvider);
    final searchQuery = ref.watch(appointmentSearchProvider);
    final filter = ref.watch(appointmentFilterProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Randevularım'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TapRegion(
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  child: CupertinoSearchTextField(
                    placeholder: 'Müşteri veya hizmet ara...',
                    onChanged: (v) =>
                        ref.read(appointmentSearchProvider.notifier).state = v,
                    onSubmitted: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                          (AppointmentFilter.upcoming, 'Yaklaşan'),
                          (AppointmentFilter.archive, 'Arşiv'),
                        ].map((option) {
                          final selected = filter == option.$1;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(option.$2),
                              selected: selected,
                              onSelected: (_) =>
                                  ref
                                      .read(appointmentFilterProvider.notifier)
                                      .state = option
                                      .$1,
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          final now = DateTime.now();
          final filtered =
              appointments.where((a) {
                final matchesSearch =
                    a.customerName.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    a.serviceName.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    );

                final matchesFilter = switch (filter) {
                  AppointmentFilter.upcoming =>
                    a.isActive && a.endTime.isAfter(now),
                  AppointmentFilter.archive =>
                    !a.isActive || !a.endTime.isAfter(now),
                };

                return matchesSearch && matchesFilter;
              }).toList()..sort(
                filter == AppointmentFilter.upcoming
                    ? (a, b) => a.dateTime.compareTo(b.dateTime)
                    : (a, b) => b.dateTime.compareTo(a.dateTime),
              );

          if (filtered.isEmpty) {
            return _EmptyState(
              hasSearch: searchQuery.isNotEmpty,
              filter: filter,
            );
          }

          final grouped = filter == AppointmentFilter.upcoming
              ? _groupUpcomingAppointments(filtered)
              : _groupArchivedAppointments(filtered);

          return ListView.builder(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final group = grouped[index];
              if (group is String) {
                return _SectionHeader(title: group);
              } else {
                return _AppointmentListItem(appointment: group as Appointment);
              }
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Bir hata oluştu: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'appointments-fab',
        onPressed: () => Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const AppointmentFormView()),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        label: const Text(
          'Randevu Ekle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
    );
  }

  List<dynamic> _groupUpcomingAppointments(List<Appointment> list) {
    final List<dynamic> result = [];
    String? currentGroup;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final endOfWeek = today.add(
      Duration(days: DateTime.sunday - today.weekday),
    );

    for (final a in list) {
      final date = a.dateTime;
      final apptDay = DateTime(date.year, date.month, date.day);

      String group;
      if (apptDay == today) {
        group = 'Bugün';
      } else if (apptDay == tomorrow) {
        group = 'Yarın';
      } else if (!apptDay.isAfter(endOfWeek)) {
        group = 'Bu Hafta';
      } else {
        group = 'Daha Sonra';
      }

      if (group != currentGroup) {
        result.add(group);
        currentGroup = group;
      }
      result.add(a);
    }
    return result;
  }

  List<dynamic> _groupArchivedAppointments(List<Appointment> list) {
    final List<dynamic> result = [];
    String? currentGroup;
    final now = DateTime.now();

    for (final a in list) {
      final group = a.dateTime.year == now.year && a.dateTime.month == now.month
          ? 'Bu Ay'
          : DateFormat('MMMM yyyy', 'tr_TR').format(a.dateTime);

      if (group != currentGroup) {
        result.add(group);
        currentGroup = group;
      }
      result.add(a);
    }
    return result;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _AppointmentListItem extends ConsumerWidget {
  final Appointment appointment;
  const _AppointmentListItem({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColors.fromHex(appointment.serviceColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Slidable(
          key: ValueKey(appointment.id),
          endActionPane: appointment.isActive
              ? ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.5,
                  children: [
                    SlidableAction(
                      onPressed: (_) =>
                          _confirmComplete(context, ref, appointment),
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      icon: CupertinoIcons.checkmark_circle,
                      label: 'Bitti',
                    ),
                    SlidableAction(
                      onPressed: (_) =>
                          _confirmCancel(context, ref, appointment),
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      icon: CupertinoIcons.xmark_circle,
                      label: 'İptal',
                    ),
                  ],
                )
              : null,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => AppointmentDetailView(appointment: appointment),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.calendar,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${appointment.serviceName} - ${DateFormat('d MMM, EEE', 'tr_TR').format(appointment.dateTime)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(appointment.dateTime),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _StatusChip(status: appointment.status),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmComplete(BuildContext context, WidgetRef ref, Appointment appt) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Tamamlandı mı?'),
        content: Text(
          '${appt.customerName} randevusu tamamlandı olarak işaretlenecek.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Vazgeç'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Tamamla'),
            onPressed: () {
              ref
                  .read(appointmentsNotifierProvider.notifier)
                  .completeAppointment(appt.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, Appointment appt) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Randevuyu İptal Et'),
        content: const Text('Bu randevu iptal edilecek.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Vazgeç'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('İptal Et'),
            onPressed: () {
              ref
                  .read(appointmentsNotifierProvider.notifier)
                  .cancelAppointment(appt.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AppointmentStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final (color, bg) = switch (status) {
      AppointmentStatus.scheduled => (primary, primary.withAlpha(20)),
      AppointmentStatus.confirmed => (
        const Color(0xFF007AFF),
        const Color(0xFF007AFF).withAlpha(20),
      ),
      AppointmentStatus.completed => (
        AppColors.success,
        AppColors.success.withAlpha(20),
      ),
      AppointmentStatus.cancelled => (
        AppColors.danger,
        AppColors.danger.withAlpha(20),
      ),
      AppointmentStatus.noShow => (
        AppColors.warning,
        AppColors.warning.withAlpha(20),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final AppointmentFilter filter;
  const _EmptyState({required this.hasSearch, required this.filter});

  @override
  Widget build(BuildContext context) {
    final isUpcoming = filter == AppointmentFilter.upcoming;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch
                ? CupertinoIcons.search
                : CupertinoIcons.calendar_badge_plus,
            size: 64,
            color: AppColors.textSecondary.withAlpha(80),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch
                ? 'Sonuç bulunamadı'
                : isUpcoming
                ? 'Yaklaşan randevu yok'
                : 'Arşivlenmiş randevu yok',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          if (hasSearch)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Farklı bir arama veya filtre deneyin.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}
