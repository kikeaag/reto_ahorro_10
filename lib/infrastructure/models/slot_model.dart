import 'package:hive/hive.dart';
import 'package:money_challenge/domain/entities/slot.dart';

/// Adaptador de Hive para la entidad [Slot].
///
/// **Invariantes críticos** (ver AGENTS.md): no cambiar ni reutilizar el
/// `typeId` (corrompe los datos leídos del disco) ni el orden de los campos
/// (`writeString`, `writeBool`, `writeDouble`).
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
