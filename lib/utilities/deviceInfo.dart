import 'hospitalDevice.dart';
import 'detailedReport.dart';

class DeviceInfo {
  final HospitalDevice device;
  final List<DetailedReport> reports;
  final String? imageData;

  DeviceInfo({required this.device, required this.reports, this.imageData});
}