class OrganizationalRelation {
  final int id;
  final int parent;

  OrganizationalRelation({required this.id, required this.parent});

  factory OrganizationalRelation.fromJson(Map<String, dynamic> json) {
    return OrganizationalRelation(
      id: json['id'],
      parent: json['parent'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'parent': parent,
  };
}

class DeviceRelation {
  final int deviceId;
  final int orgUnitId;

  DeviceRelation({required this.deviceId, required this.orgUnitId});

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'orgUnitId': orgUnitId,
  };
}