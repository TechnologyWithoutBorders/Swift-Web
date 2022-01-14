class OrganizationalUnit {
  final int id;
  final String name;
  final int parent;

  OrganizationalUnit({this.id, this.name, this.parent});

  factory OrganizationalUnit.fromJson(Map<String, dynamic> json) {
    return OrganizationalUnit(
      id: int.parse(json['id']),
      name: json['name'],
      parent: json['parent'] == null ? null : int.parse(json['parent'])
    );
  }
}