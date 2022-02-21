class DeviceStats {
  final int working;
  final int maintenance;
  final int broken;
  final int progress;
  final int salvage;
  final int limitations;

  final int maintenanceOverdue;

  DeviceStats({this.working, this.maintenance, this.broken, this.progress, this.salvage, this.limitations, this.maintenanceOverdue});

  factory DeviceStats.fromJson(Map<String, dynamic> json) {
    return DeviceStats(
      working: json['working'],
      maintenance: json['maintenance'],
      broken: json['broken'],
      progress: json['progress'],
      salvage: json['salvage'],
      limitations: json['limitations'],
      maintenanceOverdue: json['maintenanceOverdue']
    );
  }
}