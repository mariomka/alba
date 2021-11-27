import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import '../../framework/error.dart';
import '../restoration.dart';
import '../router.dart';

/// A widget that manages routes and pages though the [Navigator].
///
/// [Router.of] operates on the nearest ancestor [Router] from the
/// given [BuildContext]. Be sure to provide a [BuildContext] below the
/// intended [Router].
class Router extends StatefulWidget {
  final AlbaRouter _routerState;

  final void Function() _notifyDelegate;

  /// The key used for [Navigator].
  final GlobalKey<NavigatorState>? _navigatorKey;

  /// Creates a [Router].
  const Router({
    required AlbaRouter routerState,
    required void Function() notifyDelegate,
    GlobalKey<NavigatorState>? navigatorKey,
    Key? key,
  })  : _navigatorKey = navigatorKey,
        _routerState = routerState,
        _notifyDelegate = notifyDelegate,
        super(key: key);

  @override
  RouterState createState() => RouterState();

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// Router.of(context).push('/my/path');
  /// ```
  ///
  /// If there is no [Router] in the give `context`, this function will
  /// throw a [RouterError] in debug mode, and an exception in release mode.
  ///
  /// This method can be expensive (it walks the element tree).
  static RouterState of(BuildContext context) {
    var _routerState = context.findRootAncestorStateOfType<RouterState>();

    assert(() {
      if (_routerState == null) {
        throw AlbaError(
            'Router operation requested with a context that does not include a Router.\n');
      }
      return true;
    }());

    return _routerState!;
  }
}

/// The state for a [Router] widget.
///
/// A reference to this class can be obtained by calling [Router.of].
class RouterState extends State<Router> with RestorationMixin {
  final RestorablePageInformationList _restorablePages =
      RestorablePageInformationList();

  @override
  String? get restorationId => 'page_router';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restorablePages, 'restorable_pages');

    if (_restorablePages.value.isEmpty) {
      _syncRestorablePages();
    } else {
      widget._routerState.restorePages(_restorablePages);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      restorationScopeId: 'navigator',
      key: widget._navigatorKey,
      pages: [
        for (var activePage in widget._routerState.activeRoutes)
          activePage.buildPage(context)
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }

        widget._routerState.pop(route, result);
        _syncRestorablePages();
        widget._notifyDelegate();

        return true;
      },
    );
  }

  void _syncRestorablePages() {
    _restorablePages.value = widget._routerState.activeRoutes
        .map((activePage) =>
            RestorablePageInformation.fromActivePage(activePage))
        .toList();
  }

  /// Adds new page.
  void push(String path, {String? id}) {
    widget._routerState.push(path, id);
    _syncRestorablePages();
    widget._notifyDelegate();
  }

  /// Router event stream.
  ValueStream<RouterEvent> get eventStream => widget._routerState.eventStream;
}