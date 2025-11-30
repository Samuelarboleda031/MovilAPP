class Barbero {
  final int? id;
  final String documento;
  final String nombre;
  final String apellido;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? fechaIngreso;
  final bool? estado;

  Barbero({
    this.id,
    required this.documento,
    required this.nombre,
    required this.apellido,
    this.telefono,
    this.email,
    this.direccion,
    this.fechaIngreso,
    this.estado,
  });

  factory Barbero.fromJson(Map<String, dynamic> json) {
    return Barbero(
      id: json['id'] ?? json['ID'],
      documento: json['documento'] ?? json['Documento'] ?? '',
      nombre: json['nombre'] ?? json['Nombre'] ?? '',
      apellido: json['apellido'] ?? json['Apellido'] ?? '',
      telefono: json['telefono'] ?? json['Telefono'],
      email: json['email'] ?? json['Email'],
      direccion: json['direccion'] ?? json['Direccion'],
      fechaIngreso: json['fechaIngreso'] ?? json['FechaIngreso'],
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
      'fechaIngreso': fechaIngreso,
      'estado': estado,
    };
  }

  String get nombreCompleto => '$nombre $apellido';
}

