import 'package:flutter/material.dart';
import '../models/stats_period.dart';

class PeriodChips extends StatelessWidget {
  final StatsPeriod selected;
  final ValueChanged<StatsPeriod> onChanged;
  final Color color;

  const PeriodChips({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final p in StatsPeriod.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(p.label, style: const TextStyle(fontSize: 12)),
                selected: selected == p,
                selectedColor: color.withOpacity(0.18),
                onSelected: (_) => onChanged(p),
              ),
            ),
        ],
      ),
    );
  }
}