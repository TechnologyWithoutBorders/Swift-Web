import 'package:teog_swift/utilities/shortDeviceInfo.dart';

class MaintenanceEvent {
  final DateTime dateTime;
  final List<ShortDeviceInfo> device;

  MaintenanceEvent({this.dateTime, this.device});
}