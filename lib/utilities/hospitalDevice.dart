class HospitalDevice {
  final int id;
  final String type;
  final String manufacturer;
  final String model;
  int orgUnitId;
  String orgUnit;
  final int maintenanceInterval;

  HospitalDevice({this.id, this.type, this.manufacturer, this.model, this.orgUnitId, this.orgUnit, this.maintenanceInterval});

  factory HospitalDevice.fromJson(Map<String, dynamic> json) {
    return HospitalDevice(
      id: json['id'],
      type: json['type'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      orgUnitId: json['orgUnitId'],
      orgUnit: json['orgUnit'],
      maintenanceInterval: json['maintenanceInterval']
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'manufacturer': manufacturer,
    'model': model,
    'orgUnitId': orgUnitId,
    'orgUnit': orgUnit,
    'maintenanceInterval': maintenanceInterval
  };
}