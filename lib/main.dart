import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'presentation/routes/app_routes.dart';
import 'presentation/features/controller_selection/bloc/controller_selection_bloc.dart';
import 'package:test_gcode/presentation/features/gcode_diff/bloc/gcode_diff_bloc.dart';
import 'package:test_gcode/presentation/features/gcode_diff/bloc/gcode_diff_state.dart';
import './domain/usecases/compare_gcode_usecase.dart';
import './domain/usecases/get_gcode_versions_usecase.dart';
import './domain/usecases/save_reference_usecase.dart';
import './data/repositories/gcode_repository_impl.dart';
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
          create: (context) => ControllerSelectionBloc(),
        ),
        BlocProvider(
          create: (context) {
            final repository = GCodeRepositoryImpl(GCodeService());
            return GCodeDiffBloc(
              compareGCode: CompareGCodeUseCase(repository),
              getVersions: GetGCodeVersionsUseCase(repository),
              saveReference: SaveReferenceUseCase(repository),
              gcodeRepository: repository,
            );
          },
        ),
      ],
      child: MaterialApp(
        title: 'CNC G-Code Monitor',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        onGenerateRoute: AppRoutes.generateRoute,
        initialRoute: AppRoutes.controllerSelection,
        builder: (context, child) {
          return BlocListener<GCodeDiffBloc, GCodeDiffState>(
            listener: (context, state) {
              if (state is GCodeDiffLoaded && state.diff.changes.isNotEmpty) {
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