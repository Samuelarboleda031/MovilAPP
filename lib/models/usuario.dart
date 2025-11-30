class Usuario {
  final int? id;
  final String correo;
  final String? contrasena;
  final int? rolId;
  final bool? estado;

  Usuario({
    this.id,
    required this.correo,
    this.contrasena,
    this.rolId,
    this.estado,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? json['ID'],
      correo: json['correo'] ?? json['Correo'] ?? '',
      contrasena: json['contrasena'] ?? json['Contrasena'],
      rolId: json['rolId'] ?? json['RolID'],
      estado: json['estado'] ?? json['Estado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'correo': correo,
      'contrasena': contrasena,
      'rolId': rolId,
      'estado': estado,
    };
  }
}

class LoginRequest {
  final String correo;
  final String contrasena;

  LoginRequest({
    required this.correo,
    required this.contrasena,
  });

  Map<String, dynamic> toJson() {
    return {
      'correo': correo,
      'contrasena': contrasena,
    };
  }
}

class LoginResponse {
  final bool success;
  final String? token;
  final Usuario? usuario;
  final String? message;

  LoginResponse({
    required this.success,
    this.token,
    this.usuario,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      token: json['token'],
      usuario: json['usuario'] != null ? Usuario.fromJson(json['usuario']) : null,
      message: json['message'],
    );
  }
}

