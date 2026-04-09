import 'package:folio_kreta_api/models/subject.dart';

class SubjectAverage {
  String uid;
  double average;
  GradeSubject subject;
  int sortIndex;
  Map json;

  SubjectAverage({
    required this.uid,
    required this.average,
    required this.subject,
    required this.sortIndex,
    this.json = const {},
  });

  factory SubjectAverage.fromJson(Map json) {
    return SubjectAverage(
      uid: json["Uid"]?.toString() ?? "",
      average: (json["Atlag"] as num?)?.toDouble() ?? 0.0,
      subject: GradeSubject.fromJson(json["Tantargy"] ?? {}),
      sortIndex: json["SortIndex"] ?? 0,
      json: json,
    );
  }
}
