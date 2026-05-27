import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'enums.dart';

class Appointment {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final DateTime dateTime;
  final int durationMinutes;
  final List<String> serviceIds;
  final String serviceName;
  final String serviceColor; // hex string, örn: '#5856D6'
  final String notes;
  final AppointmentStatus status;
  final double totalPrice;
  final String staffId;
  final bool notificationsEnabled;
  final int reminderMinutes;
  final bool startNotificationEnabled;

  const Appointment({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.dateTime,
    required this.durationMinutes,
    required this.serviceIds,
    required this.serviceName,
    required this.serviceColor,
    this.notes = '',
    this.status = AppointmentStatus.scheduled,
    this.totalPrice = 0.0,
    this.staffId = '',
    this.notificationsEnabled = true,
    this.reminderMinutes = 30,
    this.startNotificationEnabled = true,
  });

  factory Appointment.create({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required DateTime dateTime,
    required int durationMinutes,
    required List<String> serviceIds,
    required String serviceName,
    required String serviceColor,
    String notes = '',
    double totalPrice = 0.0,
    String staffId = '',
    bool notificationsEnabled = true,
    int reminderMinutes = 30,
    bool startNotificationEnabled = true,
  }) {
    return Appointment(
      id: const Uuid().v4(),
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      dateTime: dateTime,
      durationMinutes: durationMinutes,
      serviceIds: serviceIds,
      serviceName: serviceName,
      serviceColor: serviceColor,
      notes: notes,
      totalPrice: totalPrice,
      staffId: staffId,
      notificationsEnabled: notificationsEnabled,
      reminderMinutes: reminderMinutes,
      startNotificationEnabled: startNotificationEnabled,
    );
  }

  DateTime get endTime => dateTime.add(Duration(minutes: durationMinutes));
  bool get isScheduled => status == AppointmentStatus.scheduled;
  bool get isConfirmed => status == AppointmentStatus.confirmed;
  bool get isActive => isScheduled || isConfirmed;
  bool get isCompleted => status == AppointmentStatus.completed;
  bool get isCancelled => status == AppointmentStatus.cancelled;
  bool get isNoShow => status == AppointmentStatus.noShow;

  bool overlapsWith(DateTime otherStart, int otherDurationMinutes) {
    final otherEnd = otherStart.add(Duration(minutes: otherDurationMinutes));
    return dateTime.isBefore(otherEnd) && endTime.isAfter(otherStart);
  }

  Appointment copyWith({
    String? customerId,
    String? customerName,
    String? customerPhone,
    DateTime? dateTime,
    int? durationMinutes,
    List<String>? serviceIds,
    String? serviceName,
    String? serviceColor,
    String? notes,
    AppointmentStatus? status,
    double? totalPrice,
    String? staffId,
    bool? notificationsEnabled,
    int? reminderMinutes,
    bool? startNotificationEnabled,
  }) {
    return Appointment(
      id: id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      serviceIds: serviceIds ?? this.serviceIds,
      serviceName: serviceName ?? this.serviceName,
      serviceColor: serviceColor ?? this.serviceColor,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      staffId: staffId ?? this.staffId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      startNotificationEnabled:
          startNotificationEnabled ?? this.startNotificationEnabled,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'customer_id': customerId,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'date_time': dateTime.millisecondsSinceEpoch,
    'duration_minutes': durationMinutes,
    'service_id': jsonEncode(serviceIds),
    'service_name': serviceName,
    'service_color': serviceColor,
    'notes': notes,
    'status': status.name,
    'total_price': totalPrice,
    'staff_id': staffId,
    'notifications_enabled': notificationsEnabled ? 1 : 0,
    'reminder_minutes': reminderMinutes,
    'start_notification_enabled': startNotificationEnabled ? 1 : 0,
  };

  factory Appointment.fromMap(Map<String, dynamic> map) {
    final rawServiceId = map['service_id'] as String?;
    List<String> serviceIds;

    if (rawServiceId != null && rawServiceId.startsWith('[')) {
      try {
        serviceIds = List<String>.from(jsonDecode(rawServiceId));
      } catch (_) {
        serviceIds = [rawServiceId];
      }
    } else {
      serviceIds = [rawServiceId ?? 'svc_genel'];
    }

    final serviceName = map['service_name'] as String? ?? 'Genel Randevu';
    final serviceColor = map['service_color'] as String? ?? '#5856D6';

    return Appointment(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String,
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['date_time'] as int),
      durationMinutes: map['duration_minutes'] as int,
      serviceIds: serviceIds,
      serviceName: serviceName,
      serviceColor: serviceColor,
      notes: map['notes'] as String? ?? '',
      status: AppointmentStatus.fromString(
        map['status'] as String? ?? 'scheduled',
      ),
      totalPrice: (map['total_price'] as num?)?.toDouble() ?? 0.0,
      staffId: map['staff_id'] as String? ?? '',
      notificationsEnabled: (map['notifications_enabled'] as int? ?? 1) == 1,
      reminderMinutes: map['reminder_minutes'] as int? ?? 30,
      startNotificationEnabled:
          (map['start_notification_enabled'] as int? ?? 1) == 1,
    );
  }

  @override
  bool operator ==(Object other) => other is Appointment && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
