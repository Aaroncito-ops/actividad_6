import 'package:ecomarket/domain/entities/producto.dart';
import 'package:ecomarket/domain/repositories/producto_repository.dart';
import 'package:ecomarket/presentation/controllers/catalogo_controller.dart';
import 'package:flutter_test/flutter_test.dart';

// Repositorio falso: devuelve productos únicamente en memoria.
// No utiliza internet, bases de datos ni servicios externos.
class _RepositorioFalso implements ProductoRepository {
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
      Producto(
        id: 'naranja',
        nombre: 'Naranja',
        descripcion: 'Naranja de prueba.',
        categoria: 'Frutas',
        precio: 15.25,
        stock: 10,
      ),
    ];
  }
}

void main() {
  group('Suite de Calidad - Lógica de Negocio', () {
    test('Estado inicial: el carrito inicia vacío y con total cero', () {
      // 1. ARRANGE (Preparar): crear un controlador nuevo.
      final controller = CatalogoController(repository: _RepositorioFalso());
      addTearDown(controller.dispose);

      // 2. ACT (Actuar): consultar el estado inicial.
      final articulos = controller.cantidadTotalArticulos;
      final monto = controller.totalCarrito;

      // 3. ASSERT (Verificar): comprobar que el carrito está vacío.
      expect(articulos, 0);
      expect(monto, 0.0);
      expect(controller.carrito, isEmpty);
      expect(controller.carritoVacio, isTrue);
    });

    test('Cálculo matemático: suma correctamente dos productos', () async {
      // 1. ARRANGE (Preparar): cargar los productos ficticios.
      final controller = CatalogoController(repository: _RepositorioFalso());
      addTearDown(controller.dispose);

      await controller.cargarCatalogo();

      // 2. ACT (Actuar): agregar una unidad de cada producto.
      controller.agregarAlCarrito('manzana');
      controller.agregarAlCarrito('naranja');

      // 3. ASSERT (Verificar): dos artículos y 25.50 + 15.25 = 40.75.
      expect(controller.cantidadTotalArticulos, 2);
      expect(controller.cantidadProductosEnCarrito, 2);
      expect(controller.cantidadEnCarrito('manzana'), 1);
      expect(controller.cantidadEnCarrito('naranja'), 1);
      expect(controller.totalCarrito, 40.75);
    });

    test('Regla de negocio: rechaza comprar con el carrito vacío', () {
      // 1. ARRANGE (Preparar): crear un carrito sin productos.
      final controller = CatalogoController(repository: _RepositorioFalso());
      addTearDown(controller.dispose);

      // 2. ACT (Actuar): preparar el intento de compra inválida.
      // Se ejecutará dentro de expect para capturar la excepción.
      final operacion = controller.confirmarCompra;

      // 3. ASSERT (Verificar): rechazar la compra y conservar el estado.
      expect(operacion, throwsStateError);
      expect(controller.cantidadTotalArticulos, 0);
      expect(controller.totalCarrito, 0.0);
      expect(controller.carritoVacio, isTrue);
    });
  });
}
