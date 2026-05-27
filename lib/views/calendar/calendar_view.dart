import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/enums.dart';
import '../../models/appointment.dart';
import '../../providers/providers.dart';
import '../appointments/appointment_form_view.dart';
import '../appointments/appointment_detail_view.dart';
import 'day_timeline_view.dart';
import 'week_view.dart';

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(calendarViewModeProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final allAppointments = ref.watch(appointmentsNotifierProvider).value ?? [];
    final dayAppointments = ref.watch(
      appointmentsForDateProvider(selectedDate),
    );
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Takvim'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              ref.read(selectedDateProvider.notifier).state = DateTime(
                now.year,
                now.month,
                now.day,
              );
            },
            child: const Text(
              'Bugün',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            color: Theme.of(context).colorScheme.surface,
            child: CupertinoSegmentedControl<CalendarViewMode>(
              children: const {
                CalendarViewMode.day: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Gün',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                CalendarViewMode.week: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Hafta',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                CalendarViewMode.month: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Ay',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              },
              groupValue: viewMode,
              onValueChanged: (v) =>
                  ref.read(calendarViewModeProvider.notifier).state = v,
              selectedColor: primary,
              borderColor: primary,
              unselectedColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (viewMode == CalendarViewMode.month)
            _buildMonthCalendar(selectedDate, allAppointments, primary)
          else
            _buildWeekStrip(selectedDate, allAppointments, primary),

          Expanded(
            child: _buildMainContent(viewMode, selectedDate, dayAppointments),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'calendar-fab',
        onPressed: () => Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => AppointmentFormView(initialDate: selectedDate),
          ),
        ),
        backgroundColor: primary,
        label: const Text(
          'Randevu Ekle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMonthCalendar(
    DateTime focused,
    List<Appointment> all,
    Color primary,
  ) {
    final surface = Theme.of(context).colorScheme.surface;
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      color: surface,
      child: TableCalendar(
        firstDay: DateTime.utc(2022, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focused,
        calendarFormat: CalendarFormat.month,
        headerVisible: true,
        daysOfWeekHeight: 30,
        rowHeight: 48,
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => isSameDay(day, focused),
        onDaySelected: (selected, _) {
          ref.read(selectedDateProvider.notifier).state = DateTime(
            selected.year,
            selected.month,
            selected.day,
          );
        },
        locale: 'tr_TR',
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(
            CupertinoIcons.chevron_left,
            size: 16,
            color: primary,
          ),
          rightChevronIcon: Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: primary,
          ),
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: primary.withAlpha(40),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: primary,
            fontWeight: FontWeight.bold,
          ),
          markerDecoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
        ),
        eventLoader: (day) {
          return all
              .where((a) => a.isActive && isSameDay(a.dateTime, day))
              .toList();
        },
      ),
    );
  }

  Widget _buildWeekStrip(
    DateTime focused,
    List<Appointment> all,
    Color primary,
  ) {
    final surface = Theme.of(context).colorScheme.surface;
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      color: surface,
      padding: const EdgeInsets.only(bottom: 8),
      child: TableCalendar(
        firstDay: DateTime.utc(2022, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focused,
        calendarFormat: CalendarFormat.week,
        headerVisible: true,
        daysOfWeekHeight: 20,
        rowHeight: 44,
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => isSameDay(day, focused),
        onDaySelected: (selected, _) {
          ref.read(selectedDateProvider.notifier).state = DateTime(
            selected.year,
            selected.month,
            selected.day,
          );
        },
        locale: 'tr_TR',
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          leftChevronIcon: Icon(
            CupertinoIcons.chevron_left,
            size: 14,
            color: primary,
          ),
          rightChevronIcon: Icon(
            CupertinoIcons.chevron_right,
            size: 14,
            color: primary,
          ),
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: primary.withAlpha(30),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: primary,
            fontWeight: FontWeight.bold,
          ),
          markerDecoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
          ),
        ),
        eventLoader: (day) {
          return all
              .where((a) => a.isActive && isSameDay(a.dateTime, day))
              .toList();
        },
      ),
    );
  }

  Widget _buildMainContent(
    CalendarViewMode mode,
    DateTime selected,
    List<Appointment> dayAppts,
  ) {
    switch (mode) {
      case CalendarViewMode.day:
        return DayTimelineView(date: selected);
      case CalendarViewMode.week:
        return WeekView(anchorDate: selected);
      case CalendarViewMode.month:
        return dayAppts.isEmpty
            ? const Center(
                child: Text(
                  'Bu güne ait randevu yok.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: dayAppts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) =>
                    _CompactAppointmentCard(appointment: dayAppts[i]),
              );
    }
  }
}

class _CompactAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const _CompactAppointmentCard({required this.appointment});

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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: appointment.isCancelled
                    ? AppColors.textSecondary
                    : color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.customerName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(appointment.dateTime)} – ${appointment.serviceName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
