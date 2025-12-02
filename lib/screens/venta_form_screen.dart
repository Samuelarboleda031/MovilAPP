import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../models/venta.dart'; 
import '../models/cliente.dart';
import '../models/barbero.dart';
import '../models/producto.dart';
import '../models/servicio.dart';
import '../models/paquete.dart';
import '../services/venta_service.dart';
import '../services/auxiliar_service.dart';

// === CLASE AUXILIAR DE VALOR ÚNICO (Solución al Dropdown Error) ===
// Asegura que el valor seleccionado sea único al combinar tipos (Producto, Servicio, Paquete).
class ItemVenta {
  final String tipo; // 'Producto', 'Servicio', 'Paquete'
  final int id;
  
  ItemVenta({required this.tipo, required this.id});
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    // La comparación debe basarse en el tipo Y el id
    return other is ItemVenta && other.tipo == tipo && other.id == id;
  }

  @override
  int get hashCode => tipo.hashCode ^ id.hashCode;
}

// Clase para manejar el estado en el formulario (DetalleVentaItem)
class DetalleVentaItem {
  int? productoId;
  int? servicioId;
  int? paqueteId;
  ItemVenta? itemSeleccionado; // Campo de estado para el Dropdown
  int cantidad;
  double precioUnitario;

  DetalleVentaItem({
    this.productoId,
    this.servicioId,
    this.paqueteId,
    this.itemSeleccionado,
    required this.cantidad,
    required this.precioUnitario,
  });
}

// ------------------------------------------------------------------

class VentaFormScreen extends StatefulWidget {
  final Venta? venta;

  const VentaFormScreen({super.key, this.venta});

  @override
  State<VentaFormScreen> createState() => _VentaFormScreenState();
}

