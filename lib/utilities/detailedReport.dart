class DetailedReport {
  final int id;
  final String title;
  final String description;
  final int currentState;
  final DateTime created;

  DetailedReport({this.id, this.title, this.description, this.currentState, this.created});

  factory DetailedReport.fromJson(Map<String, dynamic> json) {
    return DetailedReport(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      currentState: json['currentState'],
      created: DateTime.parse(json['created']),//TODO UTC->local
    );
  }
}