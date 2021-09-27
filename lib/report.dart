class Report {
  final int currentState;
  final String created;

  Report({this.currentState, this.created});

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      currentState: json['currentState'],
      created: json['created'],//TODO UTC->local
    );
  }
}