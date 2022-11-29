import 'package:teog_swift/utilities/organizational_relation.dart';

class OrganizationalUnit {
  final int id;
  final String name;

  OrganizationalUnit({required this.id, required this.name});

  factory OrganizationalUnit.fromJson(Map<String, dynamic> json) {
    return OrganizationalUnit(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

class OrganizationalInfo {
  final List<OrganizationalUnit> units;
  final List<OrganizationalRelation> relations;

  OrganizationalInfo({required this.units, required this.relations});
}