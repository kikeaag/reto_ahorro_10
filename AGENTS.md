# AGENTS.md — money_challenge

Guía de reglas de negocio e invariantes para trabajar en esta app. Léela antes de modificar código.

## Visión general

App Flutter de reto de ahorro: el usuario marca casillas (cada una representa una moneda de cierto
denominado) hasta alcanzar una meta de **$5,000.00**.

- **Stack:** Flutter 3.44.9 (stable) · Dart `^3.12.2` · Hive (almacenamiento local) ·
  `provider` · `confetti` (pantalla de felicitaciones) · `share_plus` (compartir logro)
- **Sin backend:** todos los datos viven en el dispositivo, sin sincronización ni backup.
- **Arquitectura por capas:** `domain` (reglas puras) → `infrastructure` (Hive) →
  `presentation` (UI). La UI **nunca** habla con Hive: pasa por casos de uso y
  `HomeController`.

### Mapa de archivos

| Archivo | Rol |
|---|---|
| `lib/main.dart` | Arranque (Hive, registro de `SlotAdapter`, tema Material 3 lila `#6750A4`) **y raíz de composición**: ensambla datasource → repository → casos de uso → `HomeController`. |
| `lib/domain/entities/` | Entidades puras (sin Flutter ni Hive): `Slot`, `DenominationGroup` (+ `goal`, `denominationGroups`), `SavingsSummary`/`GroupProgress`. |
| `lib/domain/datasources/slot_datasource.dart` | Interfaz de acceso a datos de casillas. |
| `lib/domain/repositories/savings_repository.dart` | Interfaz de persistencia; es lo único que usan los casos de uso. |
| `lib/domain/usecases/` | `InitializeSlots`, `GetSlots`, `ToggleSlot`, `GetSavingsSummary`, `ResetSlots`. |
| `lib/infrastructure/` | Implementación concreta: `models/slot_model.dart` (`SlotAdapter`), `datasources/hive_slot_datasource.dart`, `repositories/savings_repository_impl.dart`. |
| `lib/presentation/controllers/home_controller.dart` | `ChangeNotifier` que publica el `SavingsSummary`; **única vía de escritura desde la UI**. |
| `lib/presentation/screens/home_screen.dart` | UI pura: slivers, grid y animación de arranque. |
| `lib/presentation/screens/goal_reached_screen.dart` | Pantalla de felicitaciones (`GoalReachedScreen`): se abre con `pushReplacement` al cruzar la meta; confeti (`confetti`), resumen final y botones de compartir (`share_plus`) y reinicio. |
| `lib/presentation/utils/money_format.dart` | Helper `formatMoney` (entero + separador de miles, sin centavos). |
| `lib/presentation/widgets/` | `StatsHeader`, `GroupHeader`, `SlotTile`. |
| `test/widget_test.dart` | Único test. Depende de textos y del conteo de casillas (ver invariantes). |

## Reglas de negocio

### Meta

- Meta global: **`goal = 5000.0`** (`lib/domain/entities/denomination_group.dart`).

### Denominaciones (fuente única de verdad: `denominationGroups`)

| Monto | Casillas | Subtotal |
|---|---|---|
| $5 | 56 | $280 |
| $10 | 54 | $540 |
| $20 | 54 | $1,080 |
| $50 | 6 | $300 |
| $100 | 6 | $600 |
| $200 | 6 | $1,200 |
| $500 | 2 | $1,000 |
| **Total** | **184** | **$5,000** |

### Invariantes (romperlos rompe la app)

1. **La suma de los subtotales debe ser exactamente igual a la meta ($5,000).**
   Si es menor, el progreso nunca llega a 100%. Si es mayor, se supera el 100% (aunque el
   porcentaje está con `clamp(0, 100)`). Si cambias `denominationGroups`, recalcula la suma.
2. **El total de casillas es 184** y está hardcodeado en `test/widget_test.dart`
   (`'Casillas totales: 0 / 184'`). Si cambias las cantidades, actualiza el test en el mismo cambio.
3. **Formato de ID de slot: `'${group.amount}_$i'`** → como `amount` es `double`, el id real es
   **`5.0_1`**, `10.0_7`, `500.0_4`… (no `5_1`). Se usa para deduplicar y reconciliar: **no
   cambiar el patrón** ni el tipo de `amount`, o existentes data se leería como malformada.
4. **Interacción solo de toggle:** desde la UI solo se marca/desmarca una casilla. No existe
   edición de montos ni borrado de casillas por el usuario (la única excepción es el reset
   de "Iniciar nueva alcancía", ver *Meta alcanzada*). Colapsar un grupo completado es
   estado visual efímero: **no modifica datos**.

### Meta alcanzada (felicitaciones)

- `HomeController.toggle(id)` devuelve **`bool`**: `true` solo cuando ese toque **cruza**
  la meta (`antes < goal && después >= goal`). Es la única señal que dispara la
  felicitación; no duplicar el cálculo del umbral en la UI.
- `HomeScreen` navega con **`Navigator.pushReplacement`** a `GoalReachedScreen`:
  la pantalla final **reemplaza** al home (sin vuelta atrás a la lista; el botón
  atrás del sistema cierra la app).
