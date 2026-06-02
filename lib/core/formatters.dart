import 'package:intl/intl.dart';

const weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

final _yenFormat = NumberFormat('#,##0', 'ja_JP');

String formatYen(int value) => '¥${_yenFormat.format(value)}';

String weekdayText(Set<int> days) {
  if (days.isEmpty) return '特売日未設定';
  final sorted = days.toList()..sort();
  return sorted.map((day) => weekdayLabels[day - 1]).join('・');
}
