import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:money_challenge/slot.dart';

class _DenominationGroup {
  final double amount;
  final int slots;

  const _DenominationGroup({required this.amount, required this.slots});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  Box<Slot>? slotsBox;
  bool _isLoadingBox = true;
  // Controls whether the startup animation should play once when the app starts.
  bool _runInitialLaunchAnimation = false;
  final ScrollController _scrollController = ScrollController();
  bool _showSavedTotalInAppBar = false;

  late final AnimationController _startupController;
  // Number of tiles (casillas) total across all groups — used to compute stagger.
  int _totalSlotsCount = 0;
  // Small stagger interval between tiles (as fraction of animation controller duration).
  final double _staggerPerTile = 0.012;

  static const List<_DenominationGroup> denominationGroups = [
    _DenominationGroup(amount: 5, slots: 40),
    _DenominationGroup(amount: 10, slots: 54),
    _DenominationGroup(amount: 20, slots: 53),
    _DenominationGroup(amount: 50, slots: 54),
    _DenominationGroup(amount: 100, slots: 11),
    _DenominationGroup(amount: 200, slots: 12),
    _DenominationGroup(amount: 500, slots: 4),
  ];

  final double goal = 10000.0;

  double _progressPercent(double savedTotalValue) {
    if (goal <= 0) return 0;
    return (savedTotalValue / goal * 100).clamp(0.0, 100.0);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateAppBarState);
    _ensureSlotsBox();
  }

  Future<void> _ensureSlotsBox() async {
    if (Hive.isBoxOpen('slots')) {
      slotsBox = Hive.box<Slot>('slots');
    } else {
      slotsBox = await Hive.openBox<Slot>('slots');
    }

    final isFirstLaunch = slotsBox!.isEmpty;
    if (isFirstLaunch) {
      _runInitialLaunchAnimation = true;
      // First-time initialization: create all slots according to denominationGroups
      for (final group in denominationGroups) {
        for (var i = 1; i <= group.slots; i++) {
          final slot = Slot(
            id: '${group.amount}_$i',
            checked: false,
            amount: group.amount,
          );
          slotsBox!.put(slot.id, slot);
        }
      }
    } else {
      // Reconcile existing slots with the desired counts in denominationGroups.
      // Add missing slots and remove extras so each section has exactly group.slots entries.
      for (final group in denominationGroups) {
        final existing = slotsBox!.values.where((s) => s.amount == group.amount).toList();
        final existingCount = existing.length;

        if (existingCount < group.slots) {
          // Add missing sequential slots using the next available indices.
          var start = 1;
          // Find the highest existing index to avoid id collisions when some were deleted.
          for (final s in existing) {
            final parts = s.id.split('_');
            if (parts.length == 2) {
              final idx = int.tryParse(parts[1]) ?? 0;
              if (idx >= start) start = idx + 1;
            }
          }

          for (var i = start; i <= group.slots; i++) {
            final slot = Slot(id: '${group.amount}_$i', checked: false, amount: group.amount);
            slotsBox!.put(slot.id, slot);
          }
        } else if (existingCount > group.slots) {
          // Remove extras with indices greater than group.slots.
          for (var i = group.slots + 1; i <= existingCount; i++) {
            final key = '${group.amount}_$i';
            if (slotsBox!.containsKey(key)) {
              slotsBox!.delete(key);
            }
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingBox = false;
      });

      // Prepare and start the startup animation controller so tiles can use
      // a single shared controller with staggered intervals.
      _totalSlotsCount = slotsBox!.length;
      var durationMs = _totalSlotsCount * 25 + 600; // scale with number of tiles
      if (durationMs > 2000) durationMs = 2000; // cap duration for responsiveness
      _startupController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: durationMs),
      );

      // When the controller completes, clear the flag so subsequent rebuilds
      // won't wrap tiles with the animation (prevents animations on scroll).
      _startupController.addStatusListener((status) {
        if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
          if (mounted) {
            setState(() {
              _runInitialLaunchAnimation = false;
            });
          }
        }
      });

      // Mark that a startup animation should run; start playing after the
      // first frame so the UI is ready.
      _runInitialLaunchAnimation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startupController.forward();
        }
      });
    }
  }

  double get savedTotal {
    if (slotsBox == null) return 0.0;
    return slotsBox!.values
        .where((s) => s.checked)
        .fold(0.0, (p, e) => p + e.amount);
  }

  int get totalSlots => slotsBox?.length ?? 0;

  List<Slot> slotsForAmount(double amount) {
    if (slotsBox == null) return const [];
    return slotsBox!.values.where((s) => s.amount == amount).toList();
  }

  // Restore the original slot palette: neutral when unchecked, green when checked.
  Color _bgColorForAmount(double amount, ColorScheme cs) {
    // surfaceVariant is deprecated; use surfaceContainerHighest instead.
    return cs.surfaceContainerHighest;
  }

  void toggleChecked(String key) {
    final box = slotsBox;
    if (box == null) return;
    final s = box.get(key);
    if (s == null) return;
    final updated = Slot(id: s.id, checked: !s.checked, amount: s.amount);
    // Writing to the Hive box will notify the ValueListenableBuilder and rebuild only
    // the list contents; avoid calling setState() here to prevent unnecessary rebuilds.
    box.put(key, updated);
  }

  void _updateAppBarState() {
    final shouldShowSavedTotal = _scrollController.offset > 100;
    if (shouldShowSavedTotal != _showSavedTotalInAppBar) {
      setState(() {
        _showSavedTotalInAppBar = shouldShowSavedTotal;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateAppBarState);
    _scrollController.dispose();
    // Dispose the startup controller if it was created.
    try {
      _startupController.dispose();
    } catch (_) {}
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    // The startup animation flag is managed by the animation controller's
    // status listener. Don't clear it here on every build.

    if (_isLoadingBox || slotsBox == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }



    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: ValueListenableBuilder(
          valueListenable: slotsBox!.listenable(),
          builder: (context, Box<Slot> box, _) {
            if (_showSavedTotalInAppBar) {
              final saved = box.values.where((s) => s.checked).fold(0.0, (p, e) => p + e.amount);
              return Text('Total guardado: \$${saved.toStringAsFixed(2)}');
            }
            return const Text('10k Challenge');
          },
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: slotsBox!.listenable(),
          builder: (context, Box<Slot> box, _) {
            // Group slots by amount and compute saved total in one pass to avoid
            // multiple iterations over box.values (which was causing heavy work
            // on rebuild and degrading scroll performance).
            final Map<double, List<Slot>> groupedSlots = {};
            double savedTotalLocal = 0.0;
            for (final s in box.values) {
              groupedSlots.putIfAbsent(s.amount, () => []).add(s);
              if (s.checked) savedTotalLocal += s.amount;
            }
            final percentLocal = _progressPercent(savedTotalLocal);

            final bottomPadding = MediaQuery.of(context).viewPadding.bottom + MediaQuery.of(context).viewInsets.bottom + 12.0;

            // Use a CustomScrollView with slivers and SliverGrid.builder to lazily build
            // grid items. This avoids building all grid children at once (which caused
            // expensive layouts and the overflow warning) and improves scroll performance.
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('${percentLocal.toStringAsFixed(2)} %'),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Total guardado: \$${savedTotalLocal.toStringAsFixed(2)}'),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Casillas totales: $totalSlots'),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),

                // For each denomination group add a header plus a grid. Build full lists
                // of children and apply a single startup animation controller with
                // staggered intervals so the animation only runs at app start.
                ...(() {
                  final List<Widget> groupSlivers = [];
                  int runningIndex = 0;

                  for (final group in denominationGroups) {
                    final slots = groupedSlots[group.amount] ?? const [];

                    groupSlivers.add(
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Monedas de \$${group.amount.toInt()}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                              ),
                              Text('${slots.where((s) => s.checked).length} / ${group.slots}'),
                            ],
                          ),
                        ),
                      ),
                    );

                    final children = List<Widget>.generate(slots.length, (index) {
                      final globalIndex = runningIndex + index;
                      final s = slots[index];
                      final cs = Theme.of(context).colorScheme;
                      final baseBg = _bgColorForAmount(group.amount, cs);
                      final checkedBg = cs.primary.withAlpha((0.18 * 255).round());
                      final bgColor = s.checked ? checkedBg : baseBg;
                      final accentColor = s.checked ? cs.primary : cs.onSurfaceVariant;

                      // Core tile widget (no animation wrapper)
                      final tile = RepaintBoundary(
                        key: ValueKey(s.id),
                        child: GestureDetector(
                          onTap: () => toggleChecked(s.id),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cs.outline),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      group.amount.toInt().toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: accentColor, fontSize: 14),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Icon(
                                        s.checked ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: accentColor,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );

                      // If we should run the startup animation, wrap the tile with
                      // Fade + Slide transitions using a staggered Interval based on
                      // the tile's global index. Otherwise return the tile directly.
                      if (_runInitialLaunchAnimation) {
                        final start = (globalIndex * _staggerPerTile).clamp(0.0, 1.0);
                        final end = (start + 0.38).clamp(0.0, 1.0);
                        final anim = CurvedAnimation(
                          parent: _startupController,
                          curve: Interval(start, end, curve: Curves.easeOut),
                        );

                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero).animate(anim),
                            child: tile,
                          ),
                        );
                      }

                      return tile;
                    });

                    runningIndex += slots.length;

                    groupSlivers.add(
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

                  return groupSlivers;
                }()),

                // Bottom spacing to account for system insets (use a small adapter)
                SliverToBoxAdapter(
                  child: SizedBox(height: bottomPadding),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
