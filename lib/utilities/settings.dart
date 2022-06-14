class Settings {
  final bool autoMaintenance;

  Settings({required this.autoMaintenance});

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      autoMaintenance: json['autoMaintenance'],
    );
  }
}