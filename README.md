# HouseBusiness

This is a Flutter and Firebase app for buying and selling homes. Sellers post listings with photos. Buyers search with filters, save homes, compare up to 3 side by side, message the seller, and book a time to see the house. Each listing also shows similar homes nearby so buyers can tell if the price makes sense.

Made by Kirtan Patel (solo, undergraduate track). Topic is PropertyPulse (House Marketplace).

## What the app does

* Log in, sign up, and reset your password with email (Firebase Auth)
* Continue with Google on the login and sign up screens. Closing the Google picker just takes you back with no error
* Splash screen checks if you are already logged in and skips the login screen if you are
* Friendly error messages for wrong password, used email, weak password, and no internet
* Wrong password and unknown email show the same message, so nobody can check who has an account
* More features coming as I build them

## How to run

* `flutter pub get`
* `flutter run`
* `flutter test`
* For the APK: `flutter build apk --release`

## Firebase setup

* Coming soon

## Files

* `lib/main.dart` - starts Firebase and the app
* `lib/core/router.dart` - all the routes and the 5 bottom tabs
* `lib/core/theme.dart` - colors and the app look
* `lib/features/` - one folder per part of the app (auth, browse, listing, saved, messages, viewings, seller, profile)
* `docs/` - proposal and wireframes

## Known limitations

* Coming soon
