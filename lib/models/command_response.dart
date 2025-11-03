import 'package:json_annotation/json_annotation.dart';

part 'command_response.g.dart';

@JsonSerializable()
class CommandResponse {
  final String status;
  final String? message;
  @JsonKey(defaultValue: 'unknown')
  final String type;
  @JsonKey(defaultValue: [])
  final dynamic config;

  CommandResponse({
    required this.status,
    this.message,
    required this.type,
    this.config,
  });

  factory CommandResponse.fromJson(Map<String, dynamic> json) =>
      _$CommandResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CommandResponseToJson(this);
}
