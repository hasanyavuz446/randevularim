import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme_config.dart';
import '../../providers/providers.dart';
import 'service_management_view.dart';
import 'backup_view.dart';
import 'business_profile_view.dart';
import 'import_contacts_view.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(title: const Text('Ayarlar'), backgroundColor: surface),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Görünüm ────────────────────────────────────────────────────────
          _SectionHeader(title: 'GÖRÜNÜM'),
          const SizedBox(height: 8),

          // Tema seçimi
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: CupertinoIcons.paintbrush,
                title: 'Renk Teması',
                subtitle: AppThemeConfig.fromId(settings.themeId).name,
              ),
              const Divider(height: 1, indent: 52),
              _ThemeGrid(
                selectedId: settings.themeId,
                onSelected: notifier.setTheme,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Görünüm modu
          _SettingsCard(
            children: [
              _SettingsTile(icon: CupertinoIcons.moon, title: 'Görünüm Modu'),
              const Divider(height: 1, indent: 52),
              _AppearancePicker(
                selected: settings.themeMode,
                onChanged: notifier.setThemeMode,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Hizmetler ──────────────────────────────────────────────────────
          _SectionHeader(title: 'HİZMET YÖNETİMİ'),
          const SizedBox(height: 8),

          _SettingsCard(
            children: [
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.building_2_fill,
                    size: 16,
                    color: Colors.blue,
                  ),
                ),
                title: const Text(
                  'İşletme Profili',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Çalışma saatleri ve iletişim',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const BusinessProfileView(),
                  ),
                ),
              ),
              const Divider(indent: 56, height: 1),
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.list_bullet,
                    size: 16,
                    color: primary,
                  ),
                ),
                title: const Text(
                  'Hizmetleri Düzenle',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Ekle, düzenle, sil',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const ServiceManagementView(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Bildirimler ───────────────────────────────────────────────────
          _SectionHeader(title: 'BİLDİRİMLER'),
          const SizedBox(height: 8),

          _SettingsCard(
            children: [
              SwitchListTile.adaptive(
                secondary: Icon(
                  CupertinoIcons.bell_fill,
                  size: 18,
                  color: primary,
                ),
                title: const Text(
                  'Genel Bildirimler',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Randevu hatırlatıcılarını etkinleştir',
                  style: TextStyle(fontSize: 12),
                ),
                value: settings.globalNotificationsEnabled,
                onChanged: notifier.setGlobalNotifications,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              if (settings.globalNotificationsEnabled) ...[
                const Divider(height: 1, indent: 52),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.timer,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Hatırlatma Zamanı',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DropdownButton<int>(
                        value: settings.reminderMinutes,
                        underline: const SizedBox(),
                        items: [0, 15, 30, 45, 60, 120].map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text(
                              m == 0 ? 'Tam Zamanında' : '$m dk önce',
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => notifier.setReminderMinutes(v!),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),
          // ── Veri Yönetimi ──────────────────────────────────────────────────
          _SectionHeader(title: 'VERİ YÖNETİMİ'),
          const SizedBox(height: 8),

          _SettingsCard(
            children: [
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.person_crop_circle_fill_badge_plus,
                    size: 16,
                    color: primary,
                  ),
                ),
                title: const Text(
                  'Rehberden Aktar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Kişileri toplu veya seçerek ekle',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const ImportContactsView(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Veri Yedekleme ─────────────────────────────────────────────────
          _SectionHeader(title: 'GÜVENLİK VE YEDEKLEME'),
          const SizedBox(height: 8),

          _SettingsCard(
            children: [
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.cloud_upload,
                    size: 16,
                    color: Colors.orange,
                  ),
                ),
                title: const Text(
                  'Veri Yedekleme',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Verilerinizi dışarı aktarın',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const BackupView()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          // Versiyon
          Center(
            child: Text(
              'Randevu Takip v1.0',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Bileşenler ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SettingsTile({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelected;

  const _ThemeGrid({required this.selectedId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
        children: AppThemeConfig.all.map((config) {
          final isSelected = config.id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(config.id),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [config.primary, config.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          )
                        : Border.all(color: Colors.transparent, width: 3),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: config.primary.withAlpha(80),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 24,
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  config.name,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AppearancePicker extends StatelessWidget {
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  static const _options = [
    (ThemeMode.light, CupertinoIcons.sun_max, 'Açık'),
    (ThemeMode.dark, CupertinoIcons.moon_stars, 'Koyu'),
    (ThemeMode.system, CupertinoIcons.circle_lefthalf_fill, 'Otomatik'),
  ];

  const _AppearancePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: _options.map((opt) {
          final (mode, icon, label) = opt;
          final isSelected = mode == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? primary
                        : Theme.of(context).dividerColor,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
