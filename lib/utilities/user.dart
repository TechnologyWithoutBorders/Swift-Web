class User {
  final int id;
  final String name;
  final String phone;
  final String mail;
  final String position;
  final bool valid;

  User({required this.id, required this.name, required this.phone, required this.mail, required this.position, required this.valid});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      mail: json['mail'],
      position: json['position'],
      valid: json['valid']
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'mail': mail,
    'position': position,
    'valid': valid,
  };
}