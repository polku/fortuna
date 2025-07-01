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

The bottom navigation lets you access three pages:

1. **Portfolio** – displays the total value of your holdings and lists each position (current values are assumed to be 100 € per unit).
2. **Add** – enter a new buy operation (ISIN, date, quantity and unit price) which is saved locally.
3. **Operations** – shows the history of saved operations.

Existing installations are automatically migrated so that previously saved
operations receive a quantity of `1`.
