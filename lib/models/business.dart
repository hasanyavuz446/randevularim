import 'package:uuid/uuid.dart';

class Business {
  final String id;
  final String name;
  final String category;
  final String phone;
  final String address;
  final String logoUrl;
  final List<int> workingDays; // 1 = Monday, 7 = Sunday
  final String openingTime; // HH:mm
  final String closingTime; // HH:mm
  final int appointmentIntervalMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Business({
    required this.id,
    required this.name,
    this.category = 'Genel',
    this.phone = '',
    this.address = '',
    this.logoUrl = '',
    this.workingDays = const [1, 2, 3, 4, 5, 6],
    this.openingTime = '09:00',
    this.closingTime = '19:00',
    this.appointmentIntervalMinutes = 30,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.createDefault() {
    final now = DateTime.now();
    return Business(
      id: const Uuid().v4(),
      name: 'İşletmem',
      createdAt: now,
      updatedAt: now,
    );
  }

  Business copyWith({
    String? name,
    String? category,
    String? phone,
    String? address,
    String? logoUrl,
    List<int>? workingDays,
    String? openingTime,
    String? closingTime,
    int? appointmentIntervalMinutes,
    DateTime? updatedAt,
  }) {
    return Business(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      logoUrl: logoUrl ?? this.logoUrl,
      workingDays: workingDays ?? this.workingDays,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      appointmentIntervalMinutes: appointmentIntervalMinutes ?? this.appointmentIntervalMinutes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'phone': phone,
        'address': address,
        'logo_url': logoUrl,
        'working_days': workingDays.join(','),
        'opening_time': openingTime,
        'closing_time': closingTime,
        'appointment_interval': appointmentIntervalMinutes,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Business.fromMap(Map<String, dynamic> map) => Business(
        id: map['id'] as String,
        name: map['name'] as String,
        category: map['category'] as String? ?? 'Genel',
        phone: map['phone'] as String? ?? '',
        address: map['address'] as String? ?? '',
        logoUrl: map['logo_url'] as String? ?? '',
        workingDays: (map['working_days'] as String? ?? '1,2,3,4,5,6')
            .split(',')
            .where((s) => s.isNotEmpty)
            .map(int.parse)
            .toList(),
        openingTime: map['opening_time'] as String? ?? '09:00',
        closingTime: map['closing_time'] as String? ?? '19:00',
        appointmentIntervalMinutes: map['appointment_interval'] as int? ?? 30,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
}
