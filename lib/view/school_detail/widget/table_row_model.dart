class TableRowModel {
  final String label;
  final dynamic value;
  final bool isLast;

  TableRowModel({
    required this.label,
    required this.value,
    this.isLast = false,
  });
}