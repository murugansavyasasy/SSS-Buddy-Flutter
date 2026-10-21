class DialoutServerModel {
  final int id;
  final String serverName;
  final String defaultDid;
  final String providerCode;
  final bool isActive;
  final bool isCallLog;
  final bool isFileUpload;
  final bool isSendData;

  DialoutServerModel({
    required this.id,
    required this.serverName,
    required this.defaultDid,
    required this.providerCode,
    required this.isActive,
    required this.isCallLog,
    required this.isFileUpload,
    required this.isSendData,
  });

  factory DialoutServerModel.fromJson(Map<String, dynamic> json) {
    return DialoutServerModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      serverName: json['server_name']?.toString() ?? '',
      defaultDid: json['default_did']?.toString() ?? '',
      providerCode: json['provider_code']?.toString() ?? '',
      isActive: _parseBool(json['is_active']),
      isCallLog: _parseBool(json['iscall_log']),
      isFileUpload: _parseBool(json['isfile_upload']),
      isSendData: _parseBool(json['issend_data']),
    );
  }

  // Flag keys used by the list and update-server-flag APIs
  static const keyActive = 'is_active';
  static const keyCallLog = 'iscall_log';
  static const keyFileUpload = 'isfile_upload';
  static const keySendData = 'issend_data';

  bool flag(String key) {
    switch (key) {
      case keyActive:
        return isActive;
      case keyCallLog:
        return isCallLog;
      case keyFileUpload:
        return isFileUpload;
      case keySendData:
        return isSendData;
    }
    return false;
  }

  // Applies the flags returned by update-server-flag; missing keys keep current value
  DialoutServerModel withFlags(Map<String, dynamic> flags) {
    bool pick(String key, bool current) =>
        flags.containsKey(key) ? _parseBool(flags[key]) : current;

    return DialoutServerModel(
      id: id,
      serverName: serverName,
      defaultDid: defaultDid,
      providerCode: providerCode,
      isActive: pick(keyActive, isActive),
      isCallLog: pick(keyCallLog, isCallLog),
      isFileUpload: pick(keyFileUpload, isFileUpload),
      isSendData: pick(keySendData, isSendData),
    );
  }

  // API may send true/false, 1/0 or "true"/"1"
  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    final s = value?.toString().toLowerCase();
    return s == 'true' || s == '1';
  }
}
