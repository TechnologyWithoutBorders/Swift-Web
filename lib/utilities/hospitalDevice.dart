class HospitalDevice {
  final int id;
  final String type;
  final String manufacturer;
  final String model;
  final String serialNumber;
  int orgUnitId;
  String orgUnit;
  final int maintenanceInterval;

  HospitalDevice({this.id, this.type, this.manufacturer, this.model, this.serialNumber, this.orgUnitId, this.orgUnit, this.maintenanceInterval});

  factory HospitalDevice.fromJson(Map<String, dynamic> json) {
    return HospitalDevice(
      id: json['id'],
      type: json['type'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      serialNumber: json['serialNumber'],
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
    'serialNumber': serialNumber,
    'orgUnitId': orgUnitId,
    'orgUnit': orgUnit,
    'maintenanceInterval': maintenanceInterval
  };
}