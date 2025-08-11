import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/routes.dart';
import './app/features/controllers/bloc/controllers_bloc.dart';
import './app/features/gcode_diff/bloc/gcode_diff_bloc.dart';
import './core/services/gcode_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ControllersBloc()..add(LoadControllers()),
        ),
        BlocProvider(
          create: (context) => GCodeDiffBloc(gCodeService: GCodeService()),
        ),
      ],
      child: MaterialApp(
        title: 'CNC G-Code Monitor',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        onGenerateRoute: AppRoutes.generateRoute,
        initialRoute: AppRoutes.controllers,
        builder: (context, child) {
          return BlocListener<GCodeDiffBloc, GCodeDiffState>(
            listener: (context, state) {
              if (state is GCodeDiffLoaded && state.changes.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Обнаружены изменения в G-коде станка ${state.controllerId}'),
                    action: SnackBarAction(
                      label: 'Перейти',
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/controller/${state.controllerId}/gcode-diff',
                        );
                      },
                    ),
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            child: child,
          );
        },
      ),
    );
  }
}