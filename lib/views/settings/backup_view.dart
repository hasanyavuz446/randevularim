import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';

class BackupView extends ConsumerStatefulWidget {
  const BackupView({super.key});

  @override
  ConsumerState<BackupView> createState() => _BackupViewState();
}

class _BackupViewState extends ConsumerState<BackupView> {
  bool _isWorking = false;

  Future<void> _exportBackup() async {
    setState(() => _isWorking = true);
    try {
      final service = await ref.read(backupServiceProvider.future);
      final jsonString = await service.exportJson();
      final directory = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${directory.path}/randevularim_yedek_$stamp.json');
      await file.writeAsString(jsonString);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Randevularım uygulama yedeği');
    } catch (e) {
      _showError('Yedekleme hatası: $e');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _restoreBackup() async {
    const typeGroup = XTypeGroup(
      label: 'JSON yedek dosyasi',
      extensions: <String>['json'],
    );
    final picked = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (picked == null || !mounted) return;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Yedeği Geri Yükle'),
        content: const Text(
          'Mevcut müşteri, randevu, hizmet ve işletme verileri seçilen '
          'yedekle değiştirilecek. Devam edilsin mi?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Geri Yükle'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isWorking = true);
    try {
      final bytes = await picked.readAsBytes();

      final service = await ref.read(backupServiceProvider.future);
      await service.restoreJson(utf8.decode(bytes));
      ref.read(settingsNotifierProvider.notifier).reload();
      await ref.read(customersNotifierProvider.notifier).loadAll();
      await ref.read(appointmentsNotifierProvider.notifier).loadAll();
      await ref.read(servicesNotifierProvider.notifier).loadAll();
      await ref.read(businessNotifierProvider.notifier).load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yedek başarıyla geri yüklendi.')),
        );
      }
    } catch (e) {
      _showError('Geri yükleme hatası: $e');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Veri Yedekleme')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            CupertinoIcons.cloud_upload,
            size: 76,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Verilerinizi Güvende Tutun',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Müşterileriniz, randevularınız, hizmetleriniz ve işletme '
            'ayarlarınız tek bir JSON dosyasında saklanır.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 38),
          ElevatedButton.icon(
            onPressed: _isWorking ? null : _exportBackup,
            icon: const Icon(CupertinoIcons.share),
            label: const Text('Yedek Dosyası Oluştur ve Paylaş'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _isWorking ? null : _restoreBackup,
            icon: const Icon(CupertinoIcons.arrow_down_doc),
            label: const Text('Yedekten Geri Yükle'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
          if (_isWorking) ...[
            const SizedBox(height: 26),
            const Center(child: CupertinoActivityIndicator()),
          ],
          const SizedBox(height: 22),
          const Text(
            'Geri yükleme, cihazdaki mevcut verilerin yerine yedek '
            'dosyasındaki kayıtları yazar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
