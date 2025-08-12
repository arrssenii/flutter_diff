import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/controller_selection_bloc.dart';
import '../bloc/controller_selection_state.dart';
import '../../../routes/app_routes.dart';
import '../bloc/controller_selection_event.dart';

class ControllerSelectionPage extends StatelessWidget {
  const ControllerSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выбор контроллера ЧПУ')),
      body: BlocBuilder<ControllerSelectionBloc, ControllerSelectionState>(
        builder: (context, state) {
          if (state is ControllerSelectionLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ControllerSelectionLoaded) {
            return ListView.builder(
              itemCount: state.controllers.length,
              itemBuilder: (context, index) {
                final controller = state.controllers[index];
                return ListTile(
                  title: Text(controller),
                  onTap: () {
                    context.read<ControllerSelectionBloc>().add(
                          SelectController(controller),
                        );
                    Navigator.pushNamed(
                      context,
                      AppRoutes.gcodeDiff,
                      arguments: controller,
                    );
                  },
                );
              },
            );
          } else if (state is ControllerSelectionError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text('Нажмите для загрузки контроллеров'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<ControllerSelectionBloc>().add(LoadControllers());
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}