import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';

class BusinessProfileView extends ConsumerStatefulWidget {
  const BusinessProfileView({super.key});

  @override
  ConsumerState<BusinessProfileView> createState() =>
      _BusinessProfileViewState();
}

class _BusinessProfileViewState extends ConsumerState<BusinessProfileView> {
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  late List<int> _workingDays;
  late TimeOfDay _openingTime;
  late TimeOfDay _closingTime;
  late int _interval;

  @override
  void initState() {
    super.initState();
    final biz = ref.read(businessNotifierProvider).value;
    if (biz != null) {
      _nameCtrl.text = biz.name;
      _categoryCtrl.text = biz.category;
      _phoneCtrl.text = biz.phone;
      _addressCtrl.text = biz.address;
      _workingDays = List.from(biz.workingDays);
      _openingTime = _parseTime(biz.openingTime);
      _closingTime = _parseTime(biz.closingTime);
      _interval = biz.appointmentIntervalMinutes;
    } else {
      _workingDays = [1, 2, 3, 4, 5];
      _openingTime = const TimeOfDay(hour: 9, minute: 0);
      _closingTime = const TimeOfDay(hour: 18, minute: 0);
      _interval = 30;
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isOpening) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openingTime : _closingTime,
    );
    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final biz = ref.read(businessNotifierProvider).value;
    if (biz == null) return;

    final updated = biz.copyWith(
      name: _nameCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      workingDays: _workingDays,
      openingTime: _formatTime(_openingTime),
      closingTime: _formatTime(_closingTime),
      appointmentIntervalMinutes: _interval,
    );

    await ref.read(businessNotifierProvider.notifier).updateBusiness(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşletme bilgileri güncellendi.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşletme Profili'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Kaydet',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel(label: 'TEMEL BİLGİLER'),
          _TextField(
            controller: _nameCtrl,
            label: 'İşletme Adı',
            icon: CupertinoIcons.building_2_fill,
          ),
          const SizedBox(height: 12),
          _TextField(
            controller: _categoryCtrl,
            label: 'Kategori',
            icon: CupertinoIcons.tag_fill,
          ),
          const SizedBox(height: 12),
          _TextField(
            controller: _phoneCtrl,
            label: 'İş Telefonu',
            icon: CupertinoIcons.phone_fill,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _TextField(
            controller: _addressCtrl,
            label: 'Adres',
            icon: CupertinoIcons.location_fill,
            maxLines: 2,
          ),

          const SizedBox(height: 24),
          _SectionLabel(label: 'ÇALIŞMA SAATLERİ'),
          Row(
            children: [
              Expanded(
                child: _PickerTile(
                  label: 'Açılış',
                  value: _formatTime(_openingTime),
                  onTap: () => _pickTime(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerTile(
                  label: 'Kapanış',
                  value: _formatTime(_closingTime),
                  onTap: () => _pickTime(false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _SectionLabel(label: 'ÇALIŞMA GÜNLERİ'),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final day = index + 1;
              final isSelected = _workingDays.contains(day);
              final dayName = _getDayName(day);
              return FilterChip(
                label: Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                selected: isSelected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _workingDays.add(day);
                    } else if (_workingDays.length > 1) {
                      _workingDays.remove(day);
                    }
                  });
                },
                selectedColor: Theme.of(context).colorScheme.primary,
                checkmarkColor: Colors.white,
              );
            }),
          ),

          const SizedBox(height: 24),
          _SectionLabel(label: 'RANDEVU ARALIĞI'),
          DropdownButtonFormField<int>(
            initialValue: _interval,
            decoration: const InputDecoration(
              prefixIcon: Icon(CupertinoIcons.timer, size: 18),
            ),
            items: [15, 20, 30, 45, 60]
                .map(
                  (v) => DropdownMenuItem(value: v, child: Text('$v dakika')),
                )
                .toList(),
            onChanged: (v) => setState(() => _interval = v!),
          ),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Bilgileri Güncelle'),
          ),
        ],
      ),
    );
  }

  String _getDayName(int day) {
    return switch (day) {
      1 => 'Pzt',
      2 => 'Sal',
      3 => 'Çar',
      4 => 'Per',
      5 => 'Cum',
      6 => 'Cmt',
      7 => 'Paz',
      _ => '',
    };
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
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  const _TextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _PickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
