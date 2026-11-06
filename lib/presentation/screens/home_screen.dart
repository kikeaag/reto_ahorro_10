import 'package:flutter/material.dart';
import 'package:money_challenge/domain/entities/savings_summary.dart';
import 'package:money_challenge/presentation/controllers/home_controller.dart';
import 'package:money_challenge/presentation/utils/money_format.dart';
import 'package:money_challenge/presentation/widgets/group_header.dart';
import 'package:money_challenge/presentation/widgets/slot_tile.dart';
import 'package:money_challenge/presentation/widgets/stats_header.dart';
import 'package:provider/provider.dart';

/// Pantalla principal del reto.
///
/// Es una UI "pura": no persiste nada ni calcula el ahorro. Lee el
/// [SavingsSummary] del [HomeController] y delega cada toggle en él.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  /// Escalonamiento entre casillas en la animación de arranque.
  static const double _staggerPerTile = 0.012;

  final ScrollController _scrollController = ScrollController();
  bool _showSavedTotalInAppBar = false;

  /// Montos de los grupos **completados** que el usuario colapsó (estado de
  /// UI puro y efímero: no persiste y al reiniciar todo arranca expandido).
  final Set<double> _collapsedGroups = {};

  /// La animación de arranque se ejecuta **una sola vez** al iniciar la app
  /// (nunca al hacer scroll): el flag se limpia al terminar el controlador.
  bool _runInitialLaunchAnimation = false;
  AnimationController? _startupController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateAppBarState);

    // Inicializa las casillas (idempotente) y arranca la animación de
    // entrada. Se hace en initState para que el primer build ya pinte la UI
    // con las casillas listas y con el flag de animación activo.
    final controller = context.read<HomeController>();
    controller.init();
    final summary = controller.summary;
    if (summary != null) _startStartupAnimation(summary.totalSlots);
  }

  /// Duración proporcional al nº de casillas, con tope de 2000 ms.
  void _startStartupAnimation(int totalSlots) {
    var durationMs = totalSlots * 25 + 600;
    if (durationMs > 2000) durationMs = 2000;

    final animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    // Al terminar se limpia el flag para que los repintados posteriores (p.
    /// ej. al hacer scroll) no vuelvan a envolver las casillas.
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (mounted) {
          setState(() => _runInitialLaunchAnimation = false);
        }
      }
    });

    _startupController = animationController;
    _runInitialLaunchAnimation = true;

    // Se lanza tras el primer frame para que la UI ya esté construida.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) animationController.forward();
    });
  }

  void _updateAppBarState() {
    final shouldShowSavedTotal = _scrollController.offset > 100;
    if (shouldShowSavedTotal != _showSavedTotalInAppBar) {
      setState(() => _showSavedTotalInAppBar = shouldShowSavedTotal);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateAppBarState);
    _scrollController.dispose();
    _startupController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    final summary = controller.summary;

    if (summary == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bottomPadding = MediaQuery.of(context).viewPadding.bottom +
        MediaQuery.of(context).viewInsets.bottom +
        12.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        // Al hacer scroll: el mismo cerdito (Icons.savings) de la tarjeta
        // de estadísticas + la cantidad guardada, con Semantics para
        // accesibilidad.
        title: _showSavedTotalInAppBar
            ? Semantics(
                label: 'Total guardado: ${formatMoney(summary.total)}',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.savings,
                      // Mismo tono del glifo en la tarjeta de estadísticas.
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(formatMoney(summary.total)),
                  ],
                ),
              )
            : const Text('Alcancía 5k'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              // 16 px de margen inferior para separar la tarjeta de
              // estadísticas del primer encabezado de grupo.
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              sliver: SliverToBoxAdapter(child: StatsHeader(summary: summary)),
            ),
            ..._buildGroupSlivers(context, controller, summary),
            SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
          ],
        ),
      ),
    );
  }

  /// Un encabezado + un grid por grupo, con un único índice global para el
  /// escalonamiento de la animación de arranque.
  List<Widget> _buildGroupSlivers(
    BuildContext context,
    HomeController controller,
    SavingsSummary summary,
  ) {
    final slivers = <Widget>[];
    var runningIndex = 0;

    for (final group in summary.groups) {
      final isComplete =
          group.targetSlots > 0 && group.checkedSlots == group.targetSlots;
      final isCollapsed =
          isComplete && _collapsedGroups.contains(group.amount);

      slivers.add(
        SliverPadding(
          // Colapsado: sin grid, así que el margen inferior del encabezado
          // mantiene el mismo ritmo visual que el padding del grid (18 px).
          padding: isCollapsed
              ? const EdgeInsets.fromLTRB(20, 0, 20, 18)
              : const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: GroupHeader(
              group: group,
              collapsible: isComplete,
              collapsed: isCollapsed,
              onToggle: isComplete
                  ? () => setState(() {
                        if (!_collapsedGroups.remove(group.amount)) {
                          _collapsedGroups.add(group.amount);
                        }
                      })
                  : null,
            ),
          ),
        ),
      );

      // Contraído: no se genera ni se construye el grid del grupo.
      if (isCollapsed) {
        runningIndex += group.slots.length;
        continue;
      }

      final children = List<Widget>.generate(group.slots.length, (index) {
        final globalIndex = runningIndex + index;
        final slot = group.slots[index];

        final tile = SlotTile(
          slot: slot,
          onTap: () => controller.toggle(slot.id),
        );

        // Solo se envuelve con la animación mientras dura el arranque.
        if (!_runInitialLaunchAnimation) return tile;

        final start = (globalIndex * _staggerPerTile).clamp(0.0, 1.0);
        final end = (start + 0.38).clamp(0.0, 1.0);
        final animation = CurvedAnimation(
          parent: _startupController!,
          curve: Interval(start, end, curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.22),
              end: Offset.zero,
            ).animate(animation),
            child: tile,
          ),
        );
      });

      runningIndex += group.slots.length;

      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          sliver: SliverGrid(
            delegate: SliverChildListDelegate(children),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
          ),
        ),
      );
    }

    return slivers;
  }
}
