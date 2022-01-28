class Hospital {
  final int id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;

  Hospital({this.id, this.name, this.location, this.latitude, this.longitude});

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      latitude: json['latitude'],
      longitude: json['longitude']
    );
  }
}