import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/l10n.dart';

/// Urdu for the messages our database functions raise (error code P0001).
const _databaseMessagesUrdu = {
  'Please sign in again.': 'براہ کرم دوبارہ سائن ان کریں۔',
  'Please complete your profile first.': 'براہ کرم پہلے اپنی پروفائل مکمل کریں۔',
  'Please complete your profile before posting a job.':
      'کام پوسٹ کرنے سے پہلے اپنی پروفائل مکمل کریں۔',
  'Invalid document upload.': 'دستاویز درست طریقے سے اپ لوڈ نہیں ہوئی۔',
  'Invalid photo attachment.': 'تصویر درست نہیں ہے۔',
  'Invalid photo path.': 'تصویر درست نہیں ہے۔',
  'Your application has already been submitted.':
      'آپ کی درخواست پہلے ہی جمع ہو چکی ہے۔',
  'This CNIC is already registered.': 'یہ شناختی کارڈ پہلے سے رجسٹرڈ ہے۔',
  'Too many attempts today. Please try again tomorrow.':
      'آج بہت زیادہ کوششیں ہو چکی ہیں۔ براہ کرم کل دوبارہ کوشش کریں۔',
  'This job is already finished.': 'یہ کام پہلے ہی ختم ہو چکا ہے۔',
  'Choose a worker who responded to this job.':
      'وہ کاریگر منتخب کریں جس نے اس کام پر جواب دیا تھا۔',
  'A worker can only be assigned when completing a job.':
      'کاریگر صرف کام مکمل کرتے وقت منتخب کیا جا سکتا ہے۔',
  'The contractor has not assigned a worker to this job yet.':
      'ٹھیکیدار نے ابھی تک اس کام پر کوئی کاریگر نہیں بھیجا۔',
  'You cannot send an order to your own shop.':
      'آپ اپنی ہی دکان کو آرڈر نہیں بھیج سکتے۔',
  'This contractor is not taking orders right now.':
      'یہ ٹھیکیدار ابھی آرڈر نہیں لے رہا۔',
  'This order is no longer waiting for a reply.':
      'یہ آرڈر اب جواب کا منتظر نہیں ہے۔',
  'Choose at least one worker.': 'کم از کم ایک کاریگر منتخب کریں۔',
  'Accept this order before sending workers.':
      'کاریگر بھیجنے سے پہلے آرڈر قبول کریں۔',
  'Only members of your team can be sent.':
      'صرف آپ کی ٹیم کے ارکان بھیجے جا سکتے ہیں۔',
  'Your shop must be verified before you can build a team.':
      'ٹیم بنانے سے پہلے آپ کی دکان کی تصدیق ضروری ہے۔',
  'No verified worker found with this number.':
      'اس نمبر پر کوئی تصدیق شدہ کاریگر نہیں ملا۔',
  'This invitation is no longer available.': 'یہ دعوت اب دستیاب نہیں۔',
  'You can add up to 12 work photos. Remove one to add another.':
      'آپ زیادہ سے زیادہ 12 تصاویر لگا سکتے ہیں۔ نئی لگانے کے لیے ایک ہٹائیں۔',
};

/// Turns backend failures into text that is safe and useful to show a user.
String friendlyError(Object error) {
  // Users get the friendly text; developers need the real cause in the logs.
  if (!kReleaseMode) debugPrint('[error] ${error.runtimeType}: $error');

  final fallback = tr(
    'Something went wrong. Please try again.',
    'کچھ غلط ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔',
  );
  final offline = tr(
    'No internet connection. Please check it and try again.',
    'انٹرنیٹ کنکشن نہیں ہے۔ براہ کرم چیک کر کے دوبارہ کوشش کریں۔',
  );

  if (error is AuthException) {
    final code = error.code ?? '';
    if (error.statusCode == '429' || code.contains('rate_limit')) {
      return tr(
        'Too many attempts. Please wait a minute and try again.',
        'بہت زیادہ کوششیں۔ ایک منٹ انتظار کر کے دوبارہ کوشش کریں۔',
      );
    }
    if (code == 'otp_expired' || code == 'invalid_credentials') {
      return tr(
        'That code is wrong or has expired. Please try again.',
        'یہ کوڈ غلط ہے یا اس کی مدت ختم ہو گئی ہے۔ دوبارہ کوشش کریں۔',
      );
    }
    if (code == 'validation_failed' || code == 'email_address_invalid') {
      return tr(
        'Please enter a valid email address.',
        'براہ کرم درست ای میل ایڈریس درج کریں۔',
      );
    }
    if (error is AuthRetryableFetchException) return offline;
    return fallback;
  }
  if (error is PostgrestException) {
    // P0001 is raised by our own database functions with user-facing wording.
    if (error.code != 'P0001') return fallback;
    return AppLanguage.isUrdu
        ? (_databaseMessagesUrdu[error.message] ?? error.message)
        : error.message;
  }
  if (error is StorageException) {
    return tr(
      'The photo could not be uploaded. Please try again.',
      'تصویر اپ لوڈ نہیں ہو سکی۔ دوبارہ کوشش کریں۔',
    );
  }
  if (error is TimeoutException) return offline;
  if (error is FormatException) return error.message;

  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('Failed host lookup')) {
    return offline;
  }
  return fallback;
}
