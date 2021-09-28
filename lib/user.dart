class User {
  final int id;
  final String name;
  final String position;

  User({this.id, this.name, this.position});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id']),
      name: json['name'],
      position: json['position']
    );
  }
}