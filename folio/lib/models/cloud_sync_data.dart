class CloudSyncData {
  Map settings;
  List<String> deviceIds;
  String FolioPlusId;
  Map json;

  CloudSyncData({
    this.settings = const {},
    this.deviceIds = const [],
    this.FolioPlusId = "",
    required this.json,
  });

  factory CloudSyncData.fromJson(Map json) {
    return CloudSyncData(
      settings: json['settings'] ?? {},
      deviceIds: List<String>.from(json['device_ids'] ?? []),
      FolioPlusId: json['folio_plus_id'] ?? "",
      json: json,
    );
  }
}
