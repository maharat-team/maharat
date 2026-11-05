import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the dialer or WhatsApp for a +92 number.
Future<void> contactWorker(
  BuildContext context, {
  required String phone,
  required bool isWhatsApp,
}) async {
  final uri = isWhatsApp
      ? Uri.parse('https://wa.me/${phone.replaceAll('+', '')}')
      : Uri(scheme: 'tel', path: phone);
  final messenger = ScaffoldMessenger.of(context);
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isWhatsApp
              ? 'Could not open WhatsApp. Number: $phone'
              : 'Could not start a call. Number: $phone',
        ),
      ),
    );
  }
}