- **`init()` nunca la dispara**: abrir la app ya completada no vuelve a celebrar;
  la celebración es exclusiva de marcar la última casilla. Si el usuario desmarca
  y vuelve a marcar, celebra de nuevo (es otro cruce).
- La pantalla es UI pura: lee el resumen con `context.read<HomeController>().summary`
  y no persiste nada.
- **Reset (`ResetSlots`):** su única acción es el botón **`Iniciar nueva alcancía`**
  (`FilledButton.icon` con `refresh`), que llama a `HomeController.reset()` y luego
  `pushReplacement` a un `HomeScreen` nuevo. `reset()` desmarca las 184 casillas
  (**no borra la box ni los ids**) y **recalcula el resumen** antes de navegar:
  `init()` es idempotente y no lo haría, así que sin ese paso el home nuevo
  mostraría el total viejo. Es la **única** operación que limpia `checked`.
- **Compartir (`Compartir logro`):** `OutlinedButton.icon` con `share` que, con
  `share_plus`, abre la **hoja de compartir del sistema** (WhatsApp, X, Facebook…).
  Adjunta dos cosas: el mensaje de texto (`¡Alcancé mi meta de ahorro! 🐷💰` +
  `$5,000 en la Alcancía 5k — 184/184 casillas completadas.` + bloque
  **`📲 Descarga la app`** con las ligas de Google Play y App Store) y un **PNG de la
  pantalla completa** capturado con el `RepaintBoundary` que envuelve el `body`
  (`_repaintKey` → `toImage` → `XFile.fromData`). Si la captura falla, se
  comparte **solo el texto** (nunca rompe el share). **No navega ni modifica
  datos.** El contexto se lee siempre antes del primer `await` (lint
  `use_build_context_synchronously`); el `sharePositionOrigin` del botón (vía
  `Builder`) es el ancla del popover en iPad.
- **Ligas de descarga:** viven como constantes en
  `lib/presentation/utils/app_download_links.dart` (`kPlayStoreUrl`,
  `kAppStoreUrl`). **Son placeholders**: reemplazar por las URLs reales de las
  fichas publicadas antes de compartir en producción (ahí se cambian, y solo
  ahí). Van **dentro del `text`** del share porque `share_plus` **no permite**
  `text` y `uri` al mismo tiempo.

### Cálculos

- **Total guardado** = suma de `amount` de las casillas con `checked == true`.
- **Progreso (%)** = `total / goal * 100`, con `clamp(0.0, 100.0)`.
- **Formato de presentación:** el porcentaje siempre con 2 decimales y **espacio antes del
  símbolo**: `12.34 %`. El total es un **entero con separador de miles y sin centavos**:
  `$1234` → `$1,234` (helper `formatMoney` en `lib/presentation/utils/money_format.dart`).

### Reconciliación al arrancar (`InitializeSlots`)

- Si la box está vacía (primer arranque): se crean todas las casillas de `denominationGroups`
  con `checked: false`.
- Si ya existe data, **por cada grupo**:
  - Se conservan las casillas cuyo id parsea a un índice dentro de `1..group.slots` (sin
    duplicados).
  - Se **borran** las sobrantes: índice fuera de rango, id malformado o índice duplicado.
  - Se **crean sin marcar** los índices que falten, de modo que cada grupo termine con
    **exactamente** `group.slots` casillas.
  - Se borra antes de crear (para liberar índices) y **nunca se pisa un id que siga existiendo**.
- **El estado `checked` de las casillas existentes se preserva** (es tu ahorro; nunca resetearlo
  al reconciliar).

## Persistencia (Hive)

- Box: **`'slots'`**, tipo `Box<Slot>`, abierta **una sola vez en `main()`**. El datasource la
  asume abierta (`Hive.box('slots')`).
- `SlotAdapter` tiene **`typeId: 0`** y orden binario `writeString, writeBool, writeDouble`.
  **Nunca reutilizar ni reasignar este typeId** con otro tipo: corrompe los datos leídos del disco.
- **Contrato de sincronía del datasource** (romperlo cuelga la UI y los tests):
  - **Lecturas síncronas** (`getSlots`, `getSlot`): las casillas viven en memoria.
  - **Escrituras `void`**: Hive aplica el cambio en memoria de forma síncrona y persiste en
    segundo plano. **No esperar el futuro de disco** (bloquea el hilo y, en `testWidgets`, cuelga
    el test indefinidamente).
  - Por el mismo motivo **no usar streams de Hive ni `subscription.cancel()`** dentro de la UI:
    el estado se refresca con `HomeController` → `notifyListeners()`.
- Los datos son locales. Borrar la app / limpiar datos = perder el ahorro. No agregar
  operaciones que sobrescriban la box sin preservar `checked`.

## UI / UX

- Título del AppBar: **`Alcancía 5k`**. Al hacer scroll `> 100px` cambia al **icono `savings`
  (cerdito)** en color **`onPrimaryContainer`** (igual que en la tarjeta) + la **cantidad
  guardada** (`formatMoney(total)`, p. ej. `$5,000`), envuelto en
  `Semantics(label: 'Total guardado: $X,XXX')`.
