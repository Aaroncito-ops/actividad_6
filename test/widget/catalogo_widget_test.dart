import 'package:ecomarket/domain/entities/coordenada.dart';
import 'package:ecomarket/domain/entities/posicion_entrega.dart';
import 'package:ecomarket/domain/entities/producto.dart';
import 'package:ecomarket/domain/repositories/entrega_repository.dart';
import 'package:ecomarket/domain/repositories/producto_repository.dart';
import 'package:ecomarket/presentation/controllers/catalogo_controller.dart';
import 'package:ecomarket/presentation/views/catalogo_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Catálogo de prueba en memoria, sin internet ni bases de datos.
class _RepositorioProductosFalso implements ProductoRepository {
  @override
  Future<List<Producto>> obtenerTodos() async {
    return [
      Producto(
        id: 'manzana',
        nombre: 'Manzana',
        descripcion: 'Manzana de prueba.',
        categoria: 'Frutas',
        precio: 25.50,
        stock: 10,
      ),
    ];
  }
}

// Las pruebas del catálogo no deben procesar pagos ni consultar GPS.
// Si se invocan accidentalmente, la prueba fallará.
class _RepositorioEntregaFalso implements EntregaRepository {
  @override
  Future<String> procesarPago(double total) {
    throw StateError('Esta prueba no debe procesar pagos.');
  }

  @override
  Stream<PosicionEntrega> rastrearEntrega({
    required Coordenada origen,
    required Coordenada destino,
    int minutosEstimados = 30,
  }) {
    throw StateError('Esta prueba no debe consultar el GPS.');
  }
}

Widget _crearAplicacion(CatalogoController controller) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CatalogoView(
      controller: controller,
      entregaRepository: _RepositorioEntregaFalso(),
      notificarCompra: (_) async {
        throw StateError('Esta prueba no debe enviar notificaciones.');
      },
    ),
  );
}

// Busca el número específicamente dentro de la insignia del carrito.
Finder _contadorCarrito(String numero) {
  return find.descendant(of: find.byType(Badge), matching: find.text(numero));
}

void main() {
  group('Suite de Calidad - Interfaz Gráfica', () {
    testWidgets('Renderizado inicial: muestra EcoMarket y carrito en 0', (
      WidgetTester tester,
    ) async {
      // 1. ARRANGE (Preparar): crear un controlador con datos en memoria.
      final controller = CatalogoController(
        repository: _RepositorioProductosFalso(),
      );
      addTearDown(controller.dispose);

      // 2. ACT (Actuar): montar la pantalla real y completar su carga.
      await tester.pumpWidget(_crearAplicacion(controller));
      await tester.pumpAndSettle();

      // 3. ASSERT (Verificar): comprobar título, producto e insignia.
      expect(find.text('EcoMarket'), findsOneWidget);
      expect(find.text('Manzana'), findsOneWidget);
      expect(find.byType(Badge), findsOneWidget);
      expect(_contadorCarrito('0'), findsOneWidget);

      final insignia = tester.widget<Badge>(find.byType(Badge));
      expect(insignia.isLabelVisible, isTrue);
      expect(tester.takeException(), isNull);

      // Desmontar la pantalla antes de liberar el controlador.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Interacción: pulsar Añadir actualiza el carrito a 1', (
      WidgetTester tester,
    ) async {
      // 1. ARRANGE (Preparar): mostrar el catálogo con un carrito vacío.
      final controller = CatalogoController(
        repository: _RepositorioProductosFalso(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_crearAplicacion(controller));
      await tester.pumpAndSettle();

      final botonAgregar = find.text('Añadir');
      expect(botonAgregar, findsOneWidget);

      await tester.ensureVisible(botonAgregar);
      await tester.pumpAndSettle();

      expect(_contadorCarrito('0'), findsOneWidget);

      // 2. ACT (Actuar): simular el toque y refrescar el fotograma.
      await tester.tap(botonAgregar);
      await tester.pump();

      // 3. ASSERT (Verificar): comprobar la actualización automática.
      expect(_contadorCarrito('1'), findsOneWidget);
      expect(_contadorCarrito('0'), findsNothing);
      expect(controller.cantidadTotalArticulos, 1);
      expect(controller.totalCarrito, 25.50);
      expect(tester.takeException(), isNull);

      // Desmontar también las animaciones del aviso de producto añadido.
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
