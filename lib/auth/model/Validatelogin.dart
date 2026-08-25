class LoginResponse {
  final String status;
  final String message;
  final LoginData? data;

  LoginResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    if (data != null) 'data': data!.toJson(),
  };
}

class LoginData {
  final String token;
  final int userId;
  final String employeeId;
  final String? schoolUserId;
  final String name;
  final String email;
  final int roleId;
  final String roleCode;
  final String roleSlug;
  final String roleName;

  LoginData({
    required this.token,
    required this.userId,
    required this.employeeId,
    this.schoolUserId,
    required this.name,
    required this.email,
    required this.roleId,
    required this.roleCode,
    required this.roleSlug,
    required this.roleName,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      token: json['token']?.toString() ?? '',
      userId: json['userId'] ?? 0,
      employeeId: json['employeeId']?.toString() ?? '',
      schoolUserId: json['schoolUserId']?.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roleId: json['roleId'] ?? 0,
      roleCode: json['roleCode']?.toString() ?? '',
      roleSlug: json['roleSlug']?.toString() ?? '',
      roleName: json['roleName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'userId': userId,
    'employeeId': employeeId,
    'schoolUserId': schoolUserId,
    'name': name,
    'email': email,
    'roleId': roleId,
    'roleCode': roleCode,
    'roleSlug': roleSlug,
    'roleName': roleName,
  };
}