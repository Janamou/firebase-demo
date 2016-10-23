library firebase_demo.item;

const String jsonTagText = "text";
const String jsonTagDone = "done";
const String jsonTagImgUrl = "img_url";

class Note {
  String key;
  String text;
  String imageUrl;

  Note(this.text, [this.imageUrl, this.key]);

  static Map toMap(Note item) {
    Map jsonMap = {
      jsonTagText: item.text,
      jsonTagImgUrl: item.imageUrl
    };
    return jsonMap;
  }
}
