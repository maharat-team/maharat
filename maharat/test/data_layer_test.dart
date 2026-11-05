import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maharat/core/config/env.dart';
import 'package:maharat/core/utils/date_utils.dart';
import 'package:maharat/core/utils/image_compressor.dart';
import 'package:maharat/core/utils/phone_utils.dart';
import 'package:maharat/models/job_request_model.dart';
import 'package:maharat/models/user_profile_model.dart';
import 'package:maharat/models/worker_model.dart';

Map<String, dynamic> workerRow({
  String id = 'w1',
  List<Map<String, dynamic>> photos = const [],
  List<Map<String, dynamic>> reviews = const [],
}) => {
  'id': id,
  'full_name': 'Tariq',
  'trade': 'Electrician',
  'phone': '+923001234567',
  'rating_avg': 4.5,
  'review_count': 2,
  'experience_years': 8,
  'visit_fee': 300,
  'neighbourhood': 'Model Town A',
  'service_areas': ['Model Town A'],
  'bio': 'bio',
  'verification_status': 'approved',
  'is_available_today': true,
  'completed_jobs_count': 3,
  'worker_photos': photos,
  'reviews': reviews,
};

Map<String, dynamic> jobRow({Object? reviews, List<dynamic>? interests}) => {
  'id': 'j1',
  'customer_id': 'c1',
  'customer_name': 'Ahmed',
  'trade': 'Plumber',
  'description': 'leak',
  'location': 'Model Town A',
  'urgency': 'any_day',
  'status': 'completed',
  'photo_paths': ['c1/a.jpg'],
  'assigned_worker_id': 'w1',
  'created_at': '2026-11-01T10:00:00+00:00',
  'job_interests': interests ?? [],
  'reviews': reviews,
};

WorkerModel parseWorker(Map<String, dynamic> json) =>
    WorkerModel.fromJson(json, photoUrl: (path) => 'https://cdn/$path');

void main() {
  group('models', () {
    test('worker parses, newest photos and reviews first', () {
      final worker = parseWorker(
        workerRow(
          photos: [
            {
              'id': 'p1',
              'storage_path': 'w1/old.jpg',
              'created_at': '2026-01-01',
            },
            {
              'id': 'p2',
              'storage_path': 'w1/new.jpg',
              'created_at': '2026-06-01',
            },
          ],
          reviews: [
            {
              'id': 'r1',
              'customer_name': 'Ali',
              'rating': 4,
              'comment': 'ok',
              'tags': ['Skilled'],
              'created_at': '2026-02-01T00:00:00+00:00',
            },
          ],
        ),
      );

      expect(worker.rating, 4.5);
      expect(worker.isCnicVerified, isTrue);
      expect(worker.workPhotos.first.url, 'https://cdn/w1/new.jpg');
      expect(worker.reviews.single.rating, 4.0);
    });

    test('only an approved worker counts as verified', () {
      final row = workerRow()..['verification_status'] = 'pending';
      expect(parseWorker(row).isCnicVerified, isFalse);
    });

    test('job maps database values to the labels the UI uses', () {
      final job = JobRequestModel.fromJson(jobRow(), parseWorker: parseWorker);

      expect(job.urgency, 'Any Day');
      expect(job.status, 'Completed');
      expect(job.photoPaths, ['c1/a.jpg']);
      expect(JobRequestModel.urgencyToDb('Any Day'), 'any_day');
    });

    test('job reads a review embedded as an object or a list', () {
      const review = {'rating': 5, 'comment': 'great'};
      final fromObject = JobRequestModel.fromJson(
        jobRow(reviews: review),
        parseWorker: parseWorker,
      );
      final fromList = JobRequestModel.fromJson(
        jobRow(reviews: [review]),
        parseWorker: parseWorker,
      );
      final none = JobRequestModel.fromJson(
        jobRow(reviews: const []),
        parseWorker: parseWorker,
      );

      expect(fromObject.ratingGiven, 5.0);
      expect(fromList.reviewComment, 'great');
      expect(none.ratingGiven, isNull);
    });

    test('job skips interested workers hidden by RLS', () {
      final job = JobRequestModel.fromJson(
        jobRow(
          interests: [
            {'created_at': '2026-01-01', 'workers': null},
            {'created_at': '2026-01-02', 'workers': workerRow()},
          ],
        ),
        parseWorker: parseWorker,
      );

      expect(job.interestedWorkers, hasLength(1));
      expect(job.assignedWorkerName, 'Tariq');
    });

    test('profile completeness needs name, phone and area', () {
      final blank = UserProfileModel.fromJson({
        'id': 'u',
        'full_name': '',
        'phone': null,
        'language': 'English',
        'active_role': 'customer',
        'neighbourhood': '',
      });

      expect(blank.isComplete, isFalse);
      expect(
        blank
            .copyWith(
              name: 'A',
              phone: '+923001234567',
              neighbourhood: 'Model Town A',
            )
            .isComplete,
        isTrue,
      );
    });
  });

  group('client configuration', () {
    const url = 'https://abc.supabase.co';
    const key = 'sb_publishable_abc';

    test('accepts real values', () {
      expect(Env.findProblem(url, key), isNull);
    });

    test('rejects missing values', () {
      expect(Env.findProblem('', key), contains('not configured'));
      expect(Env.findProblem(url, ''), contains('not configured'));
    });

    test('rejects the values from env.example.json', () {
      expect(
        Env.findProblem(
          'https://your-project-ref.supabase.co',
          'sb_publishable_your_key_here',
        ),
        contains('placeholder'),
      );
    });

    test('rejects a secret key', () {
      expect(Env.findProblem(url, 'sb_secret_abc'), contains('secret'));
    });
  });

  group('phone numbers', () {
    test('common formats normalise to +92', () {
      for (final input in [
        '03001234567',
        '3001234567',
        '923001234567',
        '+92 300 1234567',
        '0300-1234567',
      ]) {
        expect(PhoneUtils.normalize(input), '+923001234567', reason: input);
      }
    });

    test('non-mobile input is rejected', () {
      for (final input in ['', '12345', '0421234567', '030012345678']) {
        expect(PhoneUtils.normalize(input), isNull, reason: input);
      }
    });
  });

  test('relative dates', () {
    final now = DateTime(2026, 11, 5, 12);
    expect(
      relativeDate(now.subtract(const Duration(minutes: 5)), now: now),
      'Just now',
    );
    expect(
      relativeDate(now.subtract(const Duration(days: 1)), now: now),
      'Yesterday',
    );
    expect(
      relativeDate(now.subtract(const Duration(days: 4)), now: now),
      '4 days ago',
    );
    expect(
      relativeDate(now.subtract(const Duration(days: 21)), now: now),
      '3 weeks ago',
    );
  });

  group('image compression', () {
    /// Noise is hard to compress, so it is a worst-case photo.
    img.Image noise(int width, int height, {int channels = 3}) {
      final image = img.Image(
        width: width,
        height: height,
        numChannels: channels,
      );
      var seed = 42;
      for (final pixel in image) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        pixel
          ..r = seed & 255
          ..g = (seed >> 8) & 255
          ..b = (seed >> 16) & 255;
        if (channels == 4) pixel.a = 255;
      }
      return image;
    }

    test('resizes large photos and keeps the aspect ratio', () async {
      final source = Uint8List.fromList(
        img.encodeJpg(noise(3000, 1500), quality: 100),
      );

      final output = await ImageCompressor.compress(source);
      final decoded = img.decodeJpg(output)!;

      expect(decoded.width, ImageCompressor.defaultMaxDimension);
      expect(decoded.height, ImageCompressor.defaultMaxDimension ~/ 2);
      expect(output.length, lessThan(source.length));
    });

    test('never enlarges small photos', () async {
      final source = Uint8List.fromList(img.encodeJpg(noise(300, 200)));

      final decoded = img.decodeJpg(await ImageCompressor.compress(source))!;

      expect(decoded.width, 300);
    });

    test('lowers quality to reach the size budget', () async {
      final source = Uint8List.fromList(
        img.encodeJpg(noise(800, 800), quality: 100),
      );
      const budget = 200 * 1024;

      final output = await ImageCompressor.compress(source, maxBytes: budget);

      final highQuality = img.encodeJpg(noise(800, 800), quality: 82);
      expect(output.length, lessThan(highQuality.length));
    });

    test('removes EXIF, including GPS', () async {
      final image = noise(200, 200);
      image.exif.gpsIfd['GPSLatitude'] = img.IfdValueAscii('29.39');
      image.exif.imageIfd['Make'] = img.IfdValueAscii('TestCam');
      final source = Uint8List.fromList(img.encodeJpg(image));
      expect(img.decodeJpg(source)!.exif.isEmpty, isFalse);

      final output = await ImageCompressor.compress(source);

      expect(img.decodeJpg(output)!.exif.isEmpty, isTrue);
    });

    test('always outputs JPEG, flattening transparency onto white', () async {
      final transparent = img.Image(width: 50, height: 50, numChannels: 4);
      final source = Uint8List.fromList(img.encodePng(transparent));

      final output = await ImageCompressor.compress(source);
      final pixel = img.decodeJpg(output)!.getPixel(25, 25);

      expect(output.sublist(0, 2), [0xFF, 0xD8]);
      expect(pixel.r, greaterThan(250));
    });

    test('rejects files that are not images', () async {
      await expectLater(
        ImageCompressor.compress(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(isA<ImageCompressionException>()),
      );
    });
  });
}
