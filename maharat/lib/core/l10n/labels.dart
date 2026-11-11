import 'package:flutter/widgets.dart';
import 'l10n.dart';

/// Display names for values stored in English in the database.
class Labels {
  Labels._();

  static const trades = {
    'Electrician': 'الیکٹریشن',
    'Plumber': 'پلمبر',
    'Mason': 'راج مستری',
    'Carpenter': 'بڑھئی',
    'Painter': 'پینٹر',
    'AC Technician': 'اے سی ٹیکنیشن',
  };

  static const areas = {
    'Model Town A': 'ماڈل ٹاؤن اے',
    'Model Town B': 'ماڈل ٹاؤن بی',
    'Satellite Town': 'سیٹلائٹ ٹاؤن',
    'One Unit Staff Colony': 'ون یونٹ اسٹاف کالونی',
    'Dubai Mahal Road': 'دبئی محل روڈ',
    'University Town': 'یونیورسٹی ٹاؤن',
    'Cantonment': 'کینٹ',
    'Farid Gate': 'فرید گیٹ',
    'Trust Colony': 'ٹرسٹ کالونی',
    'Commercial Area': 'کمرشل ایریا',
  };

  static const urgencies = {
    'Today': 'آج',
    'Tomorrow': 'کل',
    'Any Day': 'کسی بھی دن',
  };

  static const statuses = {
    'Active': 'جاری',
    'Completed': 'مکمل',
    'Closed': 'بند',
  };

  static const reviewTags = {
    'On time': 'وقت کے پابند',
    'Clean work': 'صاف ستھرا کام',
    'Fair price': 'مناسب قیمت',
    'Polite': 'خوش اخلاق',
    'Skilled': 'ماہر',
    'Explained well': 'اچھی طرح سمجھایا',
  };
}

extension LabelsContext on BuildContext {
  String tradeName(String value) =>
      isUrdu ? (Labels.trades[value] ?? value) : value;

  String areaName(String value) =>
      isUrdu ? (Labels.areas[value] ?? value) : value;

  String urgencyName(String value) =>
      isUrdu ? (Labels.urgencies[value] ?? value) : value;

  String statusName(String value) =>
      isUrdu ? (Labels.statuses[value] ?? value) : value;

  String tagName(String value) =>
      isUrdu ? (Labels.reviewTags[value] ?? value) : value;

  /// "Rs. 300" / "300 روپے", or "Free visit" when [amount] is 0.
  String visitFee(int amount) {
    if (amount == 0) return tr('Free visit', 'مفت وزٹ');
    return tr('Rs. $amount', '$amount روپے');
  }

  String yearsExperience(int years) =>
      tr('$years yrs exp', '$years سال تجربہ');

  /// Distance in km with one decimal, or metres when close.
  String distance(double km) {
    if (km < 1) {
      final metres = (km * 1000).round();
      return tr('$metres m away', '$metres میٹر دور');
    }
    final value = km.toStringAsFixed(1);
    return tr('$value km away', '$value کلومیٹر دور');
  }
}
