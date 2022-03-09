import 'package:teog_swift/utilities/hospitalDevice.dart';

class MaintenanceEvent {
  final DateTime dateTime;
  final HospitalDevice device;

  MaintenanceEvent({this.dateTime, this.device});
}