import 'package:flutter/material.dart';
import 'table_row_model.dart';

class ExamTable extends StatelessWidget {
  final List<TableRowModel> rows;

  const ExamTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1A3A5C), width: 1.5),
      ),
      child: Column(
        children: rows.map((row) => _buildRow(row)).toList(),
      ),
    );
  }

  Widget _buildRow(TableRowModel row) {
    return Container(
      decoration: BoxDecoration(
        border: row.isLast
            ? null
            : const Border(
          bottom: BorderSide(color: Color(0xFF1A3A5C), width: 0.8),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 140,
              padding: const EdgeInsets.all(10),

              child: Text(
                row.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A3A5C),
                ),
              ),
            ),
            Container(width: 1.5, color: const Color(0xFF1A3A5C)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(   maxLines: 2,row.value?.toString() ?? '—'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}