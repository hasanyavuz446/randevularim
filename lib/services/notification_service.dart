import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/appointment.dart';
import '../models/app_settings.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) return true;
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (_) {}

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    try {
      await _plugin.initialize(settings);
      _initialized = true;
    } catch (_) {
      return false;
    }
    return true;
  }

  Future<void> requestPermission() async {
    if (!await initialize()) return;
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    try {
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
      await macos?.requestPermissions(alert: true, badge: true, sound: true);
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } catch (_) {
      // Bildirim izni uygulamanin temel akisini engellememelidir.
    }
  }

  Future<void> scheduleForAppointment(
    Appointment appointment,
    AppSettings settings,
  ) async {
    if (!await initialize()) return;
    if (!settings.globalNotificationsEnabled ||
        !appointment.notificationsEnabled) {
      await cancelForAppointment(appointment.id);
      return;
    }

    final name = appointment.customerName;
    final service = appointment.serviceName;

    try {
      if (appointment.startNotificationEnabled) {
        await _scheduleSingle(
          id: _idFrom(appointment.id, 0),
          title: 'Randevu Başlıyor',
          body: '$name - $service randevusu başlıyor.',
          scheduledDate: appointment.dateTime,
        );
      }

      if (appointment.reminderMinutes > 0) {
        await _scheduleSingle(
          id: _idFrom(appointment.id, 1),
          title: 'Randevu Yaklaşıyor',
          body:
              '$name - $service randevusuna ${_leadTimeLabel(appointment.reminderMinutes)} kaldı.',
          scheduledDate: appointment.dateTime.subtract(
            Duration(minutes: appointment.reminderMinutes),
          ),
        );
      }
    } catch (_) {
      // Randevu kaydi, notification plugin hatasi nedeniyle basarisiz olmamali.
    }
  }

  Future<void> cancelForAppointment(String appointmentId) async {
    if (!await initialize()) return;
    try {
      await _plugin.cancel(_idFrom(appointmentId, 0));
      await _plugin.cancel(_idFrom(appointmentId, 1));
      // Legacy one-day reminder id from older builds.
      await _plugin.cancel(_idFrom(appointmentId, 2));
    } catch (_) {
      // Notification iptali ana veri islemini engellememelidir.
    }
  }

  Future<void> _scheduleSingle({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'randevu_kanal',
      'Randevu Bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  int _idFrom(String appointmentId, int suffix) {
    return appointmentId.hashCode.abs() % 100000 * 10 + suffix;
  }

  String _leadTimeLabel(int minutes) {
    if (minutes < 60) return '$minutes dakika';
    if (minutes == 1440) return '1 gün';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours saat';
    return '$hours saat $remainingMinutes dakika';
  }
}
