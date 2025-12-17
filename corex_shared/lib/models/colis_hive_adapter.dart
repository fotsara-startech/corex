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

    try {
      // Gestion de la migration : ancien format (30 champs) vs nouveau format (35 champs)
      if (numOfFields == 30) {
        // Ancien format - mapper vers le nouveau format
        print('🔄 [HIVE_ADAPTER] Migration ancien format (30 champs) vers nouveau format');
        return ColisModel(
          id: fields[0] as String,
          numeroSuivi: fields[1] as String,
          expediteurNom: fields[2] as String,
          expediteurTelephone: fields[3] as String,
          expediteurEmail: null, // Nouveau champ - pas dans l'ancien format
          expediteurAdresse: fields[4] as String,
          destinataireNom: fields[5] as String,
          destinataireTelephone: fields[6] as String,
          destinataireEmail: null, // Nouveau champ - pas dans l'ancien format
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
          isRetour: false, // Nouveau champ - valeur par défaut
          colisInitialId: null, // Nouveau champ - pas dans l'ancien format
          retourId: null, // Nouveau champ - pas dans l'ancien format
        );
      } else {
        // Nouveau format (35 champs)
        return ColisModel(
          id: fields[0] as String,
          numeroSuivi: fields[1] as String,
          expediteurNom: fields[2] as String,
          expediteurTelephone: fields[3] as String,
          expediteurEmail: fields[4] as String?,
          expediteurAdresse: fields[5] as String,
          destinataireNom: fields[6] as String,
          destinataireTelephone: fields[7] as String,
          destinataireEmail: fields[8] as String?,
          destinataireAdresse: fields[9] as String,
          destinataireVille: fields[10] as String,
          destinataireQuartier: fields[11] as String?,
          contenu: fields[12] as String,
          poids: fields[13] as double,
          dimensions: fields[14] as String?,
          montantTarif: fields[15] as double,
          isPaye: fields[16] as bool,
          datePaiement: fields[17] as DateTime?,
          modeLivraison: fields[18] as String,
          zoneId: fields[19] as String?,
          agenceTransportId: fields[20] as String?,
          agenceTransportNom: fields[21] as String?,
          tarifAgenceTransport: fields[22] as double?,
          statut: fields[23] as String,
          agenceCorexId: fields[24] as String,
          commercialId: fields[25] as String,
          coursierId: fields[26] as String?,
          dateCollecte: fields[27] as DateTime,
          dateEnregistrement: fields[28] as DateTime?,
          dateLivraison: fields[29] as DateTime?,
          historique: (fields[30] as List).cast<HistoriqueStatut>(),
          commentaire: fields[31] as String?,
          isRetour: fields[32] as bool? ?? false,
          colisInitialId: fields[33] as String?,
          retourId: fields[34] as String?,
        );
      }
    } catch (e) {
      print('❌ [HIVE_ADAPTER] Erreur lecture colis: $e');
      print('📊 [HIVE_ADAPTER] Nombre de champs: $numOfFields');
      print('🔍 [HIVE_ADAPTER] Champs disponibles: ${fields.keys.toList()}');
      rethrow;
    }
  }

  @override
  void write(BinaryWriter writer, ColisModel obj) {
    writer
      ..writeByte(35)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.numeroSuivi)
      ..writeByte(2)
      ..write(obj.expediteurNom)
      ..writeByte(3)
      ..write(obj.expediteurTelephone)
      ..writeByte(4)
      ..write(obj.expediteurEmail)
      ..writeByte(5)
      ..write(obj.expediteurAdresse)
      ..writeByte(6)
      ..write(obj.destinataireNom)
      ..writeByte(7)
      ..write(obj.destinataireTelephone)
      ..writeByte(8)
      ..write(obj.destinataireEmail)
      ..writeByte(9)
      ..write(obj.destinataireAdresse)
      ..writeByte(10)
      ..write(obj.destinataireVille)
      ..writeByte(11)
      ..write(obj.destinataireQuartier)
      ..writeByte(12)
      ..write(obj.contenu)
      ..writeByte(13)
      ..write(obj.poids)
      ..writeByte(14)
      ..write(obj.dimensions)
      ..writeByte(15)
      ..write(obj.montantTarif)
      ..writeByte(16)
      ..write(obj.isPaye)
      ..writeByte(17)
      ..write(obj.datePaiement)
      ..writeByte(18)
      ..write(obj.modeLivraison)
      ..writeByte(19)
      ..write(obj.zoneId)
      ..writeByte(20)
      ..write(obj.agenceTransportId)
      ..writeByte(21)
      ..write(obj.agenceTransportNom)
      ..writeByte(22)
      ..write(obj.tarifAgenceTransport)
      ..writeByte(23)
      ..write(obj.statut)
      ..writeByte(24)
      ..write(obj.agenceCorexId)
      ..writeByte(25)
      ..write(obj.commercialId)
      ..writeByte(26)
      ..write(obj.coursierId)
      ..writeByte(27)
      ..write(obj.dateCollecte)
      ..writeByte(28)
      ..write(obj.dateEnregistrement)
      ..writeByte(29)
      ..write(obj.dateLivraison)
      ..writeByte(30)
      ..write(obj.historique)
      ..writeByte(31)
      ..write(obj.commentaire)
      ..writeByte(32)
      ..write(obj.isRetour)
      ..writeByte(33)
      ..write(obj.colisInitialId)
      ..writeByte(34)
      ..write(obj.retourId);
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
