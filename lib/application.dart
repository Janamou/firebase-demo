library firebase_demo.app;

import 'dart:html';
import 'package:firebase/firebase.dart' as fb;
import 'package:firebase_demo/note.dart';

class Application {
  final fb.Auth auth;
  final fb.DatabaseReference databaseRef;
  final fb.StorageReference storageRef;

  final DivElement notes;
  final InputElement newNoteTitle;
  final TextAreaElement newNote;
  final InputElement submit;
  final InputElement upload;
  final FormElement form;
  final LIElement login;
  final LIElement profile;
  final DivElement template;
  final DivElement spinner;

  Application()
      : auth = fb.auth(),
        databaseRef = fb.database().ref("notes"),
        storageRef = fb.storage().ref("notes"),
        notes = querySelector("#notes"),
        newNoteTitle = querySelector("#new-note-title"),
        newNote = querySelector("#new-note"),
        upload = querySelector("#upload-image"),
        submit = querySelector("#submit"),
        form = querySelector("#notes-form"),
        login = querySelector("#login"),
        profile = querySelector("#profile"),
        template = querySelector("#card-template"),
        spinner = querySelector(".mdl-spinner") {
    newNoteTitle.disabled = false;
    newNote.disabled = false;
    submit.disabled = false;
    upload.disabled = false;

    spinner.classes.add("is-active");

    _setElementListeners();
    _setAuthListener();
  }

  void setupItems() {
    // Setups listening on the child_added event on the database ref.
    databaseRef.onChildAdded.listen((e) {
      // Snapshot of the data.
      fb.DataSnapshot data = e.snapshot;

      // Value of data from snapshot.
      var val = data.val();
      // Creates a new Note item. It is possible to retrieve a key from data.
      var item = new Note(
          val[jsonTagText], val[jsonTagTitle], val[jsonTagImgUrl], data.key);
      _showItem(item);
    });

    // Setups listening on the value event on the database ref.
    databaseRef.onValue.listen((e) {
      spinner.classes.remove("is-active");
    });

    // Setups listening on the child_removed event on the database ref.
    databaseRef.onChildRemoved.listen((e) {
      fb.DataSnapshot data = e.snapshot;
      var val = data.val();

      // Removes also the image from storage.
      var imageUrl = val[jsonTagImgUrl];
      if (imageUrl != null) {
        removeItemImage(imageUrl);
      }

      _clearItem(data.key);
    });
  }

  // Pushes a new item as a Map to database.
  postItem(Note item) async {
    try {
      await databaseRef.push(Note.toMap(item)).future;
      _resetForm();
    } catch (e) {
      print("Error in writing to database: $e");
    }
  }

  // Removes item with a key from database.
  removeItem(String key) async {
    try {
      await databaseRef.child(key).remove();
    } catch (e) {
      print("Error in deleting $key: $e");
    }
  }

  // Puts image into a storage.
  postItemImage(File file) async {
    try {
      var snapshot = await storageRef.child(file.name).put(file).future;
      _showUploadImage(snapshot.downloadURL);
    } catch (e) {
      print("Error in uploading to database: $e");
    }
  }

  // Removes image with an imageUrl from the storage.
  removeItemImage(String imageUrl) async {
    try {
      var imageRef = fb.storage().refFromURL(imageUrl);
      await imageRef.delete();
    } catch (e) {
      print("Error in deleting $imageUrl: $e");
    }
  }

  // Logins with the Google auth provider.
  loginWithGoogle() async {
    var provider = new fb.GoogleAuthProvider();
    try {
      await auth.signInWithPopup(provider);
    } catch (e) {
      print("Error in sign in with google: $e");
    }
  }

  void _setElementListeners() {
    // Upload image button listener.
    upload.onChange.listen((e) async {
      e.preventDefault();
      spinner.classes.add("is-active");
      submit.disabled = true;
      var file = (e.target as FileUploadInputElement).files[0];
      postItemImage(file);
    });

    // Form submit listener.
    form.onSubmit.listen((e) {
      e.preventDefault();
      var text = newNote.value.trim();
      var title = newNoteTitle.value.trim();
      if (text.isNotEmpty) {
        var imgElement = querySelector("#actual-image");
        var imgUrl;
        if (imgElement != null) {
          imgUrl = imgElement.getAttribute("src");
        }
        var item = new Note(text, title, imgUrl);
        postItem(item);
      } else {
        var errorParagraph = new ParagraphElement()
          ..classes.add("error")
          ..text = "Please fill the note text.";
        newNote.style.borderColor = "red";
        newNote.parent.append(errorParagraph);
      }
      submit.blur();
    });

    var loginAnchor = login.querySelector("a");
    // Login button listener.
    loginAnchor.onClick.listen((e) async {
      e.preventDefault();
      loginWithGoogle();
    });
  }

  // Sets the auth event listener.
  _setAuthListener() {
    // When the state of auth changes (user logs in/logs out).
    auth.onAuthStateChanged.listen((e) {
      var user = e.user;
      _clearProfile();

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
      }
    });
  }

  _showItem(Note item) {
    HtmlElement card = template.clone(true);
    card.style.display = "block";
    card.id = "note-${item.key}";

    var cardContentElement = card.querySelector(".note-text");
    cardContentElement.querySelector("p").text = item.text;

    if (item.title.isNotEmpty) {
      var cardTitleElement = new HeadingElement.h3()..text = item.title;
      cardContentElement.insertBefore(
          cardTitleElement, cardContentElement.firstChild);
    }

    var removeElement = card.querySelector(".note-remove")
      ..onClick.listen((e) {
        e.preventDefault();
        removeItem(item.key);
      });

    if (auth.currentUser == null) {
      removeElement.style.display = "none";
    }

    if (item.imageUrl != null) {
      var imgElement = new ImageElement(src: item.imageUrl);
      cardContentElement.append(imgElement);
    }

    notes.insertBefore(card, notes.firstChild);
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

  _clearProfile() {
    while (profile.firstChild != null) {
      profile.firstChild.remove();
    }
  }

  _showUploadImage(Uri url) {
    upload.style.display = "none";
    var containerElement = new DivElement()..id = "actual-image-container";

    var imgElement = new ImageElement(src: url.toString(), width: 200)
      ..id = "actual-image";

    var removeElement = new AnchorElement(href: "#")
      ..id = "actual-image-remove"
      ..title = "Remove image"
      ..onClick.listen((e) {
        e.preventDefault();
        removeItemImage(imgElement.src);
        _removeUploadImage();
      });

    var iconElement = new SpanElement()
      ..classes.add("material-icons")
      ..text = "delete";

    removeElement.append(iconElement);

    containerElement.append(imgElement);
    containerElement.append(removeElement);

    var imgColumn = querySelector("#note-image");
    imgColumn.append(containerElement);

    spinner.classes.remove("is-active");
    submit.disabled = false;
  }

  _removeUploadImage() {
    upload.value = "";
    upload.style.display = "block";
    var imgElement = querySelector("#actual-image-container");
    imgElement?.remove();
  }

  _resetForm() {
    newNote.value = "";
    newNoteTitle.value = "";
    newNote.style.removeProperty("border-color");
    var errorElement = querySelector(".error");
    errorElement?.remove();
    _removeUploadImage();
  }

  _clearItem(String key) {
    querySelector("#note-$key").remove();
  }
}
