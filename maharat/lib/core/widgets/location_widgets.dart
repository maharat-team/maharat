import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../features/location/location_picker_screen.dart';
import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import '../theme/app_colors.dart';
import '../utils/contact_launcher.dart';
import '../utils/geo.dart';

/// A small, non-interactive map with a pin, plus directions and distance.
class LocationPreviewCard extends StatelessWidget {
  final LatLng point;
  final String? title;
  final String addressDetails;

  /// The viewer's own location, for "2.3 km away".
  final LatLng? from;

  /// False for approximate points, which get a circle instead of a pin and no
  /// directions button.
  final bool isExact;

  const LocationPreviewCard({
    super.key,
    required this.point,
    this.title,
    this.addressDetails = '',
    this.from,
    this.isExact = true,
  });

  @override
  Widget build(BuildContext context) {
    final km = distanceBetween(from, point);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
            child: IgnorePointer(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: isExact ? 15.5 : 13.5,
                ),
                children: [
                  osmTiles(),
                  if (isExact)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 40,
                            color: AppColors.statusRed,
                          ),
                        ),
                      ],
                    )
                  else
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: point,
                          radius: 700,
                          useRadiusInMeter: true,
                          color: AppColors.primary.withAlpha(50),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 1.5,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ??
                            (isExact
                                ? context.tr('Exact location', 'درست مقام')
                                : context.tr(
                                    'Approximate area',
                                    'تقریبی علاقہ',
                                  )),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      if (addressDetails.isNotEmpty)
                        Text(
                          addressDetails,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      if (km != null)
                        Text(
                          context.distance(km),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isExact)
                  FilledButton.icon(
                    onPressed: () => openDirections(context, point),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(0, 40),
                    ),
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: Text(context.tr('Directions', 'راستہ')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A form row that shows the chosen pin and opens the map to change it.
class LocationField extends StatelessWidget {
  final String label;
  final LatLng? value;
  final String addressDetails;
  final ValueChanged<PickedLocation> onChanged;
  final bool askDetails;
  final bool required;

  const LocationField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.addressDetails = '',
    this.askDetails = true,
    this.required = false,
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await LocationPickerScreen.open(
      context,
      initial: value,
      initialDetails: addressDetails,
      title: label,
      askDetails: askDetails,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final point = value;
    final summary = point == null
        ? (required
              ? context.tr('Tap to place your pin', 'پن لگانے کے لیے ٹیپ کریں')
              : context.tr(
                  'Optional: helps workers reach you',
                  'اختیاری: کاریگروں کو آپ تک پہنچنے میں مدد',
                ))
        : (addressDetails.isNotEmpty
              ? addressDetails
              : context.tr('Pin placed on map', 'نقشے پر پن لگ گئی'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: point == null ? AppColors.white : AppColors.lightMint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: point == null ? AppColors.border : AppColors.primary,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: () => _pick(context),
            leading: Icon(
              point == null ? Icons.add_location_alt_outlined : Icons.place,
              color: point == null ? AppColors.primary : AppColors.statusRed,
            ),
            title: Text(
              point == null
                  ? context.tr('Choose on Bahawalpur map', 'بہاولپور نقشے پر منتخب کریں')
                  : context.tr('Location selected', 'مقام منتخب ہو گیا'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Icon(
              point == null ? Icons.map_outlined : Icons.edit_location_alt,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
