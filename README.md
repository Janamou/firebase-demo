# Dart + Firebase = ♥ demo

Demo app for the Dart Dev Summit 2016. The application is written in Dart and uses the [Firebase3 library](https://github.com/Janamou/firebase3-dart/).

![Dart + Firebase App](https://github.com/Janamou/firebase-demo/blob/master/dartsummit-demo.png)

## Before running

### Your credentials

Before running the app, update the `web/main.dart` file with your Firebase project's credentials:

```dart
initializeApp(
      apiKey: "TODO",
      authDomain: "TODO",
      databaseURL: "TODO",
      storageBucket: "TODO");
```

### Google login

Enable Google login in Firebase console under the `Authentication/Sign-in method`.

### Database rules

Set database rules on who can access the database under the `Database/Rules`. More info on [Database rules](https://firebase.google.com/docs/database/security/).

### Storage rules

Set storage rules on who can access the storage under the `Storage/Rules`. More info on [Storage rules](https://firebase.google.com/docs/storage/security/).
