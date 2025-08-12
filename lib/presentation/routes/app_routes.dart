import 'package:flutter/material.dart';
import '../features/gcode_diff/view/gcode_diff_page.dart';
import '../features/controller_selection/view/controller_selection_page.dart';

class AppRoutes {
  static const String controllerSelection = '/';
  static const String gcodeDiff = '/gcode-diff';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case controllerSelection:
        return MaterialPageRoute(
          builder: (_) => const ControllerSelectionPage(),
          settings: settings,
        );
      case gcodeDiff:
        final controllerId = settings.arguments as String? ?? 'default';
        return MaterialPageRoute(
          builder: (_) => GCodeDiffPage(controllerId: controllerId),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}