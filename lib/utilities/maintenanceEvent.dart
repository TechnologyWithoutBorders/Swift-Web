import 'package:teog_swift/utilities/hospitalDevice.dart';

class MaintenanceEvent {
  final DateTime dateTime;
  final HospitalDevice device;

  MaintenanceEvent({required this.dateTime, required this.device});
}