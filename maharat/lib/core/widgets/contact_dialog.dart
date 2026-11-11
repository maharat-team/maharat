import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../utils/contact_launcher.dart';
import '../utils/phone_utils.dart';

/// Confirms before calling or opening WhatsApp, and shows the number so it can
/// be noted down.
void showContactDialog(
  BuildContext context, {
  required String name,
  String? subtitle,
  required String phone,
  required bool isWhatsApp,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            isWhatsApp ? Icons.chat_bubble_rounded : Icons.call_rounded,
            color: isWhatsApp ? AppColors.whatsappGreen : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isWhatsApp
                  ? ctx.tr('WhatsApp', 'واٹس ایپ')
                  : ctx.tr('Direct Call', 'براہ راست کال'),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle == null ? name : '$name ($subtitle)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            ctx.tr(
              'Phone: ${PhoneUtils.display(phone)}',
              'فون: ${PhoneUtils.display(phone)}',
            ),
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: AppColors.primaryText, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ctx.tr(
                'Maharat charges no commission. Agree the price directly.',
                'مہارت کوئی کمیشن نہیں لیتا۔ قیمت براہ راست طے کریں۔',
              ),
              style: const TextStyle(fontSize: 12, color: AppColors.darkGreen),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(ctx.tr('Cancel', 'منسوخ')),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isWhatsApp
                ? AppColors.whatsappGreen
                : AppColors.primary,
            minimumSize: const Size(0, 44),
          ),
          onPressed: () {
            Navigator.pop(ctx);
            contactWorker(context, phone: phone, isWhatsApp: isWhatsApp);
          },
          child: Text(
            isWhatsApp
                ? ctx.tr('Open WhatsApp', 'واٹس ایپ کھولیں')
                : ctx.tr('Call Now', 'ابھی کال کریں'),
          ),
        ),
      ],
    ),
  );
}
