class HospitalDevice {
  final int id;
  final String type;
  final String manufacturer;
  final String model;
  final String location;
  final int maintenanceInterval;

  HospitalDevice({this.id, this.type, this.manufacturer, this.model, this.location, this.maintenanceInterval});

  factory HospitalDevice.fromJson(Map<String, dynamic> json) {
    return HospitalDevice(
      id: int.parse(json['id']),
      type: json['type'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      location: json['location'],
      maintenanceInterval: json['maintenance_interval']
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'manufacturer': manufacturer,
    'model': model,
    'location': location,
    'maintenance_interval': maintenanceInterval
  };
}