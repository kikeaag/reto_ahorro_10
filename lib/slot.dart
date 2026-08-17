import 'package:hive/hive.dart';

/// Modelo para representar un "slot" de dinero.
/// Campos: id (String), checked (bool), amount (double)
class Slot {
  String id;
  bool checked;
  double amount;

  Slot({required this.id, required this.checked, required this.amount});

  @override
  String toString() => 'Slot(id: $id, checked: $checked, amount: $amount)';
}

/// Adapter manual para Hive. typeId debe ser único en la aplicación.
class SlotAdapter extends TypeAdapter<Slot> {
  @override
  final int typeId = 0;

  @override
  Slot read(BinaryReader reader) {
    final id = reader.readString();
    final checked = reader.readBool();
    final amount = reader.readDouble();
    return Slot(id: id, checked: checked, amount: amount);
  }

  @override
  void write(BinaryWriter writer, Slot obj) {
    writer.writeString(obj.id);
    writer.writeBool(obj.checked);
    writer.writeDouble(obj.amount);
  }
}
