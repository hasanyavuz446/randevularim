import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../models/appointment.dart';
import '../../models/customer.dart';
import '../../providers/providers.dart';
import '../appointments/appointment_detail_view.dart';
import '../appointments/appointment_form_view.dart';
import 'customer_form_view.dart';

class CustomerDetailView extends ConsumerWidget {
  final Customer customer;

  const CustomerDetailView({super.key, required this.customer});

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      // Simulator check for tel: links
      if (urlString.startsWith('tel:') && !await canLaunchUrl(url)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Simülatörde arama özelliği kullanılamıyor. Lütfen gerçek cihazda deneyin.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

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
    final customers = ref.watch(customersNotifierProvider).value ?? [];
    final current = customers.firstWhere(
      (c) => c.id == customer.id,
      orElse: () => customer,
    );

    final allAppointments = ref.watch(appointmentsNotifierProvider).value ?? [];
    final customerAppointments =
        allAppointments.where((a) => a.customerId == current.id).toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final lastAppt = customerAppointments.isEmpty
        ? null
        : customerAppointments.first;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(current.name),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.pencil),
            onPressed: () => Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => CustomerFormView(customer: current),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileCard(customer: current, lastAppointment: lastAppt),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: CupertinoIcons.phone_fill,
                  label: 'Ara',
                  color: Colors.blue,
                  onTap: () {
                    final cleanPhone = current.phone.replaceAll(
                      RegExp(r'[^0-9+]'),
                      '',
                    );
                    _launchURL(context, 'tel:$cleanPhone');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: CupertinoIcons.chat_bubble_fill,
                  label: 'WhatsApp',
                  color: Colors.green,
                  onTap: () {
                    final phone = current.phone.replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    final cleanPhone = phone.startsWith('0')
                        ? '9$phone'
                        : phone;
                    _launchURL(context, 'https://wa.me/$cleanPhone');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (current.serviceNotes.isNotEmpty) ...[
            _NotesCard(
              title: 'Hizmet Notları',
              content: current.serviceNotes,
              icon: CupertinoIcons.briefcase,
              color: AppColors.accent,
            ),
            const SizedBox(height: 12),
          ],
          if (current.generalNotes.isNotEmpty) ...[
            _NotesCard(
              title: 'Genel Notlar',
              content: current.generalNotes,
              icon: CupertinoIcons.doc_text,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Randevu Geçmişi (${customerAppointments.length})',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => AppointmentFormView(
                      initialDate: DateTime.now(),
                      initialCustomer: current,
                    ),
                  ),
                ),
                icon: const Icon(CupertinoIcons.add, size: 16),
                label: const Text('Yeni'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (customerAppointments.isEmpty)
            const _EmptyAppointments()
          else
            ...customerAppointments.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AppointmentHistoryCard(appointment: a),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Customer customer;
  final Appointment? lastAppointment;

  const _ProfileCard({required this.customer, this.lastAppointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withAlpha(25),
            child: Text(
              customer.initials,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.phone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                if (lastAppointment != null)
                  Text(
                    'Son: ${DateFormat('d MMMM yyyy').format(lastAppointment!.dateTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  const Text(
                    'Henüz randevu yok',
                    style: TextStyle(
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

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const _NotesCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}

class _AppointmentHistoryCard extends StatelessWidget {
  final Appointment appointment;

  const _AppointmentHistoryCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(appointment.serviceColor);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => AppointmentDetailView(appointment: appointment),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: appointment.isCancelled
                    ? AppColors.textSecondary
                    : appointment.isCompleted
                    ? AppColors.success
                    : color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.serviceName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        DateFormat(
                          'd MMMM yyyy, HH:mm',
                          'tr_TR',
                        ).format(appointment.dateTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (appointment.totalPrice > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${appointment.totalPrice.toStringAsFixed(0)} TL',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (appointment.isCancelled)
              const _SmallBadge(label: 'İptal', color: AppColors.danger)
            else if (appointment.isNoShow)
              const _SmallBadge(label: 'Gelmedi', color: AppColors.warning)
            else if (appointment.isCompleted)
              const _SmallBadge(label: 'Bitti', color: AppColors.success)
            else if (appointment.isConfirmed)
              const _SmallBadge(label: 'Teyitli', color: Color(0xFF007AFF))
            else
              _SmallBadge(
                label: 'Planlandı',
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyAppointments extends StatelessWidget {
  const _EmptyAppointments();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Henüz randevu yok',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ),
    );
  }
}
