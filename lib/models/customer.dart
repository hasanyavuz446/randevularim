import 'package:uuid/uuid.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String serviceNotes;
  final String generalNotes;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.serviceNotes = '',
    this.generalNotes = '',
    required this.createdAt,
  });

  factory Customer.create({
    required String name,
    required String phone,
    String serviceNotes = '',
    String generalNotes = '',
  }) {
    return Customer(
      id: const Uuid().v4(),
      name: name,
      phone: phone,
      serviceNotes: serviceNotes,
      generalNotes: generalNotes,
      createdAt: DateTime.now(),
    );
  }

  Customer copyWith({
    String? name,
    String? phone,
    String? serviceNotes,
    String? generalNotes,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      serviceNotes: serviceNotes ?? this.serviceNotes,
      generalNotes: generalNotes ?? this.generalNotes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'service_notes': serviceNotes,
      'general_notes': generalNotes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      serviceNotes: map['service_notes'] as String? ?? '',
      generalNotes: map['general_notes'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  bool operator ==(Object other) => other is Customer && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
