class DetailedReport {
  final int id;
  final String title;
  final String description;
  final int deviceId;
  final int authorId;
  final String author;
  final int currentState;
  final DateTime created;

  DetailedReport({required this.id, required this.title, required this.description, required this.deviceId, required this.authorId, required this.author, required this.currentState, required this.created});

  factory DetailedReport.fromJson(Map<String, dynamic> json) {
    return DetailedReport(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      deviceId: json['device'],
      authorId: json['authorId'],
      author: json['author'],
      currentState: json['currentState'],
      created: DateTime.parse(json['created']),//TODO: UTC->local
    );
  }
}