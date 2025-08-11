import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/gcode_diff_bloc.dart';
import 'widgets/diff_pane.dart';
import 'widgets/diff_navigation_controls.dart';
import 'widgets/version_selector.dart';

class GCodeDiffPage extends StatelessWidget {
  const GCodeDiffPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controllerId = ModalRoute.of(context)?.settings.arguments as String? ?? 'default-id';
    if (controllerId.isEmpty) {
      return const Scaffold(body: Center(child: Text('Ошибка: не указан ID контроллера')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Сравнение G-кода для станка $controllerId'),
        actions: const [VersionSelector()],
      ),
      body: BlocProvider.value(
        value: BlocProvider.of<GCodeDiffBloc>(context),
        child: BlocConsumer<GCodeDiffBloc, GCodeDiffState>(
          listener: (context, state) {
            if (state is GCodeDiffError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
          if (state is GCodeDiffLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is GCodeDiffLoaded) {
            return Column(
              children: [
                DiffNavigationControls(
                  currentIndex: state.currentChangeIndex,
                  totalChanges: state.changes.length,
                ),
                Expanded(
                  child: DiffPane(
                    oldText: state.original,
                    newText: state.modified,
                    currentDiffIndex: state.changes.isNotEmpty
                        ? state.changes[state.currentChangeIndex]
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Подтверждение'),
                        content: const Text('Принять изменения как эталон?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () {
                              BlocProvider.of<GCodeDiffBloc>(ctx).add(AcceptChanges());
                              Navigator.pop(ctx);
                            },
                            child: const Text('Принять'),
                          ),
                        ],
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Принять изменения как эталон'),
                  ),
                ),
              ],
            );
          }
          
          return const Center(child: Text('Загрузите данные для сравнения'));
          },
        ),
      ),
    );
  }
}