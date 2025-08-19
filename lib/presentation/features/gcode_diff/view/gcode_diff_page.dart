import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/gcode_diff_bloc.dart';
import '../bloc/gcode_diff_event.dart';
import '../bloc/gcode_diff_state.dart';
import 'widgets/diff_pane.dart';
import 'widgets/diff_navigation_controls.dart';
import 'widgets/api_diff_pane.dart';

class GCodeDiffPage extends StatefulWidget {
  final String controllerId;

  const GCodeDiffPage({
    super.key,
    required this.controllerId,
  });

  @override
  State<GCodeDiffPage> createState() => _GCodeDiffPageState();
}

class _GCodeDiffPageState extends State<GCodeDiffPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final numericId = int.tryParse(widget.controllerId) ?? 65;
      context.read<GCodeDiffBloc>().add(LoadLastChanges(numericId.toString()));
    } catch (e) {
      debugPrint('Error loading data: $e');
      context
          .read<GCodeDiffBloc>()
          .add(ErrorOccurred('Ошибка загрузки данных'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сравнение G-code для ${widget.controllerId}'),
        // убрал кнопки навигации из AppBar
      ),
      body: BlocBuilder<GCodeDiffBloc, GCodeDiffState>(
        builder: (context, state) {
          if (state is GCodeDiffLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GCodeDiffError) {
            return Center(child: Text(state.message));
          }

          if (state is GCodeDiffLoaded) {
            // Навигационные кнопки — теперь в правом верхнем углу рабочей области
            return Column(
              children: [
                // Верхняя панель с кнопками навигации (выравнена вправо)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Spacer(),
                      // Обернём кнопки в небольшую карточку, чтобы выглядело аккуратно
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          child: DiffNavigationControls(
                            currentIndex: state.currentChangeIndex,
                            totalChanges: state.diff.diffIndices.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Основная рабочая область с панелями
                Expanded(
                  child: DiffPane(
                    diff: state.diff,
                    currentDiffIndex: state.currentChangeIndex,
                  ),
                ),

                // Небольшой футер с кнопкой "Принять"
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _confirmAcceptChanges(context),
                        child: const Text('Принять изменения'),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            );
          }

          if (state is GCodeApiDiffLoaded) {
            try {
              return Column(
                children: [
                  Expanded(
                    child: ApiDiffPane(
                      oldCode: state.apiData['old'] as String,
                      newCode: state.apiData['new'] as String,
                      differences: state.apiData['differences'] as String,
                    ),
                  ),
                ],
              );
            } catch (e) {
              return Center(child: Text('Ошибка обработки данных API'));
            }
          }

          return const Center(child: Text('Загрузите данные для сравнения'));
        },
      ),
    );
  }

  void _confirmAcceptChanges(BuildContext context) {
    showDialog(
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
              context
                  .read<GCodeDiffBloc>()
                  .add(AcceptChanges(widget.controllerId));
              Navigator.pop(ctx);
            },
            child: const Text('Принять'),
          ),
        ],
      ),
    );
  }
}
