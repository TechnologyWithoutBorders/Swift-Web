import 'hospitalDevice.dart';
import 'report.dart';

class DeviceInfo {
  final HospitalDevice device;
  final List<Report> reports;
  final String imageData;

  DeviceInfo({this.device, this.reports, this.imageData});
}