class Report {
  final int currentState;
  final DateTime created;

  Report({this.currentState, this.created});

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      currentState: json['currentState'],
      created: DateTime.parse(json['created'] + 'Z'),
    );
  }
}