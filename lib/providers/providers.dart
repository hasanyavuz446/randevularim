import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment.dart';
import '../models/app_settings.dart';
import '../models/customer.dart';
import '../models/business.dart';
import '../models/enums.dart';
import '../models/service.dart';
import '../models/statistics_data.dart';
import '../services/database_service.dart';
import '../services/conflict_service.dart';
import '../services/notification_service.dart';
import '../services/onboarding_service.dart';
import '../services/backup_service.dart';
import '../services/settings_service.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/service_repository.dart';
import '../repositories/business_repository.dart';
import 'appointments_notifier.dart';
import 'customers_notifier.dart';
import 'services_notifier.dart';
import 'business_notifier.dart';
import 'settings_notifier.dart';

// ── Bootstrap (main'de override edilir) ─────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

// ── Services ─────────────────────────────────────────────────────────────────

final databaseServiceProvider = Provider<DatabaseService>(
  (_) => DatabaseService.instance,
);

final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService.instance,
);

final settingsServiceProvider = Provider<SettingsService>(
  (ref) => SettingsService(ref.read(sharedPreferencesProvider)),
);

final onboardingServiceProvider = Provider<OnboardingService>(
  (ref) => OnboardingService(ref.read(sharedPreferencesProvider)),
);

final backupServiceProvider = FutureProvider<BackupService>((ref) async {
  final database = await ref.read(databaseServiceProvider).database;
  return BackupService(database, ref.read(sharedPreferencesProvider));
});

// ── Settings ──────────────────────────────────────────────────────────────────

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
      (ref) => SettingsNotifier(ref.read(settingsServiceProvider)),
    );

// ── Repositories ──────────────────────────────────────────────────────────────

final appointmentRepositoryProvider = Provider<AppointmentRepository>(
  (ref) => AppointmentRepository(ref.read(databaseServiceProvider)),
);

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => CustomerRepository(ref.read(databaseServiceProvider)),
);

final serviceRepositoryProvider = Provider<ServiceRepository>(
  (ref) => ServiceRepository(ref.read(databaseServiceProvider)),
);

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => BusinessRepository(ref.read(databaseServiceProvider)),
);

final conflictServiceProvider = Provider<ConflictService>(
  (ref) => ConflictService(ref.read(appointmentRepositoryProvider)),
);

// ── Business (işletme) ────────────────────────────────────────────────────────

final businessNotifierProvider =
    StateNotifierProvider<BusinessNotifier, AsyncValue<Business>>(
      (ref) => BusinessNotifier(ref.read(businessRepositoryProvider)),
    );

// ── Services (hizmetler) ─────────────────────────────────────────────────────

final servicesNotifierProvider =
    StateNotifierProvider<ServicesNotifier, AsyncValue<List<Service>>>(
      (ref) => ServicesNotifier(ref.read(serviceRepositoryProvider)),
    );

// ── Appointments ──────────────────────────────────────────────────────────────

final appointmentsNotifierProvider =
    StateNotifierProvider<AppointmentsNotifier, AsyncValue<List<Appointment>>>(
      (ref) => AppointmentsNotifier(
        ref.read(appointmentRepositoryProvider),
        ref.read(notificationServiceProvider),
      ),
    );

final selectedDateProvider = StateProvider<DateTime>((_) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final calendarViewModeProvider = StateProvider<CalendarViewMode>(
  (_) => CalendarViewMode.day,
);

final appointmentsForDateProvider =
    Provider.family<List<Appointment>, DateTime>((ref, date) {
      final async = ref.watch(appointmentsNotifierProvider);
      return async.when(
        data: (list) =>
            list
                .where((a) => !a.isCancelled && _sameDay(a.dateTime, date))
                .toList()
              ..sort((a, b) => a.dateTime.compareTo(b.dateTime)),
        loading: () => [],
        error: (_, _) => [],
      );
    });

final appointmentSearchProvider = StateProvider<String>((_) => '');

enum AppointmentFilter { upcoming, archive }

final appointmentFilterProvider = StateProvider<AppointmentFilter>(
  (_) => AppointmentFilter.upcoming,
);

final todayAppointmentsProvider = Provider<List<Appointment>>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return ref.watch(appointmentsForDateProvider(today));
});

// ── Customers ─────────────────────────────────────────────────────────────────

final customersNotifierProvider =
    StateNotifierProvider<CustomersNotifier, AsyncValue<List<Customer>>>(
      (ref) => CustomersNotifier(
        ref.read(customerRepositoryProvider),
        ref.read(appointmentRepositoryProvider),
        ref.read(appointmentsNotifierProvider.notifier),
      ),
    );

final customerSearchProvider = StateProvider<String>((_) => '');

final filteredCustomersProvider = Provider<List<Customer>>((ref) {
  final query = ref.watch(customerSearchProvider).toLowerCase().trim();
  final async = ref.watch(customersNotifierProvider);
  return async.when(
    data: (list) {
      if (query.isEmpty) return list;
      return list
          .where(
            (c) =>
                c.name.toLowerCase().contains(query) || c.phone.contains(query),
          )
          .toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

// ── Statistics ────────────────────────────────────────────────────────────────

final statisticsProvider = Provider<StatisticsData>((ref) {
  final async = ref.watch(appointmentsNotifierProvider);
  return async.when(
    data: StatisticsData.compute,
    loading: StatisticsData.empty,
    error: (_, _) => StatisticsData.empty(),
  );
});

// ── Helpers ───────────────────────────────────────────────────────────────────

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
