# HouseBusiness

This is a Flutter and Firebase app for buying and selling homes. Sellers post listings with photos. Buyers search with filters, save homes, compare up to 3 side by side, message the seller, and book a time to see the house. Each listing also shows similar homes nearby so buyers can tell if the price makes sense.

Made by Kirtan Patel (solo, undergraduate track). Topic is PropertyPulse (House Marketplace).

## What the app does

* Log in, sign up, and reset your password with email (Firebase Auth)
* Continue with Google on the login and sign up screens. Closing the Google picker just takes you back with no error
* Splash screen checks if you are already logged in and skips the login screen if you are
* Friendly error messages for wrong password, used email, weak password, and no internet
* Wrong password and unknown email show the same message, so nobody can check who has an account
* New users pick buyer or seller, add their name, and can add a photo and phone. The role can't be changed later
* Email and phone are saved in `users/{uid}/private/contact` so only the owner can see them
* Only sellers see "My listings" on the Profile tab
* Sellers can make a listing with title, type, price, beds, baths, sq ft, year built, lot size, address, amenities, and a description. They can save it as a draft or publish it
* Sq ft, year built, lot size, and street address are optional. The form checks everything else before saving
* The address is turned into a map spot with the phone's geocoder. If it can't be found, the listing still saves with just the city and ZIP
* Editing only looks up the map spot again if the address changed
* If there is no internet, the listing is kept on the phone and uploads later, and the app says so
* Leaving the form with unsaved changes asks first
* More features coming as I build them

## How to run

* `flutter pub get`
* `flutter run`
* `flutter test`
* Rules tests (needs Node and Java 21): `cd rules_test`, `npm install`, then `npm test`. This starts the Firestore and Storage emulators, runs the tests, and shuts them down
* For the APK: `flutter build apk --release`

## Firebase setup

* Turn on Email/Password and Google in Authentication
* Add your debug SHA-1 to the Android app in Project settings (needed for Google sign in)
* Deploy the rules: `firebase deploy --only firestore:rules,storage`

## Security rules

All of these are in `firestore.rules` and `storage.rules`.

* You can only edit your own profile, and your buyer or seller role can't change after signup
* Your email and phone are only visible to you. Buyers and sellers talk through the app chat
* Only sellers can make listings, and only the owner can edit one. Listings get archived, never deleted
* Buyers only see published listings. Drafts are only visible to the seller
* Only the two people in a chat can read it or send messages, and a blocked user can't send
* Messages can't be edited or deleted
* Viewings can only be booked by a Cloud Function, so two people can't grab the same time slot
* A buyer can cancel a viewing. A seller can confirm, decline, or cancel. Nothing else can change
* Photos must be images under 5 MB, and only the owner can upload them
* There are 56 tests for these rules in `rules_test/`. They check that the allowed things work and the blocked things really get blocked, like a buyer making a listing, someone outside a chat reading it, or a buyer booking a slot directly

## Firestore indexes

These are in `firestore.indexes.json`.

* Browse feed: status + newest first
* Search: status + city + type + price, and status + city + price
* Search by ZIP: status + ZIP + beds
* My listings: seller + last updated
* Chats: my chats + newest message
* Viewings: buyer or seller + newest first

## Files

* `lib/main.dart` - starts Firebase and the app
* `lib/core/router.dart` - all the routes and the 5 bottom tabs
* `lib/core/theme.dart` - colors and the app look
* `lib/models/` - the user and listing data
* `lib/data/` - talks to Firebase (auth, users, listings) and the geocoder
* `lib/features/` - one folder per part of the app (auth, browse, listing, saved, messages, viewings, seller, profile)
* `rules_test/` - security rules tests that run in the Firebase emulator
* `docs/` - proposal and wireframes

## Known limitations

* Coming soon
