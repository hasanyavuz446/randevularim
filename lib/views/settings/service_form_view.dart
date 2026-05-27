import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/service.dart';
import '../../providers/providers.dart';

class ServiceFormView extends ConsumerStatefulWidget {
  final Service? service;

  const ServiceFormView({super.key, this.service});

  @override
  ConsumerState<ServiceFormView> createState() => _ServiceFormViewState();
}

class _ServiceFormViewState extends ConsumerState<ServiceFormView> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late int _duration;
  late String _colorHex;
  bool _isActive = true;

  static const _durations = [15, 20, 30, 45, 60, 75, 90, 120, 150, 180];

  @override
  void initState() {
    super.initState();
    final svc = widget.service;
    _nameCtrl.text = svc?.name ?? '';
    _priceCtrl.text = svc?.price.toString() ?? '0';
    _descCtrl.text = svc?.description ?? '';
    _duration = svc?.durationMinutes ?? 30;
    _colorHex = svc?.colorHex ?? AppColors.serviceColorPalette.first;
    _isActive = svc?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hizmet adı zorunludur.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final notifier = ref.read(servicesNotifierProvider.notifier);
    final services = ref.read(servicesNotifierProvider).value ?? [];

    if (widget.service != null) {
      await notifier.updateService(
        widget.service!.copyWith(
          name: name,
          durationMinutes: _duration,
          colorHex: _colorHex,
          price: price,
          description: _descCtrl.text.trim(),
          isActive: _isActive,
        ),
      );
    } else {
      await notifier.addService(
        Service.create(
          name: name,
          durationMinutes: _duration,
          colorHex: _colorHex,
          sortOrder: services.length,
          price: price,
          description: _descCtrl.text.trim(),
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final proceed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('"${widget.service!.name}" Silinsin mi?'),
        content: const Text(
          'Bu hizmet silinecek. Mevcut randevular etkilenmez.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Vazgeç'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Sil'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (proceed == true && mounted) {
      await ref
          .read(servicesNotifierProvider.notifier)
          .deleteService(widget.service!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.service != null;
    final surface = Theme.of(context).colorScheme.surface;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final primary = Theme.of(context).colorScheme.primary;
    final selectedColor = AppColors.fromHex(_colorHex);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(isEditing ? 'Hizmet Düzenle' : 'Yeni Hizmet'),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [selectedColor, selectedColor.withAlpha(180)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.briefcase,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameCtrl.text.isEmpty ? 'Hizmet Adı' : _nameCtrl.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_durationLabel(_duration)} • ${_priceCtrl.text} TL',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _Label('HİZMET ADI'),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Örn: Danışmanlık, Bakım, Muayene...',
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 20),

          _Label('FİYAT (TL)'),
          TextField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: '0.00',
              prefixText: '₺ ',
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 20),

          _Label('AÇIKLAMA'),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Hizmet hakkında kısa bilgi...',
            ),
          ),

          const SizedBox(height: 20),

          _Label('VARSAYILAN SÜRE'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _durations.map((d) {
              final isSelected = d == _duration;
              return GestureDetector(
                onTap: () => setState(() => _duration = d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? primary : surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? primary
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    _durationLabel(d),
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
          ),

          const SizedBox(height: 20),

          _Label('RENK'),
          GridView.count(
            crossAxisCount: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: AppColors.serviceColorPalette.map((hex) {
              final color = AppColors.fromHex(hex);
              final isSelected = hex == _colorHex;
              return GestureDetector(
                onTap: () => setState(() => _colorHex = hex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withAlpha(120),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          SwitchListTile.adaptive(
            title: const Text(
              'Hizmet Aktif',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Pasif hizmetler yeni randevularda seçilemez.',
              style: TextStyle(fontSize: 12),
            ),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _save,
            child: Text(isEditing ? 'Güncelle' : 'Hizmet Ekle'),
          ),
          if (isEditing) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _delete,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              child: const Text('Hizmeti Sil'),
            ),
          ],
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

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
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
