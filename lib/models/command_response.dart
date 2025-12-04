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

  // For backup/restore operations (BLE_BACKUP_RESTORE.md)
  @JsonKey(name: 'backup_info')
  final Map<String, dynamic>? backupInfo;

  @JsonKey(name: 'restored_configs')
  final List<String>? restoredConfigs;

  @JsonKey(name: 'success_count')
  final int? successCount;

  @JsonKey(name: 'fail_count')
  final int? failCount;

  @JsonKey(name: 'requires_restart')
  final bool? requiresRestart;

  CommandResponse({
    required this.status,
    this.message,
    required this.type,
    this.config,
    this.backupInfo,
    this.restoredConfigs,
    this.successCount,
    this.failCount,
    this.requiresRestart,
  });

  factory CommandResponse.fromJson(Map<String, dynamic> json) =>
      _$CommandResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CommandResponseToJson(this);

  // Convenience getter for backup_info
  // ignore: non_constant_identifier_names
  Map<String, dynamic>? get backup_info => backupInfo;
}
