class SwiftResponse {
  final int responseCode;
  final dynamic data;

  SwiftResponse({required this.responseCode, this.data});

  factory SwiftResponse.fromJson(Map<String, dynamic> json) {
    return SwiftResponse(
      responseCode: json['response_code'],
      data: json['data'],
    );
  }
}