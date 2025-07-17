import 'dart:convert';

LocationModel locationModelFromJson(String str) =>
    LocationModel.fromJson(json.decode(str));

class LocationModel {
  String name;
  String id;
  String text;
  LocationModel({
    required this.name,
    required this.text,
    required this.id,
  });
  factory LocationModel.empty({String name = ""}) =>
      LocationModel(name: name, id: "", text: "");
  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
        id: json["id"],
        name: json["name"],
        text: json["text"],
      );
  Map<String, dynamic> toJson() => {
        "name": name,
        "text": text,
        "id": id,
      };
}
