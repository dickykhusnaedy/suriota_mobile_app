import 'dart:convert';

class CommandResponse {
  final String status;
  final dynamic data;
  final String? message;
  final DateTime timestamp;

  CommandResponse({
    required this.status,
    required this.data,
    this.message,
    required this.timestamp,
  });

  factory CommandResponse.fromJson(Map<String, dynamic> json) {
    return CommandResponse(
      status: json['status'] ?? 'unknown',
      data: json['data'] ?? json['devices'] ?? {},
      message: json['message'],
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());
}
