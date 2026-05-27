import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/appointment.dart';
import '../../models/customer.dart';
import '../../models/service.dart';
import '../../providers/providers.dart';

class AppointmentFormView extends ConsumerStatefulWidget {
  final Appointment? appointment;
  final DateTime? initialDate;
  final Customer? initialCustomer;

  const AppointmentFormView({
    super.key,
    this.appointment,
    this.initialDate,
    this.initialCustomer,
  });

  @override
  ConsumerState<AppointmentFormView> createState() =>
      _AppointmentFormViewState();
}

class _AppointmentFormViewState extends ConsumerState<AppointmentFormView> {
  Customer? _selectedCustomer;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  List<Service> _selectedServices = [];
  late int _durationMinutes;
  late double _totalPrice;
  bool _notificationsEnabled = true;
  int _reminderMinutes = 30;
  bool _startNotificationEnabled = true;
  bool _createAnother = false;
  int _weeklyOccurrences = 1;
  final _notesController = TextEditingController();
  final _customerSearchController = TextEditingController();
  late final TextEditingController _totalPriceCtrl;
  bool _servicesInitialized = false;

  List<Appointment> _conflicts = [];

  @override
  void initState() {
    super.initState();
    final appt = widget.appointment;
    _selectedCustomer = widget.initialCustomer;
    if (appt != null) {
      _selectedDate = DateTime(
        appt.dateTime.year,
        appt.dateTime.month,
        appt.dateTime.day,
      );
      _selectedTime = TimeOfDay(
        hour: appt.dateTime.hour,
        minute: appt.dateTime.minute,
      );
      _durationMinutes = appt.durationMinutes;
      _totalPrice = appt.totalPrice;
      _notificationsEnabled = appt.notificationsEnabled;
      _reminderMinutes = appt.reminderMinutes;
      _startNotificationEnabled = appt.startNotificationEnabled;
      _notesController.text = appt.notes;
      // Hizmetleri ilk frame'den sonra yükle (providers henüz hazır olmayabilir)
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _initServicesForEditing(),
      );
    } else {
      final now = widget.initialDate ?? DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = TimeOfDay.now();
      _durationMinutes = 0;
      _totalPrice = 0.0;
      _reminderMinutes = ref.read(settingsNotifierProvider).reminderMinutes;
    }
    _totalPriceCtrl = TextEditingController(
      text: _totalPrice.toStringAsFixed(2),
    );
  }

  void _initServicesForEditing() {
    if (!mounted || _servicesInitialized) return;
    final services = ref.read(servicesNotifierProvider).value;
    if (services == null || services.isEmpty) return;

    final appt = widget.appointment!;
    final selected = services
        .where((s) => appt.serviceIds.contains(s.id))
        .toList();
    setState(() {
      _selectedServices = selected;
      _servicesInitialized = true;
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _customerSearchController.dispose();
    _totalPriceCtrl.dispose();
    super.dispose();
  }

  DateTime get _fullDateTime => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  Future<void> _checkConflicts() async {
    if (_durationMinutes <= 0) return;
    final conflicts = await ref
        .read(conflictServiceProvider)
        .findConflicts(
          _fullDateTime,
          _durationMinutes,
          excludeId: widget.appointment?.id,
        );
    if (mounted) setState(() => _conflicts = conflicts);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'tr_TR'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _checkConflicts();
    }
  }

  Future<void> _pickTime() async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            Container(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('İptal'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Tamam'),
                    onPressed: () {
                      Navigator.pop(context);
                      _checkConflicts();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  _selectedTime.hour,
                  _selectedTime.minute,
                ),
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() {
                    _selectedTime = TimeOfDay(
                      hour: newDateTime.hour,
                      minute: newDateTime.minute,
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _calculateDurationAndPrice() {
    int totalDur = 0;
    double totalP = 0.0;
    for (final s in _selectedServices) {
      totalDur += s.durationMinutes;
      totalP += s.price;
    }
    setState(() {
      _durationMinutes = totalDur;
      _totalPrice = totalP;
      _totalPriceCtrl.text = totalP.toStringAsFixed(2);
    });
    _checkConflicts();
  }

  Future<void> _save() async {
    final settings = ref.read(settingsNotifierProvider);
    final isEditing = widget.appointment != null;

    if (!isEditing && _selectedCustomer == null) {
      _showError('Lütfen bir müşteri seçin.');
      return;
    }
    if (_selectedServices.isEmpty) {
      _showError('Lütfen en az bir hizmet seçin.');
      return;
    }

    final biz = ref.read(businessNotifierProvider).value;
    if (biz != null && mounted) {
      bool isClosed = !biz.workingDays.contains(_selectedDate.weekday);

      final startTime = _selectedTime.hour * 60 + _selectedTime.minute;
      final openParts = biz.openingTime.split(':').map(int.parse).toList();
      final openTime = openParts[0] * 60 + openParts[1];
      final closeParts = biz.closingTime.split(':').map(int.parse).toList();
      final closeTime = closeParts[0] * 60 + closeParts[1];
      bool isOutsideHours =
          startTime < openTime || (startTime + _durationMinutes) > closeTime;

      if (isClosed || isOutsideHours) {
        final reason = isClosed
            ? 'İşletme bugün kapalı.'
            : 'Randevu çalışma saatleri dışında.';
        final proceed = await showCupertinoDialog<bool>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Çalışma Saatleri Dışı'),
            content: Text('$reason Yine de devam etmek istiyor musunuz?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Vazgeç'),
                onPressed: () => Navigator.pop(ctx, false),
              ),
              CupertinoDialogAction(
                child: const Text('Devam Et'),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    await _checkConflicts();
    if (!isEditing && _weeklyOccurrences > 1) {
      final seriesConflicts = <Appointment>[..._conflicts];
      for (var i = 1; i < _weeklyOccurrences; i++) {
        final conflicts = await ref
            .read(conflictServiceProvider)
            .findConflicts(
              _fullDateTime.add(Duration(days: i * 7)),
              _durationMinutes,
            );
        seriesConflicts.addAll(conflicts);
      }
      if (mounted) {
        setState(
          () => _conflicts = {
            for (final conflict in seriesConflicts) conflict.id: conflict,
          }.values.toList(),
        );
      }
    }

    if (_conflicts.isNotEmpty && mounted) {
      final proceed = await _showConflictDialog();
      if (!proceed) return;
    }

    final notifier = ref.read(appointmentsNotifierProvider.notifier);
    final serviceIds = _selectedServices.map((s) => s.id).toList();
    final serviceNames = _selectedServices.map((s) => s.name).join(', ');
    final serviceColor = _selectedServices.first.colorHex;

    if (isEditing) {
      final updated = widget.appointment!.copyWith(
        dateTime: _fullDateTime,
        durationMinutes: _durationMinutes,
        serviceIds: serviceIds,
        serviceName: serviceNames,
        serviceColor: serviceColor,
        notes: _notesController.text.trim(),
        totalPrice: _totalPrice,
        notificationsEnabled: _notificationsEnabled,
        reminderMinutes: _reminderMinutes,
        startNotificationEnabled: _startNotificationEnabled,
      );
      await notifier.updateAppointment(updated, settings);
    } else {
      final series = List.generate(
        _weeklyOccurrences,
        (index) => Appointment.create(
          customerId: _selectedCustomer!.id,
          customerName: _selectedCustomer!.name,
          customerPhone: _selectedCustomer!.phone,
          dateTime: _fullDateTime.add(Duration(days: index * 7)),
          durationMinutes: _durationMinutes,
          serviceIds: serviceIds,
          serviceName: serviceNames,
          serviceColor: serviceColor,
          notes: _notesController.text.trim(),
          totalPrice: _totalPrice,
          notificationsEnabled: _notificationsEnabled,
          reminderMinutes: _reminderMinutes,
          startNotificationEnabled: _startNotificationEnabled,
        ),
      );
      if (series.length == 1) {
        await notifier.addAppointment(series.first, settings);
      } else {
        await notifier.addAppointments(series, settings);
      }
    }

    if (!mounted) return;
    if (!isEditing && _createAnother) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (_) => AppointmentFormView(
            initialDate: _selectedDate,
            initialCustomer: _selectedCustomer,
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  Future<bool> _showConflictDialog() async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Çakışan Randevu'),
        content: Text(
          'Bu saatte ${_conflicts.length} çakışan randevu var. Yine de kaydetmek istiyor musunuz?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yine de Kaydet'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.appointment != null;
    final services =
        ref
            .watch(servicesNotifierProvider)
            .value
            ?.where((s) => s.isActive)
            .toList() ??
        [];
    final surface = Theme.of(context).colorScheme.surface;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(isEditing ? 'Randevu Düzenle' : 'Yeni Randevu'),
        backgroundColor: surface,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Kaydet',
              style: TextStyle(color: primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!isEditing) ...[
            _SectionLabel(label: 'Müşteri'),
            _CustomerSelector(
              selected: _selectedCustomer,
              searchController: _customerSearchController,
              onSelected: (c) => setState(() => _selectedCustomer = c),
            ),
            const SizedBox(height: 16),
          ],

          _SectionLabel(label: 'Tarih ve Saat'),
          Row(
            children: [
              Expanded(
                child: _PickerTile(
                  icon: CupertinoIcons.calendar,
                  label: DateFormat(
                    'd MMMM yyyy',
                    'tr_TR',
                  ).format(_selectedDate),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PickerTile(
                  icon: CupertinoIcons.clock,
                  label:
                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                  onTap: _pickTime,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          if (!isEditing) ...[
            _SectionLabel(label: 'Tekrar'),
            DropdownButtonFormField<int>(
              initialValue: _weeklyOccurrences,
              decoration: const InputDecoration(
                prefixIcon: Icon(CupertinoIcons.repeat, size: 18),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Tek randevu')),
                DropdownMenuItem(
                  value: 4,
                  child: Text('4 hafta boyunca tekrarla'),
                ),
                DropdownMenuItem(
                  value: 8,
                  child: Text('8 hafta boyunca tekrarla'),
                ),
                DropdownMenuItem(
                  value: 12,
                  child: Text('12 hafta boyunca tekrarla'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _weeklyOccurrences = value ?? 1),
            ),
            const SizedBox(height: 16),
          ],

          _SectionLabel(label: 'Hizmetler'),
          if (services.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Henüz hizmet yok. Ayarlar → Hizmet Yönetimi.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            _ServicePicker(
              services: services,
              selected: _selectedServices,
              onToggle: (s) {
                setState(() {
                  if (_selectedServices.any((item) => item.id == s.id)) {
                    _selectedServices.removeWhere((item) => item.id == s.id);
                  } else {
                    _selectedServices.add(s);
                  }
                  _calculateDurationAndPrice();
                });
              },
            ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionLabel(label: 'Toplam Süre'),
              Text(
                _durationLabel(_durationMinutes),
                style: TextStyle(fontWeight: FontWeight.bold, color: primary),
              ),
            ],
          ),
          _DurationPicker(
            value: _durationMinutes,
            onChanged: (v) {
              setState(() => _durationMinutes = v);
              _checkConflicts();
            },
          ),

          const SizedBox(height: 16),

          _SectionLabel(label: 'Toplam Ücret'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.money_dollar_circle,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration.collapsed(
                      hintText: '0.00',
                    ),
                    controller: _totalPriceCtrl,
                    onChanged: (v) => _totalPrice = double.tryParse(v) ?? 0.0,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Text('TL', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          if (_conflicts.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ConflictWarning(conflicts: _conflicts),
          ],

          const SizedBox(height: 16),

          _SectionLabel(label: 'Bildirimler'),
          SwitchListTile.adaptive(
            title: const Text(
              'Bildirimler',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Bu randevu için hatırlatma ve başlangıç bildirimi gönderilsin.',
              style: TextStyle(fontSize: 12),
            ),
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_notificationsEnabled) ...[
            SwitchListTile.adaptive(
              title: const Text(
                'Başlangıç Bildirimi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Randevu saatinde "randevu başlıyor" bildirimi gönder.',
                style: TextStyle(fontSize: 12),
              ),
              value: _startNotificationEnabled,
              onChanged: (v) => setState(() => _startNotificationEnabled = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            _SectionLabel(label: 'Önceden Hatırlat'),
            _ReminderPicker(
              value: _reminderMinutes,
              onChanged: (value) => setState(() => _reminderMinutes = value),
            ),
          ],
          if (!isEditing)
            SwitchListTile.adaptive(
              title: const Text(
                'Ardından yeni randevu ekle',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Aynı müşteri için art arda randevu oluşturmayı hızlandırır.',
                style: TextStyle(fontSize: 12),
              ),
              value: _createAnother,
              onChanged: (v) => setState(() => _createAnother = v),
              contentPadding: EdgeInsets.zero,
            ),
          const SizedBox(height: 16),
          _SectionLabel(label: 'Not'),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Randevu notu...'),
          ),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _save,
            child: Text(isEditing ? 'Güncelle' : 'Randevu Ekle'),
          ),
        ],
      ),
    );
  }

  String _durationLabel(int min) {
    if (min < 60) return '$min dk';
    final h = min ~/ 60;
    final m = min % 60;
    return m == 0 ? '$h sa' : '$h sa $m dk';
  }
}

class _ReminderPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  static const _options = [10, 15, 30, 45, 60, 120, 180, 360, 720, 1440];

  const _ReminderPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isCustom = !_options.contains(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._options.map((minutes) {
              final isSelected = value == minutes;
              return ChoiceChip(
                label: Text(_label(minutes)),
                selected: isSelected,
                onSelected: (_) => onChanged(minutes),
              );
            }),
            ActionChip(
              avatar: Icon(CupertinoIcons.slider_horizontal_3, color: primary),
              label: Text(isCustom ? 'Manuel: ${_label(value)}' : 'Manuel'),
              onPressed: () => _showCustomDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Randevudan ${_label(value)} önce hatırlatma gönderilir.',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Future<void> _showCustomDialog(BuildContext context) async {
    final controller = TextEditingController(text: value.toString());
    final result = await showCupertinoDialog<int>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Manuel Hatırlatma'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            placeholder: 'Dakika olarak girin',
            suffix: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text('dk'),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, parsed);
            },
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result > 0) {
      onChanged(result);
    }
  }

  static String _label(int minutes) {
    if (minutes < 60) return '$minutes dk';
    if (minutes == 1440) return '1 gün';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours sa';
    return '$hours sa $remainingMinutes dk';
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicePicker extends StatelessWidget {
  final List<Service> services;
  final List<Service> selected;
  final ValueChanged<Service> onToggle;

  const _ServicePicker({
    required this.services,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: services.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final isLast = i == services.length - 1;
          final isSelected = selected.any((item) => item.id == s.id);
          return Column(
            children: [
              InkWell(
                onTap: () => onToggle(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: const TextStyle(fontSize: 15)),
                            Text(
                              '${s.durationMinutes} dk • ${s.price} TL',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          CupertinoIcons.checkmark_alt_circle_fill,
                          color: primary,
                          size: 20,
                        )
                      else
                        Icon(
                          CupertinoIcons.circle,
                          color: Theme.of(context).dividerColor,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
              if (!isLast) const Divider(indent: 38, height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DurationPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  static const _options = [15, 30, 45, 60, 90, 120, 150, 180];

  const _DurationPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((min) {
        final isSelected = min == value;
        return GestureDetector(
          onTap: () => onChanged(min),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? primary
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? primary : Theme.of(context).dividerColor,
              ),
            ),
            child: Text(
              min < 60
                  ? '$min dk'
                  : '${min ~/ 60}${min % 60 == 0 ? '' : ':${(min % 60).toString().padLeft(2, '0')}'} sa',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CustomerSelector extends ConsumerWidget {
  final Customer? selected;
  final TextEditingController searchController;
  final ValueChanged<Customer> onSelected;

  const _CustomerSelector({
    required this.selected,
    required this.searchController,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    if (selected != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primary.withAlpha(80)),
        ),
        child: Row(
          children: [
            _Avatar(name: selected!.name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    selected!.phone,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => onSelected(selected!),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text('Değiştir'),
            ),
          ],
        ),
      );
    }
    return _CustomerSearch(
      controller: searchController,
      onSelected: onSelected,
    );
  }
}

class _CustomerSearch extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final ValueChanged<Customer> onSelected;

  const _CustomerSearch({required this.controller, required this.onSelected});

  @override
  ConsumerState<_CustomerSearch> createState() => _CustomerSearchState();
}

class _CustomerSearchState extends ConsumerState<_CustomerSearch> {
  bool _showList = false;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(customersNotifierProvider).value ?? [];
    final query = widget.controller.text.toLowerCase().trim();
    final filtered = query.isEmpty
        ? all
        : all
              .where(
                (c) =>
                    c.name.toLowerCase().contains(query) ||
                    c.phone.contains(query),
              )
              .toList();

    return Column(
      children: [
        TextField(
          controller: widget.controller,
          decoration: const InputDecoration(
            hintText: 'Müşteri ara...',
            prefixIcon: Icon(
              CupertinoIcons.search,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          onChanged: (_) => setState(() => _showList = true),
          onTap: () => setState(() => _showList = true),
        ),
        if (_showList && filtered.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
              itemBuilder: (_, i) {
                final c = filtered[i];
                return ListTile(
                  leading: _Avatar(name: c.name),
                  title: Text(c.name, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(c.phone, style: const TextStyle(fontSize: 12)),
                  onTap: () {
                    widget.onSelected(c);
                    widget.controller.text = c.name;
                    setState(() => _showList = false);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ConflictWarning extends StatelessWidget {
  final List<Appointment> conflicts;

  const _ConflictWarning({required this.conflicts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: AppColors.warning,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${conflicts.length} çakışan randevu: ${conflicts.map((a) => a.customerName).join(', ')}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.isNotEmpty
        ? name[0].toUpperCase()
        : '?';
    final primary = Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      radius: 18,
      backgroundColor: primary.withAlpha(25),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
    );
  }
}
