class User {
  final int id;
  final String name;
  final String phone;
  final String mail;
  final String position;

  User({this.id, this.name, this.phone, this.mail, this.position});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      mail: json['mail'],
      position: json['position']
    );
  }
}