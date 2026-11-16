# Proyecto de ventas e inventario en ensamblador

Sistema de consola en MASM x86 de 32 bits con Irvine32 para un negocio de **refacciones de iPhone**: registra productos, recibe mercancía, vende con descuento por cantidad, muestra un resumen de la sesión y guarda el catálogo en un archivo CSV para recuperarlo en otra ejecución.

## Datos generales

| | |
|---|---|
| **Materia** | Lenguajes de Interfaz |
| **Unidad** | Unidad 2. Programación básica · Unidad 3. Modularización (versión actual) |
| **Alumno** | Luciano Ivan Villa Zuñiga |
| **Horario** | 8:00 am - 9:00 am |
| **Docente** | Dr. José Luis Medina Jiménez |
| **Institución** | Instituto Tecnológico de Culiacán — Ingeniería en Sistemas Computacionales |

## Contenido del repositorio

| Archivo | Qué es |
|---|---|
| [`proyecto-ventas-inventario.sln`](proyecto-ventas-inventario.sln) | Solución de Visual Studio |
| [`proyecto-ventas-inventario/main.asm`](proyecto-ventas-inventario/main.asm) | Código fuente completo: macros, datos y procedimientos |
| [`proyecto-ventas-inventario/inventario.csv`](proyecto-ventas-inventario/inventario.csv) | Archivo de inventario con productos de prueba |
| [`pruebas/`](pruebas) | Archivos inválidos para demostrar el control de errores al cargar |
| [`docs/Informe.pdf`](docs/Informe.pdf) | Informe: negocio, regla adicional, organización en memoria, formato del archivo, decisiones, tabla de pruebas, versión de la Unidad 3 y fuentes |

## Requisitos

- Visual Studio 2022 con la carga de trabajo **Desarrollo para el escritorio con C++** (incluye MASM).
- Biblioteca **Irvine32** en `C:\Irvine` (`Irvine32.inc`, `Irvine32.lib`, `Kernel32.lib`, etc.).

## Compilación y ejecución

1. Copia la carpeta de Irvine32 a `C:\Irvine`. El proyecto ya trae configuradas las rutas:
   - *Propiedades → Microsoft Macro Assembler → Include Paths*: `C:\Irvine`
   - *Propiedades → Vinculador → Directorios de bibliotecas adicionales*: `C:\Irvine`
   - *Propiedades → Vinculador → Entrada → Dependencias adicionales*: `Irvine32.lib`
2. Abre `proyecto-ventas-inventario.sln`.
3. En la barra superior selecciona la configuración **Debug** y la plataforma **x86**. Irvine32 es de 32 bits, así que no compila en x64.
4. Compila con **Compilar → Compilar solución** (Ctrl+Shift+B).
5. Ejecuta con **Ctrl+F5** (o F5 para depurar).

Al ejecutar desde Visual Studio, el directorio de trabajo es la carpeta `proyecto-ventas-inventario/`, ahí es donde el programa busca y guarda `inventario.csv`. Si ejecutas el `.exe` directamente desde `Debug/`, copia `inventario.csv` junto al ejecutable.

## Menú

```
1. Registrar producto          6. Mostrar resumen
2. Mostrar inventario          7. Guardar catalogo
3. Buscar producto por codigo  8. Cargar catalogo
4. Recibir mercancia           9. Salir
5. Vender
```

- En cualquier captura, **Enter vacío cancela** la operación sin modificar nada.
- Si un dato es inválido se muestra el error en rojo y se vuelve a pedir.
- Al iniciar se intenta cargar `inventario.csv`; si no existe o está dañado, se avisa y se empieza con el catálogo vacío.
- Al salir con cambios sin guardar, el programa pregunta si se desea guardar.

## Datos y validaciones

| Dato | Regla |
|---|---|
| Código | Único, formato `ABC-123`: 3 letras mayúsculas, guion y 3 dígitos |
| Nombre | 1 a 25 caracteres: letras, números, espacio, `-` y `.`; no inicia con espacio |
| Precio | De 0.01 a 9999.99 MXN; pesos enteros o con punto y 1 o 2 decimales (`185`, `185.5`, `185.50`). Sin `$`, comas ni espacios. Se guarda en centavos |
| Existencia | 0 a 100 unidades |
| Entradas y ventas | Enteros mayores que cero; la existencia nunca pasa de 100 ni queda negativa |
| Capacidad | Máximo 10 productos |

## Regla del negocio: descuento por cantidad

Al vender **5 piezas o más** de un mismo producto se aplica **10% de descuento** sobre el importe base. El descuento se calcula en centavos y se descartan las fracciones de centavo.

| Venta | Importe base | Descuento | Total |
|---|---|---|---|
| 3 × Batería iPhone 13 ($650.00) | 1950.00 MXN | No aplica | 1950.00 MXN |
| 6 × Centro de carga iPhone 12 ($420.00) | 2520.00 MXN | 252.00 MXN | 2268.00 MXN |

Los ingresos de la sesión suman el total final de cada venta, y el resumen muestra también el total de descuentos otorgados.

## Formato del archivo `inventario.csv`

Texto separado por comas, con encabezado y un producto por línea (fin de línea CR LF):

```
codigo,nombre,precio,existencia
PAN-011,Pantalla iPhone 11,1850.50,12
BAT-013,Bateria iPhone 13,650.00,8
```

Al cargar, el archivo se valida completo en un catálogo temporal con las mismas reglas que la captura por teclado. Debe tener el encabezado exacto, 4 campos por línea, códigos sin repetir y como máximo 10 productos. Solo si todo es correcto se reemplaza el catálogo; si hay un error, se indica la línea y se conserva el catálogo actual.

## Archivos de prueba

Para demostrar el control de errores, copia uno de estos archivos sobre `proyecto-ventas-inventario/inventario.csv` y usa la opción 8 (o reinicia el programa):

| Archivo | Error esperado |
|---|---|
| `pruebas/inventario_codigo_duplicado.csv` | Línea 3: código repetido |
| `pruebas/inventario_precio_invalido.csv` | Línea 2: precio con `$` y tres decimales |
| `pruebas/inventario_encabezado_incorrecto.csv` | Línea 1: encabezado incorrecto |

Para probar el archivo ausente, renombra o elimina `inventario.csv`.

## Organización del código

Todo el código está en `main.asm`: primero las 12 macros, después las constantes y los datos, y al final los 43 procedimientos. Cada procedimiento está documentado con lo que **recibe**, lo que **regresa** y los registros que **modifica** o **conserva**.

Cada producto ocupa 42 bytes en memoria y se recorre con `ESI` sumando `TAM_PRODUCTO`:

| Desplazamiento | Campo | Tamaño |
|---|---|---|
| +0 | código | 8 bytes (7 + 00h) |
| +8 | nombre | 26 bytes (25 + 00h) |
| +34 | precio en centavos | DWORD |
| +38 | existencia | DWORD |

Los números se capturan con `ReadString` y se muestran con `WriteString` usando conversiones propias (`convertirEntero`, `convertirPrecio`, `convertirDecimal`, `formatearImporte`). No se usan `ReadDec`, `ReadInt`, `ParseDecimal32`, `WriteDec` ni `WriteHex`.

## Versión de la Unidad 3

En la Unidad 3 el sistema se reorganizó con procedimientos, macros y `USES`, sin cambiar sus funciones, validaciones ni la regla del descuento.

- **Procedimientos nuevos:** `leerOCancelar` (captura y cancelación con Enter vacío, usada por las 4 capturas), `pedirProductoExistente` (pedir código, buscar y mostrar, usada por buscar, recibir y vender), `calcularImporte` (importe y descuento de una venta) y `mostrarTotalProductos`.
- **Macros** (al inicio de `main.asm`): `mMostrar`, `mMostrarLn`, `mError`, `mRojo`, `mExito`, `mColor`, `mEtiquetaNumero`, `mEtiquetaImporte`, `mPonerChar`, `mFueraDeRango`, `mExtraerCampoCSV` y `mOpcion`. `mOpcion` usa `LOCAL` porque se expande 7 veces en el menú.
- **USES** en 40 procedimientos. Los registros que regresan resultados (por ejemplo EAX en `convertirEntero`) quedan fuera de `USES`.
- **Líneas de código fuente** (sin contar líneas vacías ni comentarios): 1602 en la Unidad 2 contra 1229 ahora, ya con las macros incluidas.

La versión de la Unidad 2 está en el repositorio [Proyecto-Ventas-Inventario-ASM](https://github.com/Khedos/Proyecto-Ventas-Inventario-ASM).
