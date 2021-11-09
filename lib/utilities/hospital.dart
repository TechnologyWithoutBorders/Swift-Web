class Hospital {
  final int id;
  final String name;

  Hospital({this.id, this.name});

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: int.parse(json['id']),
      name: json['name'],
    );
  }
}