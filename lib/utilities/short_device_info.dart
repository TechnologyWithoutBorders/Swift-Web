import 'hospital_device.dart';
import 'report.dart';

class ShortDeviceInfo {
  final HospitalDevice device;
  final Report report;
  final String? imageData;

  ShortDeviceInfo({required this.device, required this.report, this.imageData});
}