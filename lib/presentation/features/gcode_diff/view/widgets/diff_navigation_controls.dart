import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/gcode_diff_bloc.dart';
import '../../bloc/gcode_diff_event.dart';

class DiffNavigationControls extends StatelessWidget {
  final int currentIndex;
  final int totalChanges;

  const DiffNavigationControls({
    super.key,
    required this.currentIndex,
    required this.totalChanges,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (currentIndex > 0) {
                context
                    .read<GCodeDiffBloc>()
                    .add(NavigateToDiffByDirection(-1));
                debugPrint(
                    'Navigating to previous diff at index ${currentIndex - 1}');
              }
            },
            tooltip: 'Предыдущее отличие',
          ),
          Text(
            totalChanges == 0
                ? 'Нет изменений'
                : '${currentIndex + 1} из $totalChanges отличий',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              if (currentIndex < totalChanges - 1) {
                context.read<GCodeDiffBloc>().add(NavigateToDiffByDirection(1));
                debugPrint(
                    'Navigating to next diff at index ${currentIndex + 1}');
              }
            },
            tooltip: 'Следующее отличие',
          ),
        ],
      ),
    );
  }
}
