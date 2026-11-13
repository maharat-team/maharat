# Maharat

Maharat is a Flutter app, backed by Supabase, for connecting customers with local tradespeople in Bahawalpur, Pakistan. Customers can find workers and submit service requests; workers can create a profile, manage availability, and respond to requests.

## Features

### Customer experience

- Choose English, Urdu, or Roman Urdu as a language preference.
- Browse worker profiles by trade, neighbourhood, rating, and availability, and sort by rating, experience, or visit fee.
- Review worker experience, service areas, verification status, ratings, and reviews.
- Submit a job request with a trade, description, neighbourhood, and urgency.
- View active, completed, and closed requests; close active requests and rate completed work.
- Edit basic profile details and neighbourhood.

### Worker experience

- Register a trade, experience, visit fee, service areas, and profile description.
- Submit CNIC photos for review. Workers appear in search once approved.
- Upload and manage a gallery of work photos.
- Set job availability, view active requests, and indicate interest in a request.
- View a worker profile with ratings and reviews.

The app is focused on Bahawalpur. Its sample trades include electricians, plumbers, masons, carpenters, painters, and AC technicians.

## Technology

- Flutter and Dart (`^3.12.0` SDK constraint)
- Provider for app-wide state
- Supabase for auth, Postgres, Storage, and Realtime
- Material 3, with Google Fonts, Flutter SVG, and Lucide icons among the UI dependencies

## Project Structure

```text
lib/
	main.dart                       App entry point and provider setup
	core/
		constants/                    Trade categories and Bahawalpur areas
		theme/                        Colors, typography, and application theme
		widgets/                      Shared buttons, fields, and marketplace widgets
	features/
		onboarding/                   Splash, language, role, email sign-in, and profile setup
		customer/                     Home, worker search, profiles, requests, reviews
		worker/                       Registration, dashboard, and worker profile
	models/                         User, worker, job request, and review models
	routes/                         Named routes for the main app flows
	state/                          AppState and marketplace actions
test/
	widget_test.dart                Application smoke test
```

Platform-specific Flutter projects are present in `android/`, `ios/`, `web/`, `windows/`, `macos/`, and `linux/`.

## Getting Started

### Requirements

- Flutter SDK compatible with the Dart SDK constraint in `pubspec.yaml`
- A configured Flutter target, such as an Android emulator or connected device

Check your Flutter installation and available targets with:

```sh
flutter doctor
flutter devices
```

### Run the app

From the project root:

Copy `maharat/env.example.json` to `maharat/env.json`, then replace both placeholder values with your project URL and publishable key. The app stops at startup if they are left unchanged. Never put the secret key in this file.

```sh
cd maharat
flutter pub get
flutter run --dart-define-from-file=env.json
```

To run on a specific target, supply its device ID:

```sh
flutter run -d <device-id> --dart-define-from-file=env.json
```

### Validate the project

```sh
flutter analyze
flutter test
```

## Backend Setup

Migrations, Resend SMTP, email templates, and worker approval are covered in [`supabase/README.md`](supabase/README.md).

## App Flow and State

`main.dart` initialises Supabase, then starts at the splash route, which restores any saved session and routes the user. New users pass through language, role, email code, and profile setup.

Screens read and update `AppState`, which calls the services in `lib/services/`. The Supabase client is created only in `lib/core/config/supabase_config.dart`. Tests replace the services with the fakes in `test/fixtures/fake_backend.dart`.

## Current Limits

- Worker approval is manual, using the SQL in `supabase/README.md`.
- There are no push notifications. The Interested Workers list updates live while the app is open.
- The language choice is stored as a preference; it does not yet provide complete app-wide translations.

## Dependencies

Runtime and development dependencies are declared in [`pubspec.yaml`](pubspec.yaml). This app uses Flutter's Material widgets and the `supabase_flutter`, `provider`, `image_picker`, `image`, `url_launcher`, `google_fonts`, `flutter_svg`, and `lucide_icons_flutter` packages, with `flutter_test` and `flutter_lints` for development.
