class HospitalDevice {
  final int id;
  final String type;
  final String manufacturer;
  final String model;
  final String location;

  HospitalDevice({this.id, this.type, this.manufacturer, this.model, this.location});

  factory HospitalDevice.fromJson(Map<String, dynamic> json) {
    return HospitalDevice(
      id: int.parse(json['id']),
      type: json['type'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      location: json['location']
    );
  }
}