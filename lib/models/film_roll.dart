import 'dart:io';

class FilmRoll {
  final String id;
  final String name;
  final DateTime date;
  final List<File> photos;

  FilmRoll({
    required this.id,
    required this.name,
    required this.date,
    required this.photos,
  });

  factory FilmRoll.fromJson(Map<String, dynamic> json, String id, List<File> photos) {
    return FilmRoll(
      id: id,
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      photos: photos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date.toIso8601String(),
    };
  }

  File? get previewPhoto => photos.isNotEmpty ? photos.first : null;
}
