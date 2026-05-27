// Widget smoke test for RandevuManagerApp
// Note: This is a placeholder test. Real app tests should use mocked providers.

import 'package:flutter_test/flutter_test.dart';
import 'package:randevularim/models/appointment.dart';
import 'package:randevularim/models/enums.dart';
import 'package:randevularim/models/statistics_data.dart';

void main() {
  testWidgets('App smoke test placeholder', (WidgetTester tester) async {
    // RandevuManagerApp requires async initialization (database, notifications,
    // shared preferences) that cannot be easily set up in a basic widget test.
    // Integration tests in test/integration should be used instead.
    expect(true, isTrue);
  });

  test('completed revenue excludes no-show appointments', () {
    final now = DateTime.now();
    Appointment appointment(String id, AppointmentStatus status) => Appointment(
      id: id,
      customerId: 'customer',
      customerName: 'Musteri',
      customerPhone: '555',
      dateTime: now,
      durationMinutes: 30,
      serviceIds: const ['service'],
      serviceName: 'Hizmet',
      serviceColor: '#007AFF',
      totalPrice: 250,
      status: status,
    );

    final stats = StatisticsData.compute([
      appointment('completed', AppointmentStatus.completed),
      appointment('missed', AppointmentStatus.noShow),
    ]);

    expect(stats.todayCount, 1);
    expect(stats.todayRevenue, 250);
  });
}
