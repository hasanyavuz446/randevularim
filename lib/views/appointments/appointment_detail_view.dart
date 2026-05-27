import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../models/appointment.dart';
import '../../models/enums.dart';
import '../../providers/providers.dart';
import 'appointment_form_view.dart';

class AppointmentDetailView extends ConsumerWidget {
  final Appointment appointment;

  const AppointmentDetailView({super.key, required this.appointment});

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uygulama açılamadı: $urlString'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAppts = ref.watch(appointmentsNotifierProvider).value ?? [];
    final current = allAppts.firstWhere(
      (a) => a.id == appointment.id,
      orElse: () => appointment,
    );

    final color = AppColors.fromHex(current.serviceColor);
    final surface = Theme.of(context).colorScheme.surface;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Randevu Detayı'),
        backgroundColor: surface,
        actions: [
          if (current.isActive)
            IconButton(
              icon: const Icon(CupertinoIcons.pencil),
              onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => AppointmentFormView(appointment: current),
                ),
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
              color: surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(CupertinoIcons.briefcase, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            current.serviceName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${current.durationMinutes} dakika • ${current.totalPrice.toStringAsFixed(2)} TL',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: current.status),
                  ],
                ),
                const Divider(height: 28),
                _InfoRow(
                  icon: CupertinoIcons.person_fill,
                  label: 'Müşteri',
                  value: current.customerName,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: CupertinoIcons.phone_fill,
                  label: 'Telefon',
                  value: current.customerPhone,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: CupertinoIcons.calendar,
                  label: 'Tarih',
                  value: DateFormat(
                    'd MMMM yyyy, EEEE',
                    'tr_TR',
                  ).format(current.dateTime),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: CupertinoIcons.bell_fill,
                  label: 'Bildirim',
                  value: current.notificationsEnabled
                      ? 'Başlangıç: ${current.startNotificationEnabled ? 'Açık' : 'Kapalı'} • Hatırlatma: ${_reminderLabel(current.reminderMinutes)} önce'
                      : 'Kapalı',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: CupertinoIcons.clock,
                  label: 'Saat',
                  value:
                      '${DateFormat('HH:mm').format(current.dateTime)} – ${DateFormat('HH:mm').format(current.endTime)}',
                ),
                if (current.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: CupertinoIcons.doc_text,
                    label: 'Not',
                    value: current.notes,
                  ),
                ],
              ],
            ),
          ),

          if (current.isActive) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: CupertinoIcons.phone_fill,
                    label: 'Ara',
                    color: Colors.blue,
                    onTap: () =>
                        _launchURL(context, 'tel:${current.customerPhone}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: CupertinoIcons.chat_bubble_fill,
                    label: 'Hatırlatıcı',
                    color: Colors.green,
                    onTap: () => _showReminderOptions(context, ref, current),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (current.isScheduled) ...[
              ElevatedButton.icon(
                onPressed: () => _confirm(context, ref, current),
                icon: const Icon(CupertinoIcons.check_mark_circled),
                label: const Text('Randevuyu Teyit Et'),
              ),
              const SizedBox(height: 10),
            ],
            ElevatedButton(
              onPressed: () => _complete(context, ref, current),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tamamlandı Olarak İşaretle'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _markNoShow(context, ref, current),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Müşteri Gelmedi'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _cancel(context, ref, current),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Randevuyu İptal Et'),
            ),
          ],
        ],
      ),
    );
  }

  void _showReminderOptions(
    BuildContext context,
    WidgetRef ref,
    Appointment appt,
  ) {
    final biz = ref.read(businessNotifierProvider).value;
    final bizName = biz?.name ?? 'İşletmem';

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('WhatsApp Hatırlatıcısı'),
        message: const Text('Müşteriye gönderilecek mesaj tipini seçin.'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _sendWhatsApp(
                context,
                appt,
                'Merhaba ${appt.customerName}, $bizName randevunuz ${DateFormat('d MMMM', 'tr_TR').format(appt.dateTime)} tarihinde saat ${DateFormat('HH:mm').format(appt.dateTime)} için oluşturulmuştur. Görüşmek üzere!',
              );
            },
            child: const Text('Yeni Randevu Mesajı'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _sendWhatsApp(
                context,
                appt,
                'Merhaba ${appt.customerName}, ${DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(appt.dateTime)} saat ${DateFormat('HH:mm').format(appt.dateTime)} randevunuz olduğunu hatırlatmak isteriz. Görüşmek üzere!',
              );
            },
            child: const Text('Randevu Hatırlatması'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Vazgeç'),
        ),
      ),
    );
  }

  void _sendWhatsApp(BuildContext context, Appointment appt, String message) {
    final encodedMsg = Uri.encodeComponent(message);
    final phone = appt.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanPhone = phone.startsWith('0') ? '9$phone' : phone;
    final url = 'https://wa.me/$cleanPhone?text=$encodedMsg';
    _launchURL(context, url);
  }

  String _reminderLabel(int minutes) {
    if (minutes < 60) return '$minutes dk';
    if (minutes == 1440) return '1 gün';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours sa';
    return '$hours sa $remainingMinutes dk';
  }

  void _complete(BuildContext context, WidgetRef ref, Appointment appt) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Tamamlandı mı?'),
        content: const Text('Randevu tamamlandı olarak işaretlenecek.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(appointmentsNotifierProvider.notifier)
                  .completeAppointment(appt.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Tamamlandı'),
          ),
        ],
      ),
    );
  }

  void _confirm(BuildContext context, WidgetRef ref, Appointment appt) {
    ref.read(appointmentsNotifierProvider.notifier).confirmAppointment(appt.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Randevu teyit edildi.')));
  }

  void _markNoShow(BuildContext context, WidgetRef ref, Appointment appt) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Müşteri gelmedi mi?'),
        content: const Text('Randevu gelmedi olarak kaydedilecek.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(appointmentsNotifierProvider.notifier)
                  .markNoShow(appt.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Gelmedi'),
          ),
        ],
      ),
    );
  }

  void _cancel(BuildContext context, WidgetRef ref, Appointment appt) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Randevuyu İptal Et'),
        content: const Text('Bu randevu iptal edilecek.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(appointmentsNotifierProvider.notifier)
                  .cancelAppointment(appt.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AppointmentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final (color, bg) = switch (status) {
      AppointmentStatus.scheduled => (primary, primary.withAlpha(20)),
      AppointmentStatus.confirmed => (
        const Color(0xFF007AFF),
        const Color(0xFF007AFF).withAlpha(20),
      ),
      AppointmentStatus.completed => (
        AppColors.success,
        AppColors.success.withAlpha(20),
      ),
      AppointmentStatus.cancelled => (
        AppColors.danger,
        AppColors.danger.withAlpha(20),
      ),
      AppointmentStatus.noShow => (
        AppColors.warning,
        AppColors.warning.withAlpha(20),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
