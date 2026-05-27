import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../models/customer.dart';
import '../../providers/providers.dart';

class CustomerFormView extends ConsumerStatefulWidget {
  final Customer? customer;

  const CustomerFormView({super.key, this.customer});

  @override
  ConsumerState<CustomerFormView> createState() => _CustomerFormViewState();
}

class _CustomerFormViewState extends ConsumerState<CustomerFormView> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _serviceNotesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final FlutterNativeContactPicker _contactPicker = FlutterNativeContactPicker();

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    if (c != null) {
      _nameCtrl.text = c.name;
      _phoneCtrl.text = c.phone;
      _serviceNotesCtrl.text = c.serviceNotes;
      _notesCtrl.text = c.generalNotes;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _serviceNotesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    try {
      final contact = await _contactPicker.selectContact();
      if (contact != null) {
        setState(() {
          _nameCtrl.text = contact.fullName ?? '';
          if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
            _phoneCtrl.text = contact.phoneNumbers!.first;
          }
        });
      }
    } catch (e) {
      _error('Rehber açılırken bir hata oluştu: $e');
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty) {
      _error('Müşteri adı zorunludur.');
      return;
    }
    if (phone.isEmpty) {
      _error('Telefon numarası zorunludur.');
      return;
    }

    final notifier = ref.read(customersNotifierProvider.notifier);

    if (widget.customer != null) {
      await notifier.updateCustomer(
        widget.customer!.copyWith(
          name: name,
          phone: phone,
          serviceNotes: _serviceNotesCtrl.text.trim(),
          generalNotes: _notesCtrl.text.trim(),
        ),
      );
    } else {
      await notifier.addCustomer(
        Customer.create(
          name: name,
          phone: phone,
          serviceNotes: _serviceNotesCtrl.text.trim(),
          generalNotes: _notesCtrl.text.trim(),
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final futureAppointments = await ref.read(appointmentRepositoryProvider).getFutureByCustomer(widget.customer!.id);
    final hasFuture = futureAppointments.isNotEmpty;
    if (!mounted) return;

    final proceed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(hasFuture ? 'Gelecek Randevular Var!' : 'Müşteriyi Sil'),
        content: Text(hasFuture 
          ? '${widget.customer!.name} isimli müşterinin ${futureAppointments.length} adet gelecek randevusu bulunuyor. Müşteriyi silerseniz bu randevular da silinecektir. Devam etmek istiyor musunuz?'
          : '${widget.customer!.name} isimli müşteriyi silmek istediğinize emin misiniz? Geçmiş randevu kayıtları saklanacaktır.'),
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
      await ref.read(customersNotifierProvider.notifier).deleteCustomer(widget.customer!.id, deleteFutureAppointments: true);
      if (mounted) {
        Navigator.pop(context); 
        Navigator.pop(context); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.customer!.name} silindi')),
        );
      }
    }
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Müşteri Düzenle' : 'Yeni Müşteri'),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(CupertinoIcons.person_crop_circle_fill_badge_plus),
              onPressed: _pickContact,
              tooltip: 'Rehberden Seç',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(title: 'Temel Bilgiler'),
          _Field(
            controller: _nameCtrl,
            label: 'Ad Soyad',
            icon: CupertinoIcons.person,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: _phoneCtrl,
            label: 'Telefon',
            icon: CupertinoIcons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          _Section(title: 'Hizmet Notları'),
          TextField(
            controller: _serviceNotesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Hizmet detayları, özel tercihler ve geçmiş notlar...',
              label: Text('Hizmet Geçmişi Notları'),
            ),
          ),
          const SizedBox(height: 20),
          _Section(title: 'Genel Notlar'),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Müşteri hakkında genel notlar...',
              label: Text('Notlar'),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _save,
            child: Text(isEditing ? 'Güncelle' : 'Müşteri Ekle'),
          ),
          if (isEditing) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _delete,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              child: const Text('Müşteriyi Sil'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;

  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        label: Text(label),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}