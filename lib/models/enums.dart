enum AppointmentStatus {
  scheduled('Planlandı'),
  confirmed('Teyit Edildi'),
  completed('Tamamlandı'),
  cancelled('İptal Edildi'),
  noShow('Gelmedi');

  final String label;
  const AppointmentStatus(this.label);

  static AppointmentStatus fromString(String value) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppointmentStatus.scheduled,
    );
  }
}

enum CalendarViewMode { month, week, day }

enum StatsPeriod {
  today('Bugün'),
  week('Bu Hafta'),
  month('Bu Ay');

  final String label;
  const StatsPeriod(this.label);
}
