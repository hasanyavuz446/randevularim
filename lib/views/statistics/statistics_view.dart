import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/enums.dart' show StatsPeriod;
import '../../models/statistics_data.dart';
import '../../providers/providers.dart';

class StatisticsView extends ConsumerStatefulWidget {
  const StatisticsView({super.key});

  @override
  ConsumerState<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends ConsumerState<StatisticsView> {
  StatsPeriod _period = StatsPeriod.today;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statisticsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('İstatistikler'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PeriodSelector(
            selected: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 16),
          _StatsCards(stats: stats, period: _period),
          const SizedBox(height: 24),
          if (stats.topCustomers.isNotEmpty) ...[
            _SectionHeader(title: 'En Çok Gelen Müşteriler'),
            const SizedBox(height: 8),
            _TopCustomersList(customers: stats.topCustomers),
            const SizedBox(height: 24),
          ],
          if (stats.serviceStats.isNotEmpty) ...[
            _SectionHeader(title: 'Bu Ay Hizmet Dağılımı'),
            const SizedBox(height: 8),
            _ServiceDistribution(stats: stats.serviceStats),
          ],
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final StatsPeriod selected;
  final ValueChanged<StatsPeriod> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: StatsPeriod.values.map((p) {
          final isSelected = p == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatsCards extends StatelessWidget {
  final StatisticsData stats;
  final StatsPeriod period;

  const _StatsCards({required this.stats, required this.period});

  @override
  Widget build(BuildContext context) {
    final count = switch (period) {
      StatsPeriod.today => stats.todayCount,
      StatsPeriod.week => stats.thisWeekCount,
      StatsPeriod.month => stats.thisMonthCount,
    };

    final revenue = switch (period) {
      StatsPeriod.today => stats.todayRevenue,
      StatsPeriod.week => stats.thisWeekRevenue,
      StatsPeriod.month => stats.thisMonthRevenue,
    };

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Randevu',
            value: '$count',
            icon: Icons.calendar_today,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Ciro',
            value: '${revenue.toStringAsFixed(0)} TL',
            icon: Icons.account_balance_wallet,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
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
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _TopCustomersList extends StatelessWidget {
  final List<CustomerStat> customers;

  const _TopCustomersList({required this.customers});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: customers.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          final isLast = i == customers.length - 1;
          final primary = Theme.of(context).colorScheme.primary;
          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: primary.withAlpha(20),
                  child: Text('${i + 1}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primary)),
                ),
                title: Text(c.customerName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                trailing: Text('${c.count} randevu',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ),
              if (!isLast) const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ServiceDistribution extends StatelessWidget {
  final List<ServiceStat> stats;

  const _ServiceDistribution({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: stats.map((s) {
          final color = AppColors.fromHex(s.colorHex);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(s.name,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500))),
                    Text('${s.count} adet',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const SizedBox(width: 20),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: s.count /
                              stats.fold(0, (sum, item) => sum + item.count),
                          backgroundColor: color.withAlpha(30),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
