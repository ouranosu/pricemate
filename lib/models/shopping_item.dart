import 'enums.dart';

class ShoppingItem {
  ShoppingItem({
    required this.id,
    required this.name,
    required this.urgency,
    this.checked = false,
  });

  final String id;
  final String name;
  final Urgency urgency;
  final bool checked;

  ShoppingItem copyWith({String? name, Urgency? urgency, bool? checked}) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      urgency: urgency ?? this.urgency,
      checked: checked ?? this.checked,
    );
  }
}
