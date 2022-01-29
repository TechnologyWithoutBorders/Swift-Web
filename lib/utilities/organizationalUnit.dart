class OrganizationalUnit {
  final int id;
  final String name;

  OrganizationalUnit({this.id, this.name});

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