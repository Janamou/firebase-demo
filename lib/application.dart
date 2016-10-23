library firebase_demo.app;

import 'dart:html';
import 'package:firebase3/firebase.dart' as fb;
import 'package:firebase_demo/note.dart';

class Application {
  final fb.Auth auth;
  final fb.DatabaseReference databaseRef;
  final fb.StorageReference storageRef;

  final DivElement container;
  final InputElement newNote;
  final InputElement submit;
  final InputElement upload;
  final FormElement form;
  final AnchorElement login;
  final DivElement profile;

  Application()
      : auth = fb.auth(),
        databaseRef = fb.database().ref("notes"),
        storageRef = fb.storage().ref("notes"),
        container = querySelector("#notes"),
        newNote = querySelector("#new_note"),
        upload = querySelector("#upload_image"),
        submit = querySelector("#submit"),
        form = querySelector("#notes_form"),
        login = querySelector("#login"),
        profile = querySelector("#profile") {
    newNote.disabled = false;
    submit.disabled = false;
    upload.disabled = false;

    _setElementListeners();

    if (auth.currentUser != null) {
      form.style.display = "block";
    }
  }

  void _setElementListeners() {
    upload.onChange.listen((e) async {
      e.preventDefault();
      newNote.disabled = true;
      var file = (e.target as FileUploadInputElement).files[0];

      try {
        var snapshot = await storageRef.child(file.name).put(file).future;
        _showUploadImage(snapshot.downloadURL);
        newNote.disabled = false;
      } catch (e) {
        print("Error in uploading to database: $e");
      }
    });

    form.onSubmit.listen((e) {
      e.preventDefault();
      var text = newNote.value.trim();
      if (text.isNotEmpty) {
        var imgElement = querySelector("#note-image");
        var imgUrl;
        if (imgElement != null) {
          imgUrl = imgElement.getAttribute("src");
        }
        var item = new Note(text, imgUrl);
        postItem(item);
      }
    });

    login.onClick.listen((e) async {
      e.preventDefault();
      var provider = new fb.GoogleAuthProvider();
      try {
        await auth.signInWithPopup(provider);
      } catch (e) {
        print("Error in sign in with google: $e");
      }
    });

    auth.onAuthStateChanged.listen((e) {
      var user = e.user;
      if (user != null) {
        login.style.display = "none";
        profile.style.display = "block";
        form.style.display = "block";
        querySelectorAll(".note-remove").style.display = "block";
        _showProfile(user);
      } else {
        login.style.display = "block";
        profile.style.display = "none";
        form.style.display = "none";
        querySelectorAll(".note-remove").style.display = "none";

        while (profile.firstChild != null) {
          profile.firstChild.remove();
        }
      }
    });
  }

  void setupItems() {
    databaseRef.onChildAdded.listen((e) {
      fb.DataSnapshot data = e.snapshot;

      var val = data.val();
      var item = new Note(val[jsonTagText], val[jsonTagImgUrl], data.key);
      _showItem(item);
    });

    databaseRef.onChildRemoved.listen((e) {
      fb.DataSnapshot data = e.snapshot;
      var val = data.val();

      var imageUrl = val[jsonTagImgUrl];
      if (imageUrl != null) {
        removeImage(imageUrl);
      }

      _clearItem(data.key);
    });
  }

  postItem(Note item) async {
    try {
      await databaseRef.push(Note.toMap(item)).future;
      _resetForm();
    } catch (e) {
      print("Error in writing to database: $e");
    }
  }

  removeItem(String key) async {
    try {
      await databaseRef.child(key).remove();
    } catch (e) {
      print("Error in deleting $key: $e");
    }
  }

  removeImage(String imageUrl) async {
    try {
      var imageRef = fb.storage().refFromURL(imageUrl);
      await imageRef.delete();
    } catch (e) {
      print("Error in deleting $imageUrl: $e");
    }
  }

  _showItem(Note item) {
    var element = new DivElement()
      ..classes.add("note-item")
      ..text = item.text;

    var removeElement = new AnchorElement(href: "#")
      ..classes.add("note-remove")
      ..text = "Remove"
      ..onClick.listen((e) {
        e.preventDefault();
        removeItem(item.key);
      });

    if (auth.currentUser == null) {
      removeElement.style.display = "none";
    }

    element.append(removeElement);

    if (item.imageUrl != null) {
      var imgElement = new ImageElement(src: item.imageUrl, width: 200);
      element.append(imgElement);
    }

    container.insertBefore(element, container.firstChild);
  }

  _showProfile(fb.User user) {
    if (user.photoURL != null) {
      var imgElement =
          new ImageElement(src: user.photoURL, width: 40, height: 40);
      profile.append(imgElement);
    }

    var nameElement = new ParagraphElement()
      ..text = "${user.displayName} (${user.email})";
    profile.append(nameElement);

    var logoutElement = new AnchorElement(href: "#")
      ..text = "Sign out"
      ..onClick.listen((e) {
        e.preventDefault();
        auth.signOut();
      });

    profile.append(logoutElement);
  }

  _showUploadImage(String url) {
    upload.style.display = "none";
    var imgElement = new ImageElement(src: url, width: 200)..id = "note-image";
    form.append(imgElement);
  }

  _resetForm() {
    newNote.value = "";
    upload.value = "";
    upload.style.display = "block";
    var imgElement = querySelector("#note-image");
    imgElement?.remove();
  }

  _clearItem(String key) {
    querySelector("#note-$key").remove();
  }
}
