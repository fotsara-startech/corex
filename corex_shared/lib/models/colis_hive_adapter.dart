import 'package:hive/hive.dart';
import 'colis_model.dart';

/// Adaptateur Hive pour ColisModel
class ColisModelAdapter extends TypeAdapter<ColisModel> {
  @override
  final int typeId = 0;

  @override
  ColisModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return ColisModel(
      id: fields[0] as String,
      numeroSuivi: fields[1] as String,
      expediteurNom: fields[2] as String,
      expediteurTelephone: fields[3] as String,
      expediteurAdresse: fields[4] as String,
      destinataireNom: fields[5] as String,
      destinataireTelephone: fields[6] as String,
      destinataireAdresse: fields[7] as String,
      destinataireVille: fields[8] as String,
      destinataireQuartier: fields[9] as String?,
      contenu: fields[10] as String,
      poids: fields[11] as double,
      dimensions: fields[12] as String?,
      montantTarif: fields[13] as double,
      isPaye: fields[14] as bool,
      datePaiement: fields[15] as DateTime?,
      modeLivraison: fields[16] as String,
      zoneId: fields[17] as String?,
      agenceTransportId: fields[18] as String?,
      agenceTransportNom: fields[19] as String?,
      tarifAgenceTransport: fields[20] as double?,
      statut: fields[21] as String,
      agenceCorexId: fields[22] as String,
      commercialId: fields[23] as String,
      coursierId: fields[24] as String?,
      dateCollecte: fields[25] as DateTime,
      dateEnregistrement: fields[26] as DateTime?,
      dateLivraison: fields[27] as DateTime?,
      historique: (fields[28] as List).cast<HistoriqueStatut>(),
      commentaire: fields[29] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ColisModel obj) {
    writer
      ..writeByte(30)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.numeroSuivi)
      ..writeByte(2)
      ..write(obj.expediteurNom)
      ..writeByte(3)
      ..write(obj.expediteurTelephone)
      ..writeByte(4)
      ..write(obj.expediteurAdresse)
      ..writeByte(5)
      ..write(obj.destinataireNom)
      ..writeByte(6)
      ..write(obj.destinataireTelephone)
      ..writeByte(7)
      ..write(obj.destinataireAdresse)
      ..writeByte(8)
      ..write(obj.destinataireVille)
      ..writeByte(9)
      ..write(obj.destinataireQuartier)
      ..writeByte(10)
      ..write(obj.contenu)
      ..writeByte(11)
      ..write(obj.poids)
      ..writeByte(12)
      ..write(obj.dimensions)
      ..writeByte(13)
      ..write(obj.montantTarif)
      ..writeByte(14)
      ..write(obj.isPaye)
      ..writeByte(15)
      ..write(obj.datePaiement)
      ..writeByte(16)
      ..write(obj.modeLivraison)
      ..writeByte(17)
      ..write(obj.zoneId)
      ..writeByte(18)
      ..write(obj.agenceTransportId)
      ..writeByte(19)
      ..write(obj.agenceTransportNom)
      ..writeByte(20)
      ..write(obj.tarifAgenceTransport)
      ..writeByte(21)
      ..write(obj.statut)
      ..writeByte(22)
      ..write(obj.agenceCorexId)
      ..writeByte(23)
      ..write(obj.commercialId)
      ..writeByte(24)
      ..write(obj.coursierId)
      ..writeByte(25)
      ..write(obj.dateCollecte)
      ..writeByte(26)
      ..write(obj.dateEnregistrement)
      ..writeByte(27)
      ..write(obj.dateLivraison)
      ..writeByte(28)
      ..write(obj.historique)
      ..writeByte(29)
      ..write(obj.commentaire);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ColisModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

/// Adaptateur Hive pour HistoriqueStatut
class HistoriqueStatutAdapter extends TypeAdapter<HistoriqueStatut> {
  @override
  final int typeId = 1;

  @override
  HistoriqueStatut read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return HistoriqueStatut(
      statut: fields[0] as String,
      date: fields[1] as DateTime,
      userId: fields[2] as String,
      commentaire: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HistoriqueStatut obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.statut)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.commentaire);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is HistoriqueStatutAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
