import 'package:flutter/material.dart';
import '../../settings/settings_screen.dart';

/// The customer's Profile tab: profile details, settings and mode switching.
class CustomerProfileTab extends StatelessWidget {
  const CustomerProfileTab({super.key});

  @override
  Widget build(BuildContext context) => const SettingsScreen(embedded: true);
}
