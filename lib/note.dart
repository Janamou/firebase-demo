library firebase_demo.item;

const String jsonTagText = "text";
const String jsonTagTitle = "title";
const String jsonTagImgUrl = "img_url";

class Note {
  String key;
  String text;
  String title;
  String imageUrl;

  Note(this.text, [this.title, this.imageUrl, this.key]);

  static Map toMap(Note item) {
    Map jsonMap = {
      jsonTagText: item.text,
      jsonTagTitle: item.title,
      jsonTagImgUrl: item.imageUrl
    };
    return jsonMap;
  }
}
