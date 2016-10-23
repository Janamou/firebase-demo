import 'package:firebase3/firebase.dart';
import 'package:firebase_demo/application.dart';

void main() {
  initializeApp(
      apiKey: "TODO",
      authDomain: "TODO",
      databaseURL: "TODO",
      storageBucket: "TODO");

  new Application().setupItems();
}
