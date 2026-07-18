part of '../app_state.dart';

class _BossMoment {
  final int hp;
  final bool isDefeated;

  const _BossMoment({required this.hp, required this.isDefeated});
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP STATE PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  AppState get state => notifier!;

  static AppState of(BuildContext ctx) =>
      ctx.dependOnInheritedWidgetOfExactType<AppStateProvider>()!.state;

  static AppState? maybeOf(BuildContext ctx) =>
      ctx.dependOnInheritedWidgetOfExactType<AppStateProvider>()?.state;

  static AppState read(BuildContext ctx) =>
      ctx.getInheritedWidgetOfExactType<AppStateProvider>()!.state;
}

/// Rebuilds only when the selected AppState projection changes.
///
/// Use this for application-shell concerns that should not recreate the whole
/// MaterialApp for every domain mutation. Feature widgets can continue using
/// [AppStateProvider.of] when they intentionally observe all state changes.
class AppStateSelector<T> extends StatefulWidget {
  const AppStateSelector({
    super.key,
    this.state,
    required this.selector,
    required this.builder,
    this.child,
  });

  /// An explicitly owned state instance. When omitted, the nearest
  /// [AppStateProvider] is read without creating an inherited dependency.
  final AppState? state;
  final T Function(AppState state) selector;
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;

  @override
  State<AppStateSelector<T>> createState() => _AppStateSelectorState<T>();
}

class _AppStateSelectorState<T> extends State<AppStateSelector<T>> {
  AppState? _state;
  late T _value;

  AppState _resolveState() => widget.state ?? AppStateProvider.read(context);

  void _bindState(AppState nextState) {
    if (identical(nextState, _state)) {
      _value = widget.selector(nextState);
      return;
    }
    _state?.removeListener(_handleChange);
    _state = nextState..addListener(_handleChange);
    _value = widget.selector(nextState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindState(_resolveState());
  }

  @override
  void didUpdateWidget(AppStateSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bindState(_resolveState());
  }

  void _handleChange() {
    final state = _state;
    if (state == null || !mounted) return;
    final next = widget.selector(state);
    if (next == _value) return;
    setState(() => _value = next);
  }

  @override
  void dispose() {
    _state?.removeListener(_handleChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _value, widget.child);
}
