class LoginResponse {
  final String status;
  final LoginData data;

  LoginResponse({
    required this.status,
    required this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'] ?? '',
      data: LoginData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'data': data.toJson(),
  };
}

class LoginData {
  final String token;
  final int userId;
  final String employeeId;
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
    required this.name,
    required this.email,
    required this.roleId,
    required this.roleCode,
    required this.roleSlug,
    required this.roleName,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      token: json['token'] ?? '',
      userId: json['userId'] ?? 0,
      employeeId: json['employeeId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      roleId: json['roleId'] ?? 0,
      roleCode: json['roleCode'] ?? '',
      roleSlug: json['roleSlug'] ?? '',
      roleName: json['roleName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'userId': userId,
    'employeeId': employeeId,
    'name': name,
    'email': email,
    'roleId': roleId,
    'roleCode': roleCode,
    'roleSlug': roleSlug,
    'roleName': roleName,
  };
}