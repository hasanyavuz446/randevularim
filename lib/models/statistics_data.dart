import 'appointment.dart';

class CustomerStat {
  final String customerId;
  final String customerName;
  final int count;

  const CustomerStat({
    required this.customerId,
    required this.customerName,
    required this.count,
  });
}

class ServiceStat {
  final String name;
  final String colorHex;
  final int count;
  final double revenue;

  const ServiceStat({
    required this.name,
    required this.colorHex,
    required this.count,
    required this.revenue,
  });
}

class StatisticsData {
  final int todayCount;
  final int thisWeekCount;
  final int thisMonthCount;
  final double todayRevenue;
  final double thisWeekRevenue;
  final double thisMonthRevenue;
  final List<CustomerStat> topCustomers;
  final List<ServiceStat> serviceStats;

  const StatisticsData({
    required this.todayCount,
    required this.thisWeekCount,
    required this.thisMonthCount,
    required this.todayRevenue,
    required this.thisWeekRevenue,
    required this.thisMonthRevenue,
    required this.topCustomers,
    required this.serviceStats,
  });

  factory StatisticsData.empty() => const StatisticsData(
    todayCount: 0,
    thisWeekCount: 0,
    thisMonthCount: 0,
    todayRevenue: 0.0,
    thisWeekRevenue: 0.0,
    thisMonthRevenue: 0.0,
    topCustomers: [],
    serviceStats: [],
  );

  factory StatisticsData.compute(List<Appointment> appointments) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = today.add(const Duration(days: 1));
    final weekday = today.weekday;
    final weekStart = today.subtract(Duration(days: weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final relevant = appointments
        .where((a) => !a.isCancelled && !a.isNoShow)
        .toList();
    final completed = relevant.where((a) => a.isCompleted);

    final todayAppts = relevant.where(
      (a) => !a.dateTime.isBefore(today) && a.dateTime.isBefore(todayEnd),
    );
    final thisWeekAppts = relevant.where(
      (a) => !a.dateTime.isBefore(weekStart) && a.dateTime.isBefore(weekEnd),
    );
    final thisMonthAppts = relevant.where(
      (a) => !a.dateTime.isBefore(monthStart) && a.dateTime.isBefore(monthEnd),
    );

    final todayCount = todayAppts.length;
    final thisWeekCount = thisWeekAppts.length;
    final thisMonthCount = thisMonthAppts.length;

    final todayRevenue = completed
        .where(
          (a) => !a.dateTime.isBefore(today) && a.dateTime.isBefore(todayEnd),
        )
        .fold(0.0, (sum, a) => sum + a.totalPrice);
    final thisWeekRevenue = completed
        .where(
          (a) =>
              !a.dateTime.isBefore(weekStart) && a.dateTime.isBefore(weekEnd),
        )
        .fold(0.0, (sum, a) => sum + a.totalPrice);
    final thisMonthRevenue = completed
        .where(
          (a) =>
              !a.dateTime.isBefore(monthStart) && a.dateTime.isBefore(monthEnd),
        )
        .fold(0.0, (sum, a) => sum + a.totalPrice);

    // Top customers
    final custCounts = <String, int>{};
    final custNames = <String, String>{};
    for (final a in relevant) {
      custCounts[a.customerId] = (custCounts[a.customerId] ?? 0) + 1;
      custNames[a.customerId] = a.customerName;
    }
    final topCustomers =
        custCounts.entries
            .map(
              (e) => CustomerStat(
                customerId: e.key,
                customerName: custNames[e.key]!,
                count: e.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    // Service distribution (bu ay)
    final svcCounts = <String, int>{};
    final svcRevenue = <String, double>{};
    final svcColors = <String, String>{};
    for (final a in thisMonthAppts.where((a) => a.isCompleted)) {
      svcCounts[a.serviceName] = (svcCounts[a.serviceName] ?? 0) + 1;
      svcRevenue[a.serviceName] =
          (svcRevenue[a.serviceName] ?? 0) + a.totalPrice;
      svcColors[a.serviceName] = a.serviceColor;
    }
    final serviceStats =
        svcCounts.entries
            .map(
              (e) => ServiceStat(
                name: e.key,
                colorHex: svcColors[e.key]!,
                count: e.value,
                revenue: svcRevenue[e.key]!,
              ),
            )
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    return StatisticsData(
      todayCount: todayCount,
      thisWeekCount: thisWeekCount,
      thisMonthCount: thisMonthCount,
      todayRevenue: todayRevenue,
      thisWeekRevenue: thisWeekRevenue,
      thisMonthRevenue: thisMonthRevenue,
      topCustomers: topCustomers.take(5).toList(),
      serviceStats: serviceStats,
    );
  }
}
