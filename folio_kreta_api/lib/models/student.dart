import 'school.dart';
import 'package:folio/utils/format.dart';

class Student {
  Map? json;
  String id;
  String name;
  String? birthName;
  String? birthPlace;
  School school;
  DateTime birth;
  String yearId;
  String? address;
  String? groupId;
  String? mothersName;
  List<String> parents;
  int gradeDelay;
  String? bankAccountNumber;
  String? bankAccountOwnerName;
  int? bankAccountOwnerTypeId;
  bool bankAccountReadOnly;
  String? email;
  String? phone;
  String? className;

  Student({
    required this.id,
    required this.name,
    this.birthName,
    this.birthPlace,
    required this.school,
    required this.birth,
    required this.yearId,
    this.address,
    this.mothersName,
    required this.parents,
    required this.gradeDelay,
    this.bankAccountNumber,
    this.bankAccountOwnerName,
    this.bankAccountOwnerTypeId,
    this.bankAccountReadOnly = false,
    this.email,
    this.phone,
    this.json,
  });

  factory Student.fromJson(Map json) {
    List<String> parents = [];

    parents = ((json["Gondviselok"] ?? []) as List)
        .cast<Map>()
        .map((e) => e["Nev"] ?? "")
        .toList()
        .cast<String>();
    if (json["AnyjaNeve"] != null) parents.insert(0, json["AnyjaNeve"]);

    parents = parents.map((e) => e.capitalize()).toList(); // fix name casing
    parents = parents.toSet().toList(); // remove duplicates

    final bankszamla = json["Bankszamla"];

    return Student(
      id: json["Uid"] ?? "",
      name: (json["Nev"] ?? json["SzuletesiNev"] ?? "").trim(),
      birthName: json["SzuletesiNev"] != null
          ? (json["SzuletesiNev"] as String).trim()
          : null,
      birthPlace: json["SzuletesiHely"] != null
          ? (json["SzuletesiHely"] as String).trim()
          : null,
      school: School(
        instituteCode: json["IntezmenyAzonosito"] ?? "",
        name: json["IntezmenyNev"] ?? "",
        city: "",
      ),
      birth: json["SzuletesiDatum"] != null
          ? DateTime.parse(json["SzuletesiDatum"]).toLocal()
          : DateTime(0),
      yearId: json["TanevUid"] ?? "",
      address: json["Cimek"] != null
          ? (json["Cimek"] as List).isNotEmpty
              ? json["Cimek"][0] as String
              : null
          : null,
      mothersName: json["AnyjaNeve"] != null
          ? (json["AnyjaNeve"] as String).trim().capitalize()
          : null,
      parents: parents,
      gradeDelay: json["Intezmeny"]?["TestreszabasBeallitasok"]
              ?["ErtekelesekMegjelenitesenekKesleltetesenekMerteke"] ??
          0,
      bankAccountNumber: bankszamla?["BankszamlaSzam"] as String?,
      bankAccountOwnerName: bankszamla?["BankszamlaTulajdonosNeve"] as String?,
      bankAccountOwnerTypeId:
          bankszamla?["BankszamlaTulajdonosTipusId"] as int?,
      bankAccountReadOnly: bankszamla?["IsReadOnly"] as bool? ?? false,
      email: json["EmailCim"] as String?,
      phone: json["Telefonszam"] as String?,
      json: json,
    );
  }
}
