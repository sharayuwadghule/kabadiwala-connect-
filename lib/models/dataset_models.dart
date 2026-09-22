// Material Dataset
class MaterialDatasetRecord {
  const MaterialDatasetRecord({
    required this.categoryId,
    required this.nameEn,
    required this.nameHi,
    required this.nameMr,
    required this.description,
    required this.basePricePerKg,
  });

  final String categoryId;
  final String nameEn;
  final String nameHi;
  final String nameMr;
  final String description;
  final double basePricePerKg;

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'nameEn': nameEn,
        'nameHi': nameHi,
        'nameMr': nameMr,
        'description': description,
        'basePricePerKg': basePricePerKg,
      };
}

// Price Dataset
class PriceDatasetRecord {
  const PriceDatasetRecord({
    required this.materialId,
    required this.location,
    required this.date,
    required this.buyingPrice,
    required this.marketRangeLow,
    required this.marketRangeHigh,
    required this.unit,
  });

  final String materialId;
  final String location;
  final DateTime date;
  final double buyingPrice;
  final double marketRangeLow;
  final double marketRangeHigh;
  final String unit;

  Map<String, dynamic> toJson() => {
        'materialId': materialId,
        'location': location,
        'date': date.toIso8601String(),
        'buyingPrice': buyingPrice,
        'marketRangeLow': marketRangeLow,
        'marketRangeHigh': marketRangeHigh,
        'unit': unit,
      };
}

// Recycler Dataset
class RecyclerDatasetRecord {
  const RecyclerDatasetRecord({
    required this.recyclerId,
    required this.name,
    required this.location,
    required this.acceptedMaterials,
    required this.authorizationStatus,
    required this.contact,
    required this.pickupAvailable,
    required this.serviceArea,
  });

  final String recyclerId;
  final String name;
  final String location;
  final List<String> acceptedMaterials;
  final String authorizationStatus;
  final String contact;
  final bool pickupAvailable;
  final String serviceArea;

  Map<String, dynamic> toJson() => {
        'recyclerId': recyclerId,
        'name': name,
        'location': location,
        'acceptedMaterials': acceptedMaterials,
        'authorizationStatus': authorizationStatus,
        'contact': contact,
        'pickupAvailable': pickupAvailable,
        'serviceArea': serviceArea,
      };
}

// Transaction Dataset
class TransactionDatasetRecord {
  const TransactionDatasetRecord({
    required this.lotId,
    required this.collectorId, // will be anonymized
    required this.materialIds,
    required this.totalWeightKg,
    required this.quotedPrice,
    required this.finalPrice,
    required this.recyclerId,
    required this.collectionLocation,
    required this.handoverLocation,
    required this.timestamp,
    required this.paymentStatus,
    required this.transactionStatus,
  });

  final String lotId;
  final String collectorId;
  final List<String> materialIds;
  final double totalWeightKg;
  final double quotedPrice;
  final double? finalPrice;
  final String recyclerId;
  final String collectionLocation;
  final String handoverLocation;
  final DateTime timestamp;
  final String paymentStatus;
  final String transactionStatus;

  Map<String, dynamic> toJson() => {
        'lotId': lotId,
        'collectorId': collectorId,
        'materialIds': materialIds,
        'totalWeightKg': totalWeightKg,
        'quotedPrice': quotedPrice,
        'finalPrice': finalPrice,
        'recyclerId': recyclerId,
        'collectionLocation': collectionLocation,
        'handoverLocation': handoverLocation,
        'timestamp': timestamp.toIso8601String(),
        'paymentStatus': paymentStatus,
        'transactionStatus': transactionStatus,
      };
}

// Traceability Dataset
class TraceabilityDatasetRecord {
  const TraceabilityDatasetRecord({
    required this.lotId,
    required this.photos,
    required this.weightKg,
    required this.timestamp,
    required this.gpsCoords,
    required this.handoverReference,
    required this.recyclerConfirmed,
    required this.statusHistory,
  });

  final String lotId;
  final List<String> photos; // URIs
  final double weightKg;
  final DateTime timestamp;
  final String gpsCoords;
  final String handoverReference;
  final bool recyclerConfirmed;
  final List<String> statusHistory;

  Map<String, dynamic> toJson() => {
        'lotId': lotId,
        'photos': photos,
        'weightKg': weightKg,
        'timestamp': timestamp.toIso8601String(),
        'gpsCoords': gpsCoords,
        'handoverReference': handoverReference,
        'recyclerConfirmed': recyclerConfirmed,
        'statusHistory': statusHistory,
      };
}

// Collector Dataset (Anonymized)
class CollectorDatasetRecord {
  const CollectorDatasetRecord({
    required this.collectorId,
    required this.language,
    required this.generalArea,
    required this.transactionCount,
    required this.totalEarnings,
  });

  final String collectorId; // Anonymized hash
  final String language;
  final String generalArea;
  final int transactionCount;
  final double totalEarnings;

  Map<String, dynamic> toJson() => {
        'collectorId': collectorId,
        'language': language,
        'generalArea': generalArea,
        'transactionCount': transactionCount,
        'totalEarnings': totalEarnings,
      };
}
