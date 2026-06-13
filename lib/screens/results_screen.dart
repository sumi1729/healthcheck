import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/results_viewmodel.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ResultsViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: vm.selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (date != null && context.mounted) {
                context.read<ResultsViewModel>().setDate(date);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today,
                      color: Color(0xFF4CAF50), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(vm.selectedDate),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (vm.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _ResultsTable(rows: vm.rows),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}年${dt.month}月${dt.day}日';
}

class _ResultsTable extends StatelessWidget {
  final List<ResultRow> rows;

  const _ResultsTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      color: Color(0xFF4CAF50),
      fontWeight: FontWeight.bold,
      fontSize: 13,
    );
    const cellStyle = TextStyle(color: Colors.white, fontSize: 13);

    return Table(
      border: TableBorder.all(color: const Color(0xFF424242)),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(3),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF2A2A2A)),
          children: [
            _cell('項目', headerStyle),
            _cell('開始時刻', headerStyle),
            _cell('終了時刻', headerStyle),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              _cell(row.label, cellStyle),
              _timeCell(row.start),
              _timeCell(row.end),
            ],
          ),
      ],
    );
  }

  // 「前日」有無や列に依らず行の高さ・ベースラインを揃えるため strut を固定する。
  static const _strut = StrutStyle(fontSize: 13, forceStrutHeight: true);

  Widget _cell(String text, TextStyle style) {
    return _pad(Text(text,
        style: style, strutStyle: _strut, textAlign: TextAlign.center));
  }

  Widget _timeCell(TimeCell cell) {
    const cellStyle = TextStyle(color: Colors.white, fontSize: 13);
    final dt = cell.dateTime;
    if (dt == null) {
      return _pad(const Text('－',
          style: cellStyle, strutStyle: _strut, textAlign: TextAlign.center));
    }
    final time =
        '${dt.hour.toString().padLeft(2, '0')}時${dt.minute.toString().padLeft(2, '0')}分';
    return _pad(Text.rich(
      TextSpan(children: [
        TextSpan(text: time, style: cellStyle),
        if (cell.isPreviousDay)
          const TextSpan(
            text: '（前日）',
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
      ]),
      strutStyle: _strut,
      textAlign: TextAlign.center,
    ));
  }

  Widget _pad(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: child,
    );
  }
}
