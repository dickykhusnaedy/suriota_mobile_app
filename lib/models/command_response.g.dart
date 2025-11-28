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
      backupInfo: json['backup_info'] as Map<String, dynamic>?,
      restoredConfigs: (json['restored_configs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      successCount: (json['success_count'] as num?)?.toInt(),
      failCount: (json['fail_count'] as num?)?.toInt(),
      requiresRestart: json['requires_restart'] as bool?,
    );

Map<String, dynamic> _$CommandResponseToJson(CommandResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'type': instance.type,
      'config': instance.config,
      'backup_info': instance.backupInfo,
      'restored_configs': instance.restoredConfigs,
      'success_count': instance.successCount,
      'fail_count': instance.failCount,
      'requires_restart': instance.requiresRestart,
    };
