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
              _cell(row.label, cellStyle, vertical: _dataVertical),
              _timeCell(context, row.start, vertical: _dataVertical),
              _timeCell(context, row.end, vertical: _dataVertical),
            ],
          ),
      ],
    );
  }

  // 「前日」有無や列に依らず行の高さ・ベースラインを揃えるため strut を固定する。
  static const _strut = StrutStyle(fontSize: 13, forceStrutHeight: true);

  // ヘッダー行の縦余白。データ行はこの約1.3倍の高さにする。
  static const _headerVertical = 10.0;
  static const _dataVertical = 15.0;

  Widget _cell(String text, TextStyle style, {double vertical = _headerVertical}) {
    return _pad(
        Text(text, style: style, strutStyle: _strut, textAlign: TextAlign.center),
        vertical: vertical);
  }

  Widget _timeCell(BuildContext context, TimeCell cell,
      {double vertical = _headerVertical}) {
    const cellStyle = TextStyle(color: Colors.white, fontSize: 13);
    final dt = cell.dateTime;
    final Widget content;
    if (dt == null) {
      content = const Text('－',
          style: cellStyle, strutStyle: _strut, textAlign: TextAlign.center);
    } else {
      final time =
          '${dt.hour.toString().padLeft(2, '0')}時${dt.minute.toString().padLeft(2, '0')}分';
      content = Text.rich(
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
      );
    }
    // セルをタップで日時編集（カレンダー → 時計）。データの有無に関わらず編集可。
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _editCell(context, cell),
      child: _pad(content, vertical: vertical),
    );
  }

  /// セルをタップしたとき:
  /// 既に日時が入っている場合はまず「実績を削除しますか？」を確認し、
  ///   はい → 削除（画面・DB）、いいえ → 編集（カレンダー → 時計）へ。
  /// 未登録（「－」）の場合はそのまま編集へ。
  Future<void> _editCell(BuildContext context, TimeCell cell) async {
    final vm = context.read<ResultsViewModel>();

    if (cell.dateTime != null) {
      final delete = await _confirmDelete(context);
      if (delete == null || !context.mounted) return;
      if (delete) {
        await vm.deleteCell(cell);
        return;
      }
    }

    final base = cell.dateTime ?? vm.selectedDate;
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(cell.dateTime ?? DateTime.now()),
    );
    if (time == null || !context.mounted) return;
    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await vm.editCell(cell, dt);
  }

  /// 「実績を削除しますか？」の確認ダイアログ。
  /// はい=true / いいえ=false / ダイアログ外タップ=null。
  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('実績を削除しますか？',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('いいえ',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('はい',
                style: TextStyle(color: Color(0xFF4CAF50))),
          ),
        ],
      ),
    );
  }

  Widget _pad(Widget child, {double vertical = _headerVertical}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: vertical),
      child: child,
    );
  }
}
