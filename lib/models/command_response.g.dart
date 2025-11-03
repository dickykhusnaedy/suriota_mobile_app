// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommandResponse _$CommandResponseFromJson(Map<String, dynamic> json) =>
    CommandResponse(
      status: json['status'] as String,
      message: json['message'] as String?,
      type: json['type'] as String? ?? 'unknown',
      config: json['config'] ?? [],
    );

Map<String, dynamic> _$CommandResponseToJson(CommandResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'type': instance.type,
      'config': instance.config,
    };
