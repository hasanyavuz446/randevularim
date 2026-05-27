import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/appointment.dart';
import '../../providers/providers.dart';
import '../appointments/appointment_detail_view.dart';

class DayTimelineView extends ConsumerWidget {
  final DateTime date;

  static const _hourHeight = 84.0;
  static const _leftColumnWidth = 56.0;

  const DayTimelineView({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biz = ref.watch(businessNotifierProvider).value;
    final appointments = ref.watch(appointmentsForDateProvider(date));
    final now = DateTime.now();

    final startHour = biz != null
        ? int.parse(biz.openingTime.split(':')[0])
        : 8;
    final endHour = biz != null
        ? int.parse(biz.closingTime.split(':')[0]) + 1
        : 21;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: SizedBox(
          height: (endHour - startHour + 1) * _hourHeight + 60,
          child: Stack(
            children: [
              _buildHourGrid(startHour, endHour, context),
              if (isSameDay(date, now))
                _buildCurrentTimeIndicator(now, startHour, endHour),
              ...appointments.map(
                (a) => _buildAppointmentCard(context, a, startHour),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourGrid(int start, int end, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(end - start + 1, (i) {
        final hour = start + i;
        return SizedBox(
          height: _hourHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _leftColumnWidth,
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary.withAlpha(150),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.only(top: 8),
                  color: Theme.of(context).dividerColor.withAlpha(100),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentTimeIndicator(DateTime now, int start, int end) {
    if (now.hour < start || now.hour >= end + 1) return const SizedBox.shrink();

    final top = _minuteOffset(now.hour, now.minute, start) + 8;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: _leftColumnWidth,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                DateFormat('HH:mm').format(now),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.danger, AppColors.danger.withAlpha(0)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    Appointment appt,
    int start,
  ) {
    final top =
        _minuteOffset(appt.dateTime.hour, appt.dateTime.minute, start) + 8;
    final durationHeight = (appt.durationMinutes / 60.0 * _hourHeight);
    final height = durationHeight.clamp(32.0, double.infinity) - 4;

    final color = AppColors.fromHex(appt.serviceColor);
    return Positioned(
      top: top,
      left: _leftColumnWidth + 8,
      right: 0,
      height: height,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => AppointmentDetailView(appointment: appt),
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: appt.isCancelled || appt.isNoShow
                ? Theme.of(context).disabledColor.withAlpha(18)
                : color.withAlpha(40),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: appt.isCancelled || appt.isNoShow
                  ? Theme.of(context).disabledColor.withAlpha(80)
                  : color.withAlpha(80),
              width: 1,
            ),
            boxShadow: appt.isCancelled || appt.isNoShow
                ? null
                : [
                    BoxShadow(
                      color: color.withAlpha(20),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(
                    color: appt.isCancelled || appt.isNoShow
                        ? Theme.of(context).disabledColor
                        : color,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              appt.customerName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: appt.isCancelled || appt.isNoShow
                                    ? Theme.of(context).disabledColor
                                    : Theme.of(context).colorScheme.onSurface,
                                decoration: appt.isCancelled || appt.isNoShow
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(appt.dateTime),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: appt.isCancelled || appt.isNoShow
                                  ? Theme.of(context).disabledColor
                                  : color,
                            ),
                          ),
                        ],
                      ),
                      if (height > 50) ...[
                        const SizedBox(height: 2),
                        Text(
                          appt.serviceName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _minuteOffset(int hour, int minute, int start) {
    final totalMinutes = (hour - start) * 60 + minute;
    return (totalMinutes / 60.0) * _hourHeight;
  }
}
