# AGENTS.md — money_challenge

Guía de reglas de negocio e invariantes para trabajar en esta app. Léela antes de modificar código.

## Visión general

App Flutter de reto de ahorro: el usuario marca casillas (cada una representa una moneda de cierto
denominado) hasta alcanzar una meta de **$10,000.00**.

- **Stack:** Flutter 3.44.9 (stable) · Dart `^3.12.2` · Hive (almacenamiento local) · `provider`
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
| `lib/domain/usecases/` | `InitializeSlots`, `GetSlots`, `ToggleSlot`, `GetSavingsSummary`. |
| `lib/infrastructure/` | Implementación concreta: `models/slot_model.dart` (`SlotAdapter`), `datasources/hive_slot_datasource.dart`, `repositories/savings_repository_impl.dart`. |
| `lib/presentation/controllers/home_controller.dart` | `ChangeNotifier` que publica el `SavingsSummary`; **única vía de escritura desde la UI**. |
| `lib/presentation/screens/home_screen.dart` | UI pura: slivers, grid y animación de arranque. |
| `lib/presentation/widgets/` | `StatsHeader`, `GroupHeader`, `SlotTile`. |
| `test/widget_test.dart` | Único test. Depende de textos y del conteo de casillas (ver invariantes). |

## Reglas de negocio

### Meta

- Meta global: **`goal = 10000.0`** (`lib/domain/entities/denomination_group.dart`).

### Denominaciones (fuente única de verdad: `denominationGroups`)

| Monto | Casillas | Subtotal |
|---|---|---|
| $5 | 40 | $200 |
| $10 | 54 | $540 |
| $20 | 53 | $1,060 |
| $50 | 54 | $2,700 |
| $100 | 11 | $1,100 |
| $200 | 12 | $2,400 |
| $500 | 4 | $2,000 |
| **Total** | **228** | **$10,000** |

### Invariantes (romperlos rompe la app)

1. **La suma de los subtotales debe ser exactamente igual a la meta ($10,000).**
   Si es menor, el progreso nunca llega a 100%. Si es mayor, se supera el 100% (aunque el
   porcentaje está con `clamp(0, 100)`). Si cambias `denominationGroups`, recalcula la suma.
2. **El total de casillas es 228** y está hardcodeado en `test/widget_test.dart`
   (`'Casillas totales: 228'`). Si cambias las cantidades, actualiza el test en el mismo cambio.
3. **Formato de ID de slot: `'${group.amount}_$i'`** → como `amount` es `double`, el id real es
   **`5.0_1`**, `10.0_7`, `500.0_4`… (no `5_1`). Se usa para deduplicar y reconciliar: **no
   cambiar el patrón** ni el tipo de `amount`, o existentes data se leería como malformada.
4. **Interacción solo de toggle:** desde la UI solo se marca/desmarca una casilla. No existe
   edición de montos ni borrado de casillas por el usuario.

### Cálculos

- **Total guardado** = suma de `amount` de las casillas con `checked == true`.
- **Progreso (%)** = `total / goal * 100`, con `clamp(0.0, 100.0)`.
- **Formato de presentación:** siempre 2 decimales. El porcentaje se muestra con **espacio antes
  del símbolo**: `12.34 %`. El total como `$1234.00`.

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

- Título del AppBar: **`10k Challenge`**. Al hacer scroll `> 100px` cambia a
  **`Total guardado: $X.XX`**.
- Encabezado por grupo: **`Monedas de $X`** + contador **`n / total`** (casillas marcadas /
  casillas del grupo).
- Textos superiores: porcentaje (`XX.XX %`), `Total guardado: $X.XX`, `Casillas totales: N`.
- Grid: **5 columnas**, `childAspectRatio: 1`.
- Tema: Material 3 con semilla lila **`#6750A4`** como `primary` exacto, `onPrimary` blanco.
- Los textos anteriores los assertúa el test: si los cambias, actualiza `test/widget_test.dart`.

## Rendimiento (reglas que el código ya establece — mantenerlas)

- **Un solo pasagge** sobre la lista de casillas para agrupar por monto y calcular el total
  (`SavingsSummary.fromSlots`); no iterar la lista varias veces ni hacer N lecturas de la box.
- Al hacer toggle: escribir en la box (caso de uso) y refrescar con
  `HomeController.toggle()` → `notifyListeners()`. **No usar `setState()` en el toggle**
  (causa rebuilds innecesarios).
- Usar `CustomScrollView` + `SliverGrid` para build lazy (no construir todos los tiles a la vez).
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