- Encabezado por grupo: **`Monedas de $X`** ($5 y $10) o **`Billetes de $X`** ($20 en adelante)
  + contador **`n / total`** (casillas marcadas / casillas del grupo).
- Grupo **completado** (`n == total`): el encabezado se vuelve tocable (icono ▾/▴) y alterna el
  colapso de sus casillas; colapsado solo quedan el título y el contador, con **18 px de margen
  inferior** para separarlo del siguiente grupo. El estado contraído se persiste en la caja de
  Hive `'collapsed_groups'` (`Box<bool>`) a través de `HomeController`: al volver a abrir la app
  se mantiene contraído, al iniciar nueva alcancía (`reset`) todo vuelve a estar expandido y un
  grupo incompleto siempre se muestra expandido.
- Tarjeta de estadísticas (`StatsHeader`): `Card` M3 tonal (`surfaceContainerHighest`,
  radius 16) con icono `savings` en `primaryContainer`, etiqueta **`Total guardado`** + monto
  (`$X,XXX`), **`Progreso`** + porcentaje (`XX.XX %`) a la derecha, `LinearProgressIndicator`
  redondeado en `primary`, y pie con icono `checklist` + **`Casillas totales: n / N`**.
- Grid: **5 columnas**, `childAspectRatio: 1`.
- Tema: Material 3 con semilla lila **`#6750A4`** como `primary` exacto, `onPrimary` blanco.
  Fuente de toda la app: **Roboto** (variable, `fonts/Roboto-Variable.ttf`, familia `Roboto`
  declarada en `pubspec.yaml` y `fontFamily` del `ThemeData`).
- Pantalla de felicitaciones (`GoalReachedScreen`): **sin AppBar** y sin retorno a la
  lista, fondo degradado `primaryContainer → surface`, confeti en loop desde el centro
  superior (paquete `confetti`), icono `savings` en círculo `primary`, **`¡Felicidades!`**,
  **`Has alcanzado la meta de $5,000`**, tarjeta con **`Total guardado`** / **`$5,000`** y
  **`Progreso`** / **`100.00 %`**, pie `Completaste las 184 casillas de tu alcancía.` y,
  hasta abajo dos botones ancho completo: `OutlinedButton.icon` con `share` y texto
  **`Compartir logro`** (encima) y `FilledButton.icon` con `refresh` y texto
  **`Iniciar nueva alcancía`** (abajo, acción principal).
- **Tarjeta de vidrio** (felicitaciones): estilo *glassmorphism* compuesto por
  sombra `primary` suave por fuera → `ClipRRect` (radio 16) → `BackdropFilter`
  con `ui.ImageFilter.blur(sigma: 18)` que desenfoca el degradado y el confeti
  de atrás → relleno `Colors.white.withValues(alpha: 0.42)` → borde de 1 px
  con degradado blanco (0.9 → 0.25) pintado por `_GlassBorderPainter`
  (`CustomPaint(foregroundPainter:)`). **No existe `GradientBorder` en Flutter
  3.44.9**, por eso el borde es un painter propio y no un `border:` de
  `BoxDecoration`. El `ClipRRect` va **antes** del `BackdropFilter` para que el
  blur no sobresalga en forma rectangular detrás de las esquinas redondas.
- Los textos anteriores (incluidos los de la felicitación) los assertúa
  `test/widget_test.dart`: si los cambias, actualiza el test.

## Rendimiento (reglas que el código ya establece — mantenerlas)

- **Un solo pasagge** sobre la lista de casillas para agrupar por monto y calcular el total
  (`SavingsSummary.fromSlots`); no iterar la lista varias veces ni hacer N lecturas de la box.
- Al hacer toggle: escribir en la box (caso de uso) y refrescar con
  `HomeController.toggle()` → `notifyListeners()`. **No usar `setState()` en el toggle**
  (causa rebuilds innecesarios).
- Usar `CustomScrollView` + `SliverGrid` para build lazy (no construir todos los tiles a la vez).
- Grupo colapsado: su `SliverGrid` **no se agrega** al `CustomScrollView` (ni se construye).
- Envolver cada tile en `RepaintBoundary` para aislar repintados.

## Animación de arranque

- Se ejecuta **una sola vez al iniciar la app** (flag `_runInitialLaunchAnimation`), nunca al
  hacer scroll.
- Duración = `totalSlots * 25 + 600` ms, **con tope de 2000 ms**.
- Stagger por tile: `_staggerPerTile = 0.012`, con `Interval(start, start + 0.38)` y
  `Curves.easeOut` (Fade + Slide).
- El flag se limpia en el listener de estado del controller (`completed`/`dismissed`), no en
  `build`.

## Comandos

```bash
flutter analyze   # lint (usa flutter_lints vía analysis_options.yaml)
flutter test      # corre test/widget_test.dart
flutter run       # app en dispositivo/emulador
```

Al terminar un cambio: `flutter analyze` sin problemas nuevos y `flutter test` en verde.
