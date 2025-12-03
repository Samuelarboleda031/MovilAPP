import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/agendamiento.dart';
import '../models/barbero.dart';
import '../models/servicio.dart';
import '../models/paquete.dart';
import '../models/cliente.dart';
import '../services/agendamiento_service.dart';
import '../services/auxiliar_service.dart';
import '../services/auth_service.dart';
import '../models/usuario.dart';

class ClientAgendamientoFormScreen extends StatefulWidget {
  final Agendamiento? agendamiento;
  
  const ClientAgendamientoFormScreen({
    super.key,
    this.agendamiento,
  });

  @override
  State<ClientAgendamientoFormScreen> createState() => _ClientAgendamientoFormScreenState();
}

class _ClientAgendamientoFormScreenState extends State<ClientAgendamientoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AgendamientoService _agendamientoService = AgendamientoService();
  final AuxiliarService _auxiliarService = AuxiliarService();
  final AuthService _authService = AuthService();

  List<Barbero> _barberos = [];
  List<Servicio> _servicios = [];
  List<Paquete> _paquetes = [];
  List<Cliente> _clientes = [];

  Cliente? _clienteSeleccionado;
  Barbero? _barberoSeleccionado;
  Servicio? _servicioSeleccionado;
  Paquete? _paqueteSeleccionado;
  DateTime _fechaSeleccionada = DateTime.now();
  TimeOfDay _horaInicio = TimeOfDay.now();
  TimeOfDay _horaFin = TimeOfDay.now();
  String _estadoCita = 'Pendiente';
  double? _monto;
  String? _observaciones;
  bool _esServicio = true;
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos().then((_) {
      if (widget.agendamiento != null) {
        _cargarDatosAgendamiento(widget.agendamiento!);
      }
    });
  }
  
  void _cargarDatosAgendamiento(Agendamiento agendamiento) {
    setState(() {
      // Set client if available
      if (agendamiento.clienteId != null) {
        _clienteSeleccionado = _clientes.firstWhere(
          (cliente) => cliente.id == agendamiento.clienteId,
          orElse: () => agendamiento.cliente != null 
              ? Cliente(
                  id: agendamiento.cliente!.id,
                  documento: agendamiento.cliente!.documento,
                  nombre: agendamiento.cliente!.nombre,
                  apellido: agendamiento.cliente!.apellido,
                  telefono: agendamiento.cliente!.telefono,
                  email: agendamiento.cliente!.email,
                  direccion: agendamiento.cliente!.direccion,
                  estado: agendamiento.cliente!.estado,
                )
              : Cliente(
                  id: 0,
                  documento: '0',
                  nombre: 'Cliente',
                  apellido: 'Temporal',
                ),
        );
      }
      
      _barberoSeleccionado = _barberos.firstWhere(
        (barbero) => barbero.id == agendamiento.barberoId,
        orElse: () => agendamiento.barbero!,
      );
      
      if (agendamiento.servicioId != null) {
        _servicioSeleccionado = _servicios.firstWhere(
          (servicio) => servicio.id == agendamiento.servicioId,
          orElse: () => agendamiento.servicio!,
        );
        _esServicio = true;
      } else if (agendamiento.paqueteId != null) {
        _paqueteSeleccionado = _paquetes.firstWhere(
          (paquete) => paquete.id == agendamiento.paqueteId,
          orElse: () => agendamiento.paquete!,
        );
        _esServicio = false;
      }
      
      _fechaSeleccionada = DateTime.parse(agendamiento.fechaCita);
      
      final horaInicioParts = agendamiento.horaInicio.split(':');
      _horaInicio = TimeOfDay(
        hour: int.parse(horaInicioParts[0]),
        minute: int.parse(horaInicioParts[1]),
      );
      
      final horaFinParts = agendamiento.horaFin.split(':');
      _horaFin = TimeOfDay(
        hour: int.parse(horaFinParts[0]),
        minute: int.parse(horaFinParts[1]),
      );
      
      _estadoCita = agendamiento.estadoCita;
      _monto = agendamiento.monto;
      _observaciones = agendamiento.observaciones;
    });
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        _isLoadingData = true;
      });

      final barberos = await _auxiliarService.obtenerBarberos();
      final servicios = await _auxiliarService.obtenerServicios();
      final paquetes = await _auxiliarService.obtenerPaquetes();
      final clientes = await _auxiliarService.obtenerClientes();

      setState(() {
        _barberos = barberos;
        _servicios = servicios;
        _paquetes = paquetes;
        _clientes = clientes;
        
        // Set default client to current user if available
        final currentUser = _authService.currentUser;
        if (currentUser != null && _clienteSeleccionado == null) {
          _clienteSeleccionado = _clientes.firstWhere(
            (c) => c.documento == currentUser.uid,
            orElse: () => _clientes.isNotEmpty ? _clientes.first : Cliente(
              id: 0,
              documento: '0',
              nombre: 'Cliente',
              apellido: 'Temporal',
            ),
          );
        }
        
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar los datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _selectHoraInicio() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaInicio,
    );
    if (picked != null) {
      setState(() {
        _horaInicio = picked;
        // Ajustar hora fin si es menor que hora inicio
        if (_horaInicio.hour > _horaFin.hour ||
            (_horaInicio.hour == _horaFin.hour &&
                _horaInicio.minute >= _horaFin.minute)) {
          _horaFin = TimeOfDay(
            hour: _horaInicio.hour,
            minute: (_horaInicio.minute + 30) % 60,
          );
        }
      });
    }
  }

  Future<void> _selectHoraFin() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaFin,
    );
    if (picked != null && picked != _horaFin) {
      // Validar que hora fin sea mayor que hora inicio
      if (picked.hour > _horaInicio.hour ||
          (picked.hour == _horaInicio.hour &&
              picked.minute > _horaInicio.minute)) {
        setState(() {
          _horaFin = picked;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La hora de fin debe ser mayor que la hora de inicio'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _calcularMonto() {
    if (_esServicio && _servicioSeleccionado != null) {
      setState(() {
        _monto = _servicioSeleccionado!.precio;
      });
    } else if (!_esServicio && _paqueteSeleccionado != null) {
      setState(() {
        _monto = _paqueteSeleccionado!.precio;
      });
    } else {
      setState(() {
        _monto = null;
      });
    }
  }

  Future<void> _guardarAgendamiento() async {
    if (!_formKey.currentState!.validate()) return;

    if (_clienteSeleccionado == null || _clienteSeleccionado!.id == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione un cliente'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Ensure we have a valid client ID
    final clienteId = _clienteSeleccionado!.id;
    if (clienteId == null || clienteId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente no válido'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_barberoSeleccionado == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione un barbero'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_esServicio && _servicioSeleccionado == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione un servicio'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!_esServicio && _paqueteSeleccionado == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione un paquete'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Usar el ID del cliente seleccionado
      final clienteId = _clienteSeleccionado!.id!; // We already validated this is not null

      // Formatear fechas y horas
      final fechaCita = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);
      final horaInicio = '${_horaInicio.hour.toString().padLeft(2, '0')}:${_horaInicio.minute.toString().padLeft(2, '0')}';
      final horaFin = '${_horaFin.hour.toString().padLeft(2, '0')}:${_horaFin.minute.toString().padLeft(2, '0')}';

      // Crear el objeto agendamiento
      final agendamiento = Agendamiento(
        id: widget.agendamiento?.id,
        clienteId: clienteId,
        barberoId: _barberoSeleccionado!.id!,
        servicioId: _esServicio ? _servicioSeleccionado?.id : null,
        paqueteId: !_esServicio ? _paqueteSeleccionado?.id : null,
        fechaCita: fechaCita,
        horaInicio: horaInicio,
        horaFin: horaFin,
        estadoCita: _estadoCita,
        monto: _monto ?? 0,
        observaciones: _observaciones,
      );

      // Guardar o actualizar el agendamiento
      if (widget.agendamiento == null) {
        await _agendamientoService.crearAgendamiento(agendamiento);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _agendamientoService.actualizarAgendamiento(agendamiento);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita actualizada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la cita: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.agendamiento == null ? 'Nueva Cita' : 'Editar Cita'),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Selección de Cliente
                    DropdownButtonFormField<Cliente>(
                      value: _clientes.firstWhere(
                        (c) => _clienteSeleccionado != null && c.id == _clienteSeleccionado!.id,
                        orElse: () => _clienteSeleccionado ?? Cliente(
                          id: 0,
                          documento: '0',
                          nombre: 'Seleccione un cliente',
                          apellido: '',
                        ),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cliente',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: [
                        DropdownMenuItem<Cliente>(
                          value: Cliente(
                            id: 0,
                            documento: '0',
                            nombre: 'Seleccione un cliente',
                            apellido: '',
                          ),
                          enabled: false,
                          child: const Text('Seleccione un cliente', style: TextStyle(color: Colors.grey)),
                        ),
                        ..._clientes.map((cliente) {
                          return DropdownMenuItem<Cliente>(
                            value: cliente,
                            child: Text('${cliente.nombre} ${cliente.apellido}'.trim()),
                          );
                        }).toList(),
                      ],
                      onChanged: (Cliente? value) {
                        if (value != null && value.id != 0) {
                          setState(() {
                            _clienteSeleccionado = value;
                          });
                        }
                      },
                      validator: (value) => value == null || value.id == 0 ? 'Por favor seleccione un cliente' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Tipo de cita (Servicio/Paquete)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Tipo de cita: '),
                            ToggleButtons(
                              isSelected: [_esServicio, !_esServicio],
                              onPressed: (index) {
                                setState(() {
                                  _esServicio = index == 0;
                                  _servicioSeleccionado = null;
                                  _paqueteSeleccionado = null;
                                  _monto = null;
                                });
                              },
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Text('Servicio'),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Text('Paquete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Barbero
                    DropdownButtonFormField<Barbero>(
                      value: _barberoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Barbero',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _barberos.map((barbero) {
                        return DropdownMenuItem<Barbero>(
                          value: barbero,
                          child: Text(barbero.nombreCompleto ?? barbero.nombre),
                        );
                      }).toList(),
                      onChanged: (Barbero? value) {
                        setState(() {
                          _barberoSeleccionado = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor seleccione un barbero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Tipo de Cita
                    const Text(
                      'Tipo de Cita',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Servicio'),
                            value: true,
                            groupValue: _esServicio,
                            onChanged: (bool? value) {
                              setState(() {
                                _esServicio = value!;
                                _servicioSeleccionado = null;
                                _paqueteSeleccionado = null;
                                _monto = null;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Paquete'),
                            value: false,
                            groupValue: _esServicio,
                            onChanged: (bool? value) {
                              setState(() {
                                _esServicio = value!;
                                _servicioSeleccionado = null;
                                _paqueteSeleccionado = null;
                                _monto = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Servicio o Paquete
                    _esServicio
                        ? DropdownButtonFormField<Servicio>(
                            value: _servicioSeleccionado,
                            decoration: const InputDecoration(
                              labelText: 'Servicio',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: _servicios.map((servicio) {
                              return DropdownMenuItem<Servicio>(
                                value: servicio,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(servicio.nombre),
                                    Text(
                                      '\$${servicio.precio.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (Servicio? value) {
                              setState(() {
                                _servicioSeleccionado = value;
                                _paqueteSeleccionado = null;
                                _calcularMonto();
                              });
                            },
                            validator: (value) => value == null ? 'Por favor seleccione un servicio' : null,
                          )
                        : DropdownButtonFormField<Paquete>(
                            value: _paqueteSeleccionado,
                            decoration: const InputDecoration(
                              labelText: 'Paquete',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: _paquetes.map((paquete) {
                              return DropdownMenuItem<Paquete>(
                                value: paquete,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(paquete.nombre),
                                    Text(
                                      '\$${paquete.precio.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (Paquete? value) {
                              setState(() {
                                _paqueteSeleccionado = value;
                                _servicioSeleccionado = null;
                                _calcularMonto();
                              });
                            },
                            validator: (value) => value == null ? 'Por favor seleccione un paquete' : null,
                          ),
                    const SizedBox(height: 16),
                    
                    // Fecha y Hora
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fecha de la cita'),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: _selectDate,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(_fechaSeleccionada),
                                    ),
                                    const Icon(Icons.calendar_today, size: 18),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hora de inicio'),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: _selectHoraInicio,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _horaInicio.format(context),
                                    ),
                                    const Icon(Icons.access_time, size: 18),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hora de fin'),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: _selectHoraFin,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _horaFin.format(context),
                                    ),
                                    const Icon(Icons.access_time, size: 18),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(
                              text: _monto != null ? '\$${_monto!.toStringAsFixed(2)}' : '',
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Monto',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Estado de la cita
                    DropdownButtonFormField<String>(
                      value: _estadoCita,
                      decoration: const InputDecoration(
                        labelText: 'Estado de la cita',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: ['Pendiente', 'Confirmada', 'En curso', 'Completada', 'Cancelada']
                          .map((estado) => DropdownMenuItem<String>(
                                value: estado,
                                child: Text(estado),
                              ))
                          .toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            _estadoCita = value;
                          });
                        }
                      },
                      validator: (value) => value == null ? 'Por favor seleccione un estado' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _guardarAgendamiento,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(widget.agendamiento == null ? 'Crear Cita' : 'Actualizar Cita'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
