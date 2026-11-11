import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/geo.dart';
import '../../core/widgets/custom_button.dart';
import '../../services/location_service.dart';

/// What the picker returns: the pin and optional house or street details.
class PickedLocation {
  final LatLng point;
  final String addressDetails;

  const PickedLocation(this.point, this.addressDetails);
}

/// Shared tile setup. OpenStreetMap needs no API key; its usage policy asks
/// apps to identify themselves.
TileLayer osmTiles() => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.technestnova.maharat',
  maxZoom: 19,
);

Widget osmAttribution() => RichAttributionWidget(
  attributions: [
    TextSourceAttribution(
      'OpenStreetMap contributors',
      onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
    ),
  ],
);

/// Full-screen Bahawalpur map. The user moves the map under a fixed centre
/// pin, or taps "Use my location", then confirms.
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;
  final String initialDetails;
  final String title;

  /// Whether to ask for house or street details (not needed for a shop's
  /// map pin when the address is entered elsewhere).
  final bool askDetails;

  const LocationPickerScreen({
    super.key,
    this.initial,
    this.initialDetails = '',
    required this.title,
    this.askDetails = true,
  });

  /// Opens the picker and returns the chosen location, or null if cancelled.
  static Future<PickedLocation?> open(
    BuildContext context, {
    LatLng? initial,
    String initialDetails = '',
    String? title,
    bool askDetails = true,
  }) {
    return Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: initial,
          initialDetails: initialDetails,
          title: title ?? context.tr('Choose location', 'مقام منتخب کریں'),
          askDetails: askDetails,
        ),
      ),
    );
  }

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapController = MapController();
  late final TextEditingController _detailsController;
  late LatLng _center;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? Bahawalpur.center;
    _detailsController = TextEditingController(text: widget.initialDetails);
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final messenger = ScaffoldMessenger.of(context);
    final outside = context.tr(
      'You seem to be outside Bahawalpur. Move the pin to the right place.',
      'آپ بہاولپور سے باہر لگتے ہیں۔ پن کو درست جگہ پر لے جائیں۔',
    );
    final failed = context.tr(
      'Could not find your location. Move the pin yourself.',
      'آپ کا مقام نہیں مل سکا۔ پن خود منتقل کریں۔',
    );
    try {
      final here = await LocationService().current();
      if (!mounted) return;
      if (!Bahawalpur.contains(here)) {
        messenger.showSnackBar(SnackBar(content: Text(outside)));
        return;
      }
      _mapController.move(here, 17);
      setState(() => _center = here);
    } on LocationException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    if (!Bahawalpur.contains(_center)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Please place the pin inside Bahawalpur.',
              'براہ کرم پن بہاولپور کے اندر لگائیں۔',
            ),
          ),
        ),
      );
      return;
    }
    Navigator.of(
      context,
    ).pop(PickedLocation(_center, _detailsController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: widget.initial == null ? 13 : 16,
                    minZoom: 11,
                    maxZoom: 19,
                    cameraConstraint: CameraConstraint.containCenter(
                      bounds: LatLngBounds(
                        LatLng(Bahawalpur.south, Bahawalpur.west),
                        LatLng(Bahawalpur.north, Bahawalpur.east),
                      ),
                    ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onPositionChanged: (camera, hasGesture) {
                      _center = camera.center;
                    },
                    onTap: (_, point) {
                      _mapController.move(
                        point,
                        _mapController.camera.zoom,
                      );
                      setState(() => _center = point);
                    },
                  ),
                  children: [osmTiles(), osmAttribution()],
                ),
                // The pin stays in the middle; its tip marks the spot.
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 48,
                        color: AppColors.statusRed,
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: 16,
                  bottom: 24,
                  child: FloatingActionButton.extended(
                    heroTag: 'my-location',
                    onPressed: _locating ? null : _useMyLocation,
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primary,
                    icon: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded),
                    label: Text(context.tr('My location', 'میرا مقام')),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr(
                      'Move the map so the pin sits on your door.',
                      'نقشے کو اس طرح ہلائیں کہ پن آپ کے دروازے پر ہو۔',
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  if (widget.askDetails) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _detailsController,
                      maxLength: 200,
                      decoration: InputDecoration(
                        counterText: '',
                        prefixIcon: const Icon(Icons.home_outlined),
                        hintText: context.tr(
                          'House no., street, landmark (optional)',
                          'مکان نمبر، گلی، نشانی (اختیاری)',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  CustomButton(
                    text: context.tr('Confirm location', 'مقام کی تصدیق کریں'),
                    icon: Icons.check_rounded,
                    onPressed: _confirm,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
