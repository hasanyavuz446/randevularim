import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../models/customer.dart';
import '../../providers/providers.dart';

class ImportContactsView extends ConsumerStatefulWidget {
  const ImportContactsView({super.key});

  @override
  ConsumerState<ImportContactsView> createState() => _ImportContactsViewState();
}

class _ImportContactsViewState extends ConsumerState<ImportContactsView> {
  List<Contact> _contacts = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final status = await Permission.contacts.request();
      if (status.isGranted) {
        final contacts = await FastContacts.getAllContacts();
        if (mounted) {
          setState(() {
            _contacts = contacts.where((c) => c.phones.isNotEmpty).toList()
              ..sort((a, b) => (a.displayName).compareTo(b.displayName));
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('Rehber erişim izni verilmedi.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Rehber yüklenirken hata oluştu: $e');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  List<Contact> get _filteredContacts {
    if (_searchQuery.isEmpty) return _contacts;
    return _contacts
        .where(
          (c) =>
              c.displayName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              c.phones.any((p) => p.number.contains(_searchQuery)),
        )
        .toList();
  }

  Future<void> _importSelected() async {
    if (_selectedIds.isEmpty) return;

    final toImport = _contacts
        .where((c) => _selectedIds.contains(c.id))
        .toList();
    await _performImport(toImport);
  }

  Future<void> _importAll() async {
    final filtered = _filteredContacts;
    if (filtered.isEmpty) return;

    final proceed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Tüm Rehberi Aktar'),
        content: Text(
          '${filtered.length} kişinin tamamını müşteri listesine eklemek istediğinize emin misiniz?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Vazgeç'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Hepsini Aktar'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (proceed == true) {
      await _performImport(filtered);
    }
  }

  Future<void> _performImport(List<Contact> contactsToImport) async {
    setState(() => _isLoading = true);

    final existingCustomers = ref.read(customersNotifierProvider).value ?? [];
    final existingPhones = existingCustomers
        .map((c) => _cleanPhone(c.phone))
        .toSet();

    final List<Customer> newCustomers = [];
    for (final c in contactsToImport) {
      final phone = c.phones.first.number;
      if (!_isDuplicate(phone, existingPhones)) {
        newCustomers.add(
          Customer.create(
            name: c.displayName,
            phone: phone,
            serviceNotes: '',
            generalNotes: 'Rehberden aktarıldı',
          ),
        );
      }
    }

    if (newCustomers.isNotEmpty) {
      await ref
          .read(customersNotifierProvider.notifier)
          .bulkAddCustomers(newCustomers);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newCustomers.length} yeni müşteri eklendi.'),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seçilen kişiler zaten listenizde mevcut.'),
          ),
        );
      }
    }
  }

  bool _isDuplicate(String phone, Set<String> existing) {
    final cleaned = _cleanPhone(phone);
    if (cleaned.isEmpty) return true;
    return existing.contains(cleaned);
  }

  String _cleanPhone(String p) => p.replaceAll(RegExp(r'[^0-9]'), '');

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredContacts;
    final surface = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rehberden Aktar'),
        backgroundColor: surface,
        actions: [
          if (!_isLoading && filtered.isNotEmpty)
            TextButton(
              onPressed: _importAll,
              child: const Text('Hepsini Aktar'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TapRegion(
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              child: CupertinoSearchTextField(
                placeholder: 'İsim veya numara ara...',
                onChanged: (v) => setState(() => _searchQuery = v),
                onSubmitted: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ),
          ),
          if (!_isLoading && filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} kişi bulundu',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedIds.length == filtered.length) {
                          _selectedIds.clear();
                        } else {
                          _selectedIds.addAll(filtered.map((c) => c.id));
                        }
                      });
                    },
                    child: Text(
                      _selectedIds.length == filtered.length
                          ? 'Seçimi Kaldır'
                          : 'Tümünü Seç',
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? const Center(child: Text('Kişi bulunamadı.'))
                : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const Divider(indent: 56, height: 1),
                    itemBuilder: (ctx, i) {
                      final c = filtered[i];
                      final isSelected = _selectedIds.contains(c.id);
                      final phone = c.phones.first.number;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(20),
                          child: Text(
                            c.displayName.isNotEmpty ? c.displayName[0] : '?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(c.displayName),
                        subtitle: Text(phone),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedIds.add(c.id);
                              } else {
                                _selectedIds.remove(c.id);
                              }
                            });
                          },
                          shape: const CircleBorder(),
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(c.id);
                            } else {
                              _selectedIds.add(c.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedIds.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _importSelected,
                  child: Text('Seçilenleri Aktar (${_selectedIds.length})'),
                ),
              ),
            ),
    );
  }
}
