class SwiftResponse {
  final int responseCode;
  final dynamic message;

  SwiftResponse({this.responseCode, this.message});

  factory SwiftResponse.fromJson(Map<String, dynamic> json) {
    return SwiftResponse(
      responseCode: json['response_code'],
      message: json['data'],
    );
  }
}