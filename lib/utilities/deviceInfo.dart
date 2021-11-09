import 'hospitalDevice.dart';
import 'report.dart';

class DeviceInfo {
  final HospitalDevice device;
  final Report report;
  final String imageData;

  DeviceInfo({this.device, this.report, this.imageData});
}