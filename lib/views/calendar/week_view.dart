import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/appointment.dart';
import '../../providers/providers.dart';
import '../appointments/appointment_detail_view.dart';

class WeekView extends ConsumerWidget {
  final DateTime anchorDate;

  const WeekView({super.key, required this.anchorDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekDays = _weekDays(anchorDate);
    final allAsync = ref.watch(appointmentsNotifierProvider);
    final allAppointments = allAsync.value ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: weekDays.length,
      itemBuilder: (context, index) {
        final day = weekDays[index];
        final dayAppts = allAppointments
            .where((a) => !a.isCancelled && _sameDay(a.dateTime, day))
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

        return _DayAgendaSection(day: day, appointments: dayAppts);
      },
    );
  }

  List<DateTime> _weekDays(DateTime anchor) {
    final weekday = anchor.weekday;
    final monday = anchor.subtract(Duration(days: weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayAgendaSection extends StatelessWidget {
  final DateTime day;
  final List<Appointment> appointments;

  const _DayAgendaSection({required this.day, required this.appointments});

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(day);
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
          child: Row(
            children: [
              Text(
                DateFormat('d MMMM, EEEE', 'tr_TR').format(day),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isToday ? primary : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(4)),
                  child: const Text('BUGÜN', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
        if (appointments.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text('Randevu yok', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          )
        else
          ...appointments.map((a) => _AgendaCard(appointment: a)),
        const Divider(height: 32),
      ],
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _AgendaCard extends StatelessWidget {
  final Appointment appointment;
  const _AgendaCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(appointment.serviceColor);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => AppointmentDetailView(appointment: appointment),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Text(
              DateFormat('HH:mm').format(appointment.dateTime),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.customerName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    appointment.serviceName,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}
