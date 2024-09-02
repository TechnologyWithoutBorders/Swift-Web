import 'package:teog_swift/utilities/device_state.dart';

class DeviceStats {
  //TODO: these should be private
  int working;
  int maintenance;
  int broken;
  int progress;
  int salvage;
  int limitations;

  int maintenanceOverdue;

  DeviceStats({required this.working, required this.maintenance, required this.broken, required this.progress, required this.salvage, required this.limitations, required this.maintenanceOverdue});

  factory DeviceStats.fromJson(Map<String, dynamic> json) {
    //TODO: this should only use the state numbers, not names
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

  void add(int state, int value) {
    switch (state) {
      case DeviceState.working:
        working += value;
        break;
      case DeviceState.maintenance: 
        maintenance += value;
        break;
      case DeviceState.broken: 
        broken += value;
        break;
      case DeviceState.inProgress: 
        progress += value;
        break;
      case DeviceState.salvage: 
        salvage += value;
        break;
      case DeviceState.limitations: 
        limitations += value;
        break;
    }
  }
}