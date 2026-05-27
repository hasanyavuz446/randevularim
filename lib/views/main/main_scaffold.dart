import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../home/home_view.dart';
import '../calendar/calendar_view.dart';
import '../customers/customer_list_view.dart';
import '../statistics/statistics_view.dart';
import '../appointments/appointment_list_view.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  void _selectTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeView(
        onShowAppointments: () => _selectTab(2),
        onShowReports: () => _selectTab(4),
      ),
      const CalendarView(),
      const AppointmentListView(),
      const CustomerListView(),
      const StatisticsView(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _selectTab,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house),
              activeIcon: Icon(CupertinoIcons.house_fill),
              label: 'Bugün',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.calendar),
              activeIcon: Icon(CupertinoIcons.calendar_today),
              label: 'Takvim',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.list_bullet),
              activeIcon: Icon(CupertinoIcons.list_bullet_indent),
              label: 'Randevular',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person_2),
              activeIcon: Icon(CupertinoIcons.person_2_fill),
              label: 'Müşteriler',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chart_bar),
              activeIcon: Icon(CupertinoIcons.chart_bar_fill),
              label: 'Raporlar',
            ),
          ],
        ),
      ),
    );
  }
}