class _VentaFormScreenState extends State<VentaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final VentaService _ventaService = VentaService();
  final AuxiliarService _auxiliarService = AuxiliarService();

  List<Cliente> _clientes = [];
  List<Barbero> _barberos = [];
  List<Producto> _productos = [];
  List<Servicio> _servicios = [];
  List<Paquete> _paquetes = [];

  Cliente? _clienteSeleccionado;
  Barbero? _barberoSeleccionado;
  String _metodoPago = 'Efectivo';
  double _porcentajeDescuento = 0.0;

  List<DetalleVentaItem> _detalles = [];
  bool _isLoading = false;
  bool _isLoadingData = true; // Bloquea la UI hasta que todo cargue

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }
  
  // Lógica para inicializar los detalles de la venta en modo edición
  void _inicializarDetalles(Venta venta) {
    if (venta.detalles != null) {
      _detalles = venta.detalles!.map((d) {
        
        ItemVenta? item;
        // Lógica crucial: Reconstruir ItemVenta a partir del detalle existente
        if (d.productoId != null) {
          item = ItemVenta(tipo: 'Producto', id: d.productoId!);
        } else if (d.servicioId != null) {
          item = ItemVenta(tipo: 'Servicio', id: d.servicioId!);
        } else if (d.paqueteId != null) {
          item = ItemVenta(tipo: 'Paquete', id: d.paqueteId!);
        }
        
        return DetalleVentaItem(
          productoId: d.productoId,
          servicioId: d.servicioId,
          paqueteId: d.paqueteId,
          itemSeleccionado: item, // Asignar el ItemVenta reconstruido
          cantidad: d.cantidad,
          precioUnitario: d.precioUnitario,
        );
      }).toList();
    }
  }

  Future<void> _cargarDatos() async {
    try {
      // 1. Cargar todas las listas de referencia de la API
      final clientes = await _auxiliarService.obtenerClientes();
      final barberos = await _auxiliarService.obtenerBarberos();
      final productos = await _auxiliarService.obtenerProductos();
      final servicios = await _auxiliarService.obtenerServicios();
      final paquetes = await _auxiliarService.obtenerPaquetes();

      Venta? ventaFull;
      if (widget.venta != null) {
        ventaFull = await _ventaService.obtenerVentaPorId(widget.venta!.id!);
        // Fetch details explicitly as they might not be included in the main fetch
        try {
          final detalles = await _ventaService.obtenerDetallesVenta(widget.venta!.id!);
          if (detalles.isNotEmpty) {
             // Create a new Venta object with the fetched details
             ventaFull = Venta(
               id: ventaFull.id,
               numero: ventaFull.numero,
               fechaRegistro: ventaFull.fechaRegistro,
               clienteId: ventaFull.clienteId,
               barberoId: ventaFull.barberoId,
               metodoPago: ventaFull.metodoPago,
               subtotal: ventaFull.subtotal,
               porcentajeDescuento: ventaFull.porcentajeDescuento,
               total: ventaFull.total,
               estado: ventaFull.estado,
               cliente: ventaFull.cliente,
               barbero: ventaFull.barbero,
               detalles: detalles,
             );
          }
        } catch (e) {
          print('Error fetching details for edit: $e');
        }
      }

      setState(() {
        _clientes = clientes;
        _barberos = barberos;
        _productos = productos;
        _servicios = servicios;
        _paquetes = paquetes;

        // 2. Si estamos editando, inicializar los campos
        if (ventaFull != null) {
          // Inicializar campos principales
          try {
            _clienteSeleccionado = _clientes.firstWhere(
              (c) => c.id == ventaFull!.clienteId,
            );
          } catch (_) {
            _clienteSeleccionado = _clientes.isNotEmpty ? _clientes.first : null;
          }

          try {
            _barberoSeleccionado = _barberos.firstWhere(
              (b) => b.id == ventaFull!.barberoId,
            );
          } catch (_) {
            _barberoSeleccionado = _barberos.isNotEmpty ? _barberos.first : null;
          }
          _metodoPago = ventaFull.metodoPago;
          _porcentajeDescuento = ventaFull.porcentajeDescuento;
          
          // 3. Inicializar los detalles SÓLO después de que _productos, _servicios, etc. están cargados
          _inicializarDetalles(ventaFull);
        } else {
           // Si es venta nueva, agregar un detalle vacío por defecto
           _agregarDetalle();
        }
        
        _isLoadingData = false; // Desbloquear la interfaz
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        _mostrarError('Error al cargar datos: $e');
      }
    }
  }

  double get _subtotal {
    return _detalles.fold(0.0, (sum, item) => sum + (item.precioUnitario * item.cantidad));
  }

  double get _descuento {
    return _subtotal * (_porcentajeDescuento / 100);
  }

  double get _total {
    return _subtotal - _descuento;
  }

  void _agregarDetalle() {
    setState(() {
      _detalles.add(DetalleVentaItem(
        productoId: null,
        servicioId: null,
        paqueteId: null,
        itemSeleccionado: null, 
        cantidad: 1,
        precioUnitario: 0.0,
      ));
    });
  }

  void _eliminarDetalle(int index) {
    setState(() {
      _detalles.removeAt(index);
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _guardarVenta() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validaciones de negocio
    if (_detalles.isEmpty) {
      _mostrarError('Debe agregar al menos un producto, servicio o paquete a la venta');
      return;
    }
    
    for (final d in _detalles) {
      if (d.itemSeleccionado == null) {
        _mostrarError('Todos los detalles deben tener seleccionado un producto, servicio o paquete.');
        return;
      }
    }

    if (_clienteSeleccionado == null) {
      _mostrarError('Debe seleccionar un cliente');
      return;
    }

    if (_barberoSeleccionado == null) {
        _mostrarError('Debe seleccionar un barbero');
        return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Mapeo de DetalleVentaItem a DetalleVenta
      final detallesVenta = _detalles.map((d) => DetalleVenta(
        id: null, 
        ventaId: widget.venta?.id ?? 0, 
        productoId: d.productoId,
        servicioId: d.servicioId,
        paqueteId: d.paqueteId,
        cantidad: d.cantidad,
        precioUnitario: d.precioUnitario,
        subTotal: d.precioUnitario * d.cantidad, 
      )).toList();

      final venta = Venta(
        id: widget.venta?.id,
        // Usar la lógica de negocio para generar el número si es nueva
        numero: widget.venta?.numero ?? 'V-${DateTime.now().millisecondsSinceEpoch}',
        fechaRegistro: widget.venta?.fechaRegistro ?? DateTime.now().toIso8601String(),
        clienteId: _clienteSeleccionado!.id!,
        barberoId: _barberoSeleccionado!.id!,
        metodoPago: _metodoPago,
        subtotal: _subtotal,
        porcentajeDescuento: _porcentajeDescuento,
        total: _total,
        estado: true,
        detalles: detallesVenta, // Este campo es el que se serializa como 'detalleVenta' en el modelo Venta
      );

      print('Datos a enviar: ${jsonEncode(venta.toJson())}');

      Venta nuevaVenta;
      if (widget.venta == null) {
        nuevaVenta = await _ventaService.crearVenta(venta);
      } else {
        nuevaVenta = await _ventaService.actualizarVenta(venta);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.venta == null 
                ? 'Venta creada exitosamente' 
                : 'Venta actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Retornar éxito
      }
    } catch (e) {
      String errorMessage = 'Error al guardar la venta: $e';
      // if (e.toString().contains('400')) {
      //   errorMessage = 'Error 400: Datos inválidos. Verifique IDs, stock o formato.';
      // }
      _mostrarError(errorMessage);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.venta == null ? 'Nueva Venta' : 'Editar Venta'),
        backgroundColor: Colors.brown.shade800,
        foregroundColor: Colors.white,
      ),
      // Muestra el indicador de carga si los datos aún no están listos
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cliente
                    DropdownButtonFormField<Cliente>(
                      value: _clienteSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Cliente *',
                        border: OutlineInputBorder(),
                      ),
                      items: _clientes.map((cliente) {
                        return DropdownMenuItem<Cliente>(
                          value: cliente,
                          child: Text('${cliente.nombre} ${cliente.apellido}'), 
                        );
                      }).toList(),
                      onChanged: (cliente) {
                        setState(() {
                          _clienteSeleccionado = cliente;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Seleccione un cliente';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Barbero
                    DropdownButtonFormField<Barbero>(
                      value: _barberoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Barbero *',
                        border: OutlineInputBorder(),
                      ),
                      items: _barberos.map((barbero) {
                        return DropdownMenuItem(
                          value: barbero,
                          child: Text('${barbero.nombre} ${barbero.apellido}'), 
                        );
                      }).toList(),
                      onChanged: (barbero) {
                        setState(() {
                          _barberoSeleccionado = barbero;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Seleccione un barbero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Método de Pago
                    DropdownButtonFormField<String>(
                      initialValue: _metodoPago,
                      decoration: const InputDecoration(
                        labelText: 'Método de Pago *',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Efectivo', 'Tarjeta', 'Transferencia', 'Nequi'].map((metodo) {
                        return DropdownMenuItem(
                          value: metodo,
                          child: Text(metodo),
                        );
                      }).toList(),
                      onChanged: (metodo) {
                        setState(() {
                          _metodoPago = metodo!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Porcentaje de Descuento
                    TextFormField(
                      initialValue: _porcentajeDescuento.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Porcentaje de Descuento (%)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _porcentajeDescuento = double.tryParse(value) ?? 0.0;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    // Detalles
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Detalles de Venta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _agregarDetalle,
                          color: const Color(0xFFD8B081),
                        ),
                      ],
                    ),
                    ..._detalles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final detalle = entry.value;
                      return _buildDetalleItem(index, detalle);
                    }),
                    const SizedBox(height: 24),
                    // Resumen (Card)
                    Card(
                      color: Theme.of(context).cardTheme.color,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                            children: [
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                        const Text('Subtotal:'),
                                        Text('\$${_subtotal.toStringAsFixed(2)}'),
                                    ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                        Text('Descuento (${_porcentajeDescuento.toStringAsFixed(2)}%):'),
                                        Text('-\$${_descuento.toStringAsFixed(2)}'),
                                    ],
                                ),
                                const Divider(),
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                        const Text(
                                            'Total:',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                            ),
                                        ),
                                        Text(
                                            '\$${_total.toStringAsFixed(2)}',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.brown.shade200, // Lighter brown for dark mode
                                            ),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Botón Guardar
                    ElevatedButton(
                      onPressed: _isLoading || _isLoadingData ? null : _guardarVenta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD8B081),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.venta == null ? 'Guardar Venta' : 'Actualizar Venta',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetalleItem(int index, DetalleVentaItem detalle) {
    return DetalleVentaRow(
      key: ValueKey(detalle), // Important: Use a key to maintain state correctly
      index: index,
      detalle: detalle,
      productos: _productos,
      servicios: _servicios,
      paquetes: _paquetes,
      onRemove: () => _eliminarDetalle(index),
      onChanged: () {
        setState(() {
          // Trigger rebuild to update totals
        });
      },
    );
  }
}

class DetalleVentaRow extends StatefulWidget {
  final int index;
  final DetalleVentaItem detalle;
  final List<Producto> productos;
  final List<Servicio> servicios;
  final List<Paquete> paquetes;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const DetalleVentaRow({
    super.key,
    required this.index,
    required this.detalle,
    required this.productos,
    required this.servicios,
    required this.paquetes,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<DetalleVentaRow> createState() => _DetalleVentaRowState();
}

class _DetalleVentaRowState extends State<DetalleVentaRow> {
  late TextEditingController _cantidadCtrl;
  late TextEditingController _precioCtrl;

  @override
  void initState() {
    super.initState();
    _cantidadCtrl = TextEditingController(text: widget.detalle.cantidad.toString());
    _precioCtrl = TextEditingController(text: widget.detalle.precioUnitario.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  double getPrice(ItemVenta item) {
    switch (item.tipo) {
      case 'Producto':
        final prod = widget.productos.firstWhere(
            (p) => p.id == item.id,
            orElse: () => Producto(id: -1, nombre: '', categoriaId: 0, proveedorId: 0, precioCompra: 0, precioVenta: 0));
        return prod.id != -1 ? prod.precioVenta : 0.0;
      case 'Servicio':
        final serv = widget.servicios.firstWhere(
            (s) => s.id == item.id,
            orElse: () => Servicio(id: -1, nombre: '', precio: 0, duracionMinutos: 0));
        return serv.id != -1 ? serv.precio : 0.0;
      case 'Paquete':
        final paq = widget.paquetes.firstWhere(
            (p) => p.id == item.id,
            orElse: () => Paquete(id: -1, nombre: '', precio: 0, duracionMinutos: 0));
        return paq.id != -1 ? paq.precio : 0.0;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ItemVenta?>(
                    value: widget.detalle.itemSeleccionado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Producto/Servicio/Paquete *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      ...widget.productos.map((p) => DropdownMenuItem<ItemVenta>(
                            value: ItemVenta(tipo: 'Producto', id: p.id!),
                            child: Text('Producto: ${p.nombre}'),
                          )),
                      ...widget.servicios.map((s) => DropdownMenuItem<ItemVenta>(
                            value: ItemVenta(tipo: 'Servicio', id: s.id!),
                            child: Text('Servicio: ${s.nombre}'),
                          )),
                      ...widget.paquetes.map((paq) => DropdownMenuItem<ItemVenta>(
                            value: ItemVenta(tipo: 'Paquete', id: paq.id!),
                            child: Text('Paquete: ${paq.nombre}'),
                          )),
                    ],
                    onChanged: (ItemVenta? newValue) {
                      if (newValue == null) return;
                      setState(() {
                        widget.detalle.itemSeleccionado = newValue;

                        // Limpiar y asignar el ID correcto
                        widget.detalle.productoId = null;
                        widget.detalle.servicioId = null;
                        widget.detalle.paqueteId = null;
                        
                        switch (newValue.tipo) {
                          case 'Producto':
                            widget.detalle.productoId = newValue.id;
                            break;
                          case 'Servicio':
                            widget.detalle.servicioId = newValue.id;
                            break;
                          case 'Paquete':
                            widget.detalle.paqueteId = newValue.id;
                            break;
                        }
                        
                        final newPrice = getPrice(newValue);
                        widget.detalle.precioUnitario = newPrice;
                        _precioCtrl.text = newPrice.toStringAsFixed(2);
                        
                        widget.onChanged();
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Seleccione un ítem';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cantidadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Mínimo 1';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final cant = int.tryParse(value);
                      if (cant != null) {
                        widget.detalle.cantidad = cant;
                        widget.onChanged();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _precioCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio Unitario',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || double.tryParse(value) == null || double.parse(value) < 0) {
                        return 'Precio inválido';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final price = double.tryParse(value);
                      if (price != null) {
                        widget.detalle.precioUnitario = price;
                        widget.onChanged();
                      }
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Subtotal Detalle: \$${(widget.detalle.cantidad * widget.detalle.precioUnitario).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}