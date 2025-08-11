import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/controllers_bloc.dart';
import '../models/controllers_model.dart';

class ControllersPage extends StatelessWidget {
  const ControllersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Станки ЧПУ')),
      body: BlocBuilder<ControllersBloc, ControllersState>(
        builder: (context, state) {
          if (state is ControllersLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ControllersLoaded) {
            return ListView.builder(
              itemCount: state.controllers.length,
              itemBuilder: (context, index) {
                final controller = state.controllers[index];
                return ListTile(
                  title: Text(controller.name),
                  subtitle: Text(controller.id),
                  trailing: controller.hasChanges
                      ? const Icon(Icons.warning, color: Colors.orange)
                      : null,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/controller/${controller.id}/gcode-diff',
                  ),
                );
              },
            );
          } else if (state is ControllersError) {
            return Center(child: Text('Ошибка: ${state.message}'));
          }
          return const Center(child: Text('Загрузите список станков'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<ControllersBloc>().add(LoadControllers()),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}