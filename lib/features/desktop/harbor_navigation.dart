import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'harbor_strings.dart';

final harborNavigationHistoryProvider =
    Provider<HarborNavigationHistory>((ref) {
  final history = HarborNavigationHistory();
  ref.onDispose(history.dispose);
  return history;
});

/// Sidebar navigation uses go(), so Navigator.canPop alone misses those visits.
class HarborNavigationHistory extends ChangeNotifier {
  GoRouter? _router;
  final List<String> _visits = [];
  String? _returning;
  bool get canGoBack => _visits.length > 1;
  void attach(GoRouter router) {
    if (identical(_router, router)) return;
    _router?.routeInformationProvider.removeListener(_record);
    _router = router;
    _visits.clear();
    _visits.add(router.routeInformationProvider.value.uri.toString());
    router.routeInformationProvider.addListener(_record);
  }

  void _record() {
    final route = _router!.routeInformationProvider.value.uri.toString();
    if (_returning == route) {
      _returning = null;
    } else if (_visits.isEmpty || _visits.last != route) {
      _returning = null;
      _visits.add(route);
      if (_visits.length > 64) _visits.removeAt(0);
    }
    notifyListeners();
  }

  void back() {
    final router = _router;
    if (router == null || !canGoBack) return;
    _visits.removeLast();
    _returning = _visits.last;
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(_returning!);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _router?.routeInformationProvider.removeListener(_record);
    super.dispose();
  }
}

class HarborBackButton extends ConsumerStatefulWidget {
  final VoidCallback? localBack;
  const HarborBackButton({super.key, this.localBack});
  @override
  ConsumerState<HarborBackButton> createState() => _HarborBackButtonState();
}

class _HarborBackButtonState extends ConsumerState<HarborBackButton> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.read(harborNavigationHistoryProvider).attach(GoRouter.of(context));
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(harborNavigationHistoryProvider);
    return AnimatedBuilder(
        animation: history,
        builder: (_, __) => IconButton(
              key: const ValueKey('navigation-back'),
              tooltip: harborText(context, 'Back'),
              onPressed:
                  widget.localBack ?? (history.canGoBack ? history.back : null),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
            ));
  }
}
