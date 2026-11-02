# Maharat

Maharat is a Flutter prototype for connecting customers with local tradespeople in Bahawalpur, Pakistan. Customers can find workers and submit service requests; workers can create a profile, manage availability, and respond to requests.

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
- Complete the CNIC verification flow shown in the prototype.
- Set job availability, view active requests, and indicate interest in a request.
- View a worker profile with ratings and reviews.

The app is focused on Bahawalpur. Its sample trades include electricians, plumbers, masons, carpenters, painters, and AC technicians.

## Technology

- Flutter and Dart (`^3.12.0` SDK constraint)
- Provider for app-wide in-memory state
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
		onboarding/                   Splash, language, role, and phone screens
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

```sh
flutter pub get
flutter run
```

To run on a specific target, supply its device ID:

```sh
flutter run -d <device-id>
```

### Validate the project

```sh
flutter analyze
flutter test
```

## App Flow and State

`main.dart` creates a `ChangeNotifierProvider` for `AppState` and starts the app at the splash route. The onboarding screens lead through language and user-role selection to the customer experience or worker registration. The customer area uses four tabs: Home, Find, Requests, and Profile. Worker registration leads to a dashboard for availability and active requests.

`AppState` owns the current profile, sample workers, and job requests. Screens update this state through methods such as `addJobRequest`, `closeJobRequest`, `completeJobRequest`, `addReviewToWorker`, and `workerRespondToJob`. The data models are in `lib/models/`; the app does not currently use a remote service or local database.

## Prototype Scope

This repository implements a UI prototype with sample data, not a production marketplace backend:

- State is held in memory and resets when the app restarts.
- Phone verification is simulated. The demo OTP is pre-filled as `4321`; there is no SMS delivery or identity verification service.
- Voice-note and photo attachment controls, worker verification uploads, and verification outcomes are simulated; they do not capture or upload real files.
- Worker discovery and request responses operate on local sample records. There is no server-side matching, messaging, or request notification service.
- The language choice is stored as a preference; it does not yet provide complete app-wide translations.

## Dependencies

Runtime and development dependencies are declared in [`pubspec.yaml`](pubspec.yaml). This app uses Flutter's Material widgets and the `provider`, `google_fonts`, `flutter_svg`, and `lucide_icons_flutter` packages, with `flutter_test` and `flutter_lints` for development.
