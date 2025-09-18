import 'package:json_annotation/json_annotation.dart';

part 'command_response.g.dart';

@JsonSerializable()
class CommandResponse {
  final String status;
  final String? message;
  final String? type;
  final dynamic config;

  CommandResponse({required this.status, this.message, this.type, this.config});

  factory CommandResponse.fromJson(Map<String, dynamic> json) =>
      _$CommandResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CommandResponseToJson(this);
}
