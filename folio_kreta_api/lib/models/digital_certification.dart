class DigitalCertification {
  final int id;
  final String? name;
  final String? schoolYear;
  final String? typeName;
  final DateTime issuedAt;

  DigitalCertification({
    required this.id,
    this.name,
    this.schoolYear,
    this.typeName,
    required this.issuedAt,
  });

  factory DigitalCertification.fromJson(Map json) {
    return DigitalCertification(
      id: json["Id"] ?? 0,
      name: json["Megnevezes"] as String?,
      schoolYear: json["TanevNev"] as String?,
      typeName: json["TipusNev"] as String?,
      issuedAt: json["KiallitasDatum"] != null
          ? DateTime.parse(json["KiallitasDatum"]).toLocal()
          : DateTime(0),
    );
  }
}
