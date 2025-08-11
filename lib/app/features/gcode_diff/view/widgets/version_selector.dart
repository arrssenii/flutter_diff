import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/gcode_diff_bloc.dart';

class VersionSelector extends StatelessWidget {
  const VersionSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GCodeDiffBloc, GCodeDiffState>(
      builder: (context, state) {
        if (state is! GCodeDiffLoaded || state.versions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: DropdownButton<String>(
            value: state.selectedVersionId,
            icon: const Icon(Icons.history),
            hint: const Text('Версии'),
            onChanged: (versionId) {
              if (versionId != null) {
                context.read<GCodeDiffBloc>().add(
                      SelectHistoricalVersion(versionId: versionId),
                    );
              }
            },
            items: state.versions.map((version) {
              return DropdownMenuItem<String>(
                value: version.id,
                child: Text(
                  version.name,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}