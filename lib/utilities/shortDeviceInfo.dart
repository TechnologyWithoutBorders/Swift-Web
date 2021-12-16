import 'hospitalDevice.dart';
import 'report.dart';

class ShortDeviceInfo {
  final HospitalDevice device;
  final Report report;
  final String imageData;

  ShortDeviceInfo({this.device, this.report, this.imageData});
}