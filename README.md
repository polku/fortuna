# Fortuna

Mobile app to keep an eye on investments.

Made with Flutter. All data is stored locally using SQLite.

## Getting Started

1. Ensure Flutter is installed on your machine.
2. Run `flutter pub get` to install dependencies.
3. Launch the app with `flutter run`.

To test on a simulator or device:

1. Create or start an Android emulator using Android Studio or the `flutter emulators` command.
2. Verify it appears with `flutter devices`.
3. Run `flutter run` again to launch the app on that device.

The current implementation allows you to add a buy operation (ISIN, date, unit value) which is saved to a local SQLite database.
