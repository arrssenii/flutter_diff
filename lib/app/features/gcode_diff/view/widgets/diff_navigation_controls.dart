import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/gcode_diff_bloc.dart';

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
            onPressed: () => context.read<GCodeDiffBloc>().add(
                  NavigateToDiff(direction: -1),
                ),
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
            onPressed: () => context.read<GCodeDiffBloc>().add(
                  NavigateToDiff(direction: 1),
                ),
            tooltip: 'Следующее отличие',
          ),
        ],
      ),
    );
  }
}