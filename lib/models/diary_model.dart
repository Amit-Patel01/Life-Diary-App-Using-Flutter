import 'package:hive/hive.dart';

part 'diary_model.g.dart';

@HiveType(typeId: 0)
class DiaryEntry extends HiveObject {
  @HiveField(0)
  String date;

  @HiveField(1)
  String text;

  @HiveField(2)
  String? image;

  @HiveField(3)
  String? id;

  DiaryEntry({
    required this.date,
    required this.text,
    this.image,
    this.id,
  });

  Map<String, dynamic> toMap() {
    return {
      "date": date,
      "text": text,
      "image": image,
      "id": id,
    };
  }

  factory DiaryEntry.fromMap(Map<dynamic, dynamic> map) {
    return DiaryEntry(
      date: map["date"] ?? '',
      text: map["text"] ?? '',
      image: map["image"],
      id: map["id"],
    );
  }
}

