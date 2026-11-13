import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/l10n.dart';

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
  final message = isWhatsApp
      ? context.tr(
          'Could not open WhatsApp. Number: $phone',
          'واٹس ایپ نہیں کھل سکا۔ نمبر: $phone',
        )
      : context.tr(
          'Could not start a call. Number: $phone',
          'کال نہیں ہو سکی۔ نمبر: $phone',
        );
  if (!await _open(uri)) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Turn-by-turn directions to [destination] in Google Maps (app or web).
Future<void> openDirections(BuildContext context, LatLng destination) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=${destination.latitude},${destination.longitude}',
  );
  final messenger = ScaffoldMessenger.of(context);
  final message = context.tr(
    'Could not open maps.',
    'نقشہ نہیں کھل سکا۔',
  );
  if (!await _open(uri)) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

Future<bool> _open(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
