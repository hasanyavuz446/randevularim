import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../models/appointment.dart';
import '../../providers/providers.dart';
import '../appointments/appointment_form_view.dart';
import '../appointments/appointment_detail_view.dart';
import '../settings/settings_view.dart';

class HomeView extends ConsumerWidget {
  final VoidCallback onShowAppointments;
  final VoidCallback onShowReports;

  const HomeView({
    super.key,
    required this.onShowAppointments,
    required this.onShowReports,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final appointments = ref.watch(todayAppointmentsProvider);
    final allAppointments =
        ref.watch(appointmentsNotifierProvider).value ?? const <Appointment>[];
    final stats = ref.watch(statisticsProvider);
    final bizAsync = ref.watch(businessNotifierProvider);
    final now = DateTime.now();

    final todaysUpcoming = appointments
        .where((a) => a.isActive && a.endTime.isAfter(now))
        .toList();
    final featured = todaysUpcoming.firstOrNull;
    final upcomingAppointments =
        allAppointments
            .where(
              (a) =>
                  a.isActive && a.endTime.isAfter(now) && a.id != featured?.id,
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final completedCount = appointments.where((a) => a.isCompleted).length;
    final noShowCount = appointments.where((a) => a.isNoShow).length;
    final activeCount = appointments.where((a) => a.isActive).length;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium Header ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withBlue(100)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(today),
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    bizAsync.when(
                      data: (biz) => Text(
                        biz.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      loading: () =>
                          const CupertinoActivityIndicator(color: Colors.white),
                      error: (_, _) => const Text(
                        'Hoş Geldiniz',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withAlpha(40),
                  child: IconButton(
                    icon: const Icon(
                      CupertinoIcons.settings,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const SettingsView()),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatSquare(
                        label: 'AKTİF',
                        value: '$activeCount',
                        subValue: 'Bugün planlanan',
                        icon: CupertinoIcons.calendar,
                        color: Colors.blue,
                        onTap: onShowAppointments,
                      ),
                      const SizedBox(width: 12),
                      _StatSquare(
                        label: 'TAMAMLANDI',
                        value: '$completedCount',
                        subValue: '${stats.todayRevenue.toStringAsFixed(0)} TL',
                        icon: CupertinoIcons.check_mark_circled,
                        color: AppColors.success,
                        onTap: onShowReports,
                      ),
                    ],
                  ),
                  if (noShowCount > 0) ...[
                    const SizedBox(height: 12),
                    _AttentionCard(
                      text:
                          '$noShowCount müşteri bugün gelmedi olarak işaretlendi.',
                    ),
                  ],
                  if (featured != null) ...[
                    const SizedBox(height: 24),
                    _HeroAppointmentCard(appointment: featured),
                  ],
                  if (upcomingAppointments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionHeader(title: 'Sıradaki Diğer Randevular'),
                    const SizedBox(height: 12),
                    _UpcomingAppointmentsCard(
                      appointments: upcomingAppointments.take(4).toList(),
                      onShowAll: onShowAppointments,
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home-fab',
        onPressed: () => Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const AppointmentFormView()),
        ),
        backgroundColor: primary,
        elevation: 4,
        label: const Text(
          'Randevu Ekle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
    );
  }
}

class _StatSquare extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatSquare({
    required this.label,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: '$subValue detaylarını aç',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 14, color: color),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subValue,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const _HeroAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => AppointmentDetailView(appointment: appointment),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withAlpha(30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('HH:mm').format(appointment.dateTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    appointment.customerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    appointment.serviceName,
                    style: TextStyle(
                      color: Colors.white.withAlpha(160),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _HeroIconAction(
              icon: CupertinoIcons.phone_fill,
              tooltip: 'Ara',
              onTap: () => launchUrl(
                Uri.parse(
                  'tel:${appointment.customerPhone.replaceAll(RegExp(r'[^0-9+]'), '')}',
                ),
              ),
            ),
            const SizedBox(width: 8),
            _HeroIconAction(
              icon: CupertinoIcons.chat_bubble_fill,
              tooltip: 'WhatsApp',
              onTap: () {
                final phone = appointment.customerPhone.replaceAll(
                  RegExp(r'[^0-9]'),
                  '',
                );
                final cleanPhone = phone.startsWith('0') ? '9$phone' : phone;
                launchUrl(Uri.parse('https://wa.me/$cleanPhone'));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final String text;

  const _AttentionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            color: AppColors.warning,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeroIconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 19),
        ),
      ),
    );
  }
}

class _UpcomingAppointmentsCard extends StatelessWidget {
  final List<Appointment> appointments;
  final VoidCallback onShowAll;

  const _UpcomingAppointmentsCard({
    required this.appointments,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ...appointments.asMap().entries.map(
            (entry) => Column(
              children: [
                _UpcomingAppointmentItem(appointment: entry.value),
                if (entry.key != appointments.length - 1)
                  const Divider(height: 1, indent: 78),
              ],
            ),
          ),
          const Divider(height: 1),
          TextButton(onPressed: onShowAll, child: const Text('Tümünü Gör')),
        ],
      ),
    );
  }
}

class _UpcomingAppointmentItem extends StatelessWidget {
  final Appointment appointment;

  const _UpcomingAppointmentItem({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(appointment.serviceColor);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => AppointmentDetailView(appointment: appointment),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(appointment.dateTime),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      DateFormat('d MMM', 'tr_TR').format(appointment.dateTime),
                      style: TextStyle(color: color, fontSize: 9),
                    ),
                  ],
                ),
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appointment.serviceName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 14),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    );
  }
}
