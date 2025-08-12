import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_gcode/domain/usecases/compare_gcode_usecase.dart';
import 'package:test_gcode/domain/usecases/get_gcode_versions_usecase.dart';
import 'package:test_gcode/domain/usecases/save_reference_usecase.dart';
import 'package:test_gcode/presentation/features/gcode_diff/bloc/gcode_diff_bloc.dart';
import 'package:test_gcode/presentation/features/gcode_diff/bloc/gcode_diff_event.dart';
import 'package:test_gcode/presentation/features/gcode_diff/bloc/gcode_diff_state.dart';
import 'widgets/diff_pane.dart';
import 'widgets/api_diff_pane.dart';
import 'widgets/diff_navigation_controls.dart';

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
    // Try to load from API first
    context.read<GCodeDiffBloc>().add(LoadLastChanges(int.parse(widget.controllerId)));
    
    // Fallback to local files if API fails
    context.read<GCodeDiffBloc>().add(LoadGCodeDiff(
      reference: 'assets/gcode/reference.gcode',
      modified: 'assets/gcode/modified.gcode',
      controllerId: widget.controllerId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сравнение G-code для ${widget.controllerId}'),
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
            return Column(
              children: [
                DiffNavigationControls(
                  currentIndex: state.currentChangeIndex,
                  totalChanges: state.diff.changes.length,
                ),
                Expanded(
                  child: DiffPane(
                    diff: state.diff,
                    currentDiffIndex: state.currentChangeIndex,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () => _confirmAcceptChanges(context),
                    child: const Text('Принять изменения'),
                  ),
                ),
              ],
            );
          }
          
          if (state is GCodeApiDiffLoaded) {
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
              context.read<GCodeDiffBloc>().add(AcceptChanges(widget.controllerId));
              Navigator.pop(ctx);
            },
            child: const Text('Принять'),
          ),
        ],
      ),
    );
  }
}