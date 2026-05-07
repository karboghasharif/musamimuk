class SelectionPopupModel {
  SelectionPopupModel(
      {this.id, required this.title, this.value, this.isSelected = false});
  int? id;
  String title;
  dynamic value;
  bool isSelected;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectionPopupModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
