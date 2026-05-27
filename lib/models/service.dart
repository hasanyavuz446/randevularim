import 'dart:ui' show Color;
import 'package:uuid/uuid.dart';

class Service {
  final String id;
  final String name;
  final int durationMinutes;
  final String colorHex;
  final int sortOrder;
  final double price;
  final String description;
  final bool isActive;

  const Service({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.colorHex,
    required this.sortOrder,
    this.price = 0.0,
    this.description = '',
    this.isActive = true,
  });

  Color get color {
    final h = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  factory Service.create({
    required String name,
    required int durationMinutes,
    required String colorHex,
    required int sortOrder,
    double price = 0.0,
    String description = '',
  }) {
    return Service(
      id: const Uuid().v4(),
      name: name,
      durationMinutes: durationMinutes,
      colorHex: colorHex,
      sortOrder: sortOrder,
      price: price,
      description: description,
    );
  }

  Service copyWith({
    String? name,
    int? durationMinutes,
    String? colorHex,
    int? sortOrder,
    double? price,
    String? description,
    bool? isActive,
  }) {
    return Service(
      id: id,
      name: name ?? this.name,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      price: price ?? this.price,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'duration_minutes': durationMinutes,
    'default_duration_minutes': durationMinutes,
    'color_hex': colorHex,
    'sort_order': sortOrder,
    'price': price,
    'description': description,
    'is_active': isActive ? 1 : 0,
  };

  factory Service.fromMap(Map<String, dynamic> map) => Service(
    id: map['id'] as String,
    name: map['name'] as String,
    durationMinutes:
        map['duration_minutes'] as int? ??
        map['default_duration_minutes'] as int? ??
        30,
    colorHex: map['color_hex'] as String,
    sortOrder: map['sort_order'] as int,
    price: (map['price'] as num?)?.toDouble() ?? 0.0,
    description: map['description'] as String? ?? '',
    isActive: (map['is_active'] as int? ?? 1) == 1,
  );

  static List<Service> get defaults => const [
    Service(
      id: 'svc_genel',
      name: 'Genel Randevu',
      durationMinutes: 30,
      colorHex: '#5856D6',
      sortOrder: 0,
      price: 100.0,
    ),
    Service(
      id: 'svc_danisman',
      name: 'Danışmanlık',
      durationMinutes: 45,
      colorHex: '#007AFF',
      sortOrder: 1,
      price: 200.0,
    ),
    Service(
      id: 'svc_muayene',
      name: 'Muayene',
      durationMinutes: 20,
      colorHex: '#30D158',
      sortOrder: 2,
      price: 150.0,
    ),
    Service(
      id: 'svc_egitim',
      name: 'Eğitim / Ders',
      durationMinutes: 60,
      colorHex: '#FF2D55',
      sortOrder: 3,
      price: 120.0,
    ),
    Service(
      id: 'svc_bakim',
      name: 'Bakım / Uygulama',
      durationMinutes: 90,
      colorHex: '#FF9F0A',
      sortOrder: 4,
      price: 300.0,
    ),
    Service(
      id: 'svc_diger',
      name: 'Diğer',
      durationMinutes: 30,
      colorHex: '#8E8E93',
      sortOrder: 5,
      price: 0.0,
    ),
  ];

  static Service fromLegacyType(String typeName) {
    const map = {
      'haircut': Service(
        id: 'svc_genel',
        name: 'Genel Randevu',
        durationMinutes: 30,
        colorHex: '#5856D6',
        sortOrder: 0,
      ),
      'beard': Service(
        id: 'svc_danisman',
        name: 'Danışmanlık',
        durationMinutes: 45,
        colorHex: '#007AFF',
        sortOrder: 1,
      ),
      'hairAndBeard': Service(
        id: 'svc_muayene',
        name: 'Muayene',
        durationMinutes: 20,
        colorHex: '#30D158',
        sortOrder: 2,
      ),
      'dyeing': Service(
        id: 'svc_egitim',
        name: 'Eğitim / Ders',
        durationMinutes: 60,
        colorHex: '#FF2D55',
        sortOrder: 3,
      ),
      'keratin': Service(
        id: 'svc_bakim',
        name: 'Bakım / Uygulama',
        durationMinutes: 90,
        colorHex: '#FF9F0A',
        sortOrder: 4,
      ),
      'treatment': Service(
        id: 'svc_diger',
        name: 'Diğer',
        durationMinutes: 30,
        colorHex: '#8E8E93',
        sortOrder: 5,
      ),
    };
    return map[typeName] ?? defaults.first;
  }

  @override
  bool operator ==(Object other) => other is Service && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
