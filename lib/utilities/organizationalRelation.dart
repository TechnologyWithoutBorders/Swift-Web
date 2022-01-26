class OrganizationalRelation {
  final int id;
  final int parent;

  OrganizationalRelation({this.id, this.parent});

  factory OrganizationalRelation.fromJson(Map<String, dynamic> json) {
    return OrganizationalRelation(
      id: json['id'],
      parent: json['parent'],
    );
  }
}