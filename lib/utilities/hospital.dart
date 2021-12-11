class Hospital {
  final int id;
  final String name;
  final String location;

  Hospital({this.id, this.name, this.location});

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: int.parse(json['id']),
      name: json['name'],
      location: json['location']
    );
  }
}