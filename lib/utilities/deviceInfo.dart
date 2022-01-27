import 'hospitalDevice.dart';
import 'detailedReport.dart';

class DeviceInfo {
  final HospitalDevice device;
  final List<DetailedReport> reports;
  final String imageData;

  DeviceInfo({this.device, this.reports, this.imageData});
}