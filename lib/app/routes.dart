import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import './features/controllers/view/controllers_page.dart';
import './features/gcode_diff/view/gcode_diff_page.dart';
import '../core/services/gcode_service.dart';
import './features/gcode_diff/bloc/gcode_diff_bloc.dart';
import './features/controllers/bloc/controllers_bloc.dart';

class AppRoutes {
  static const String controllers = '/';
  static const String gcodeDiff = '/controller/:id/gcode-diff';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name!);
    
    if (uri.path == '/') {
      return MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => ControllersBloc()..add(LoadControllers()),
          child: const ControllersPage(),
        ),
        settings: settings,
      );
    }
    
    if (uri.pathSegments.length == 3 && 
        uri.pathSegments[0] == 'controller' &&
        uri.pathSegments[2] == 'gcode-diff') {
      
      final controllerId = uri.pathSegments[1];
      
      return MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => GCodeDiffBloc(
            gCodeService: GCodeService(),
          )..add(LoadGCodeDiff(controllerId: controllerId)),
          child: const GCodeDiffPage(),
        ),
        settings: settings,
      );
    }

    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text('Маршрут не найден: ${settings.name}')),
      ),
    );
  }
}