class Cliente {
  final int? id;
  final String documento;
  final String nombre;
  final String apellido;
  final String? telefono;
  final String? email;
  final String? direccion;
  final bool? estado;

  Cliente({
    this.id,
    required this.documento,
    required this.nombre,
    required this.apellido,
    this.telefono,
    this.email,
    this.direccion,
    this.estado,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] ?? json['ID'],
      documento: json['documento'] ?? json['Documento'] ?? '',
      nombre: json['nombre'] ?? json['Nombre'] ?? '',
      apellido: json['apellido'] ?? json['Apellido'] ?? '',
      telefono: json['telefono'] ?? json['Telefono'],
      email: json['email'] ?? json['Email'],
      direccion: json['direccion'] ?? json['Direccion'],
      estado: json['estado'] ?? json['Estado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documento': documento,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'estado': estado,
    };
  }

  String get nombreCompleto => '$nombre $apellido';
}

