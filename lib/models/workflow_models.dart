import 'dart:convert';
import 'dart:typed_data';

enum CollectionMode { batch, single }

enum LotStatus {
  draft,
  pendingSync,
  lotCreated,
  recyclerSelected,
  pickupRequested,
  handoverPending,
  received,
  paymentPending,
  paid,
  completed,
  rejected,
  disputed,
  sorted,
  processed,
  recoveredDownstream,
}

enum PaymentMethod { cash, upi }

enum PaymentStatus { pending, paid }

enum SyncState { local, pending, syncing, synced, failed }

String enumName(Enum value) => value.name;

T enumByName<T extends Enum>(List<T> values, Object? value, T fallback) =>
    values.where((item) => item.name == value).firstOrNull ?? fallback;

enum UserRole { collector, aggregator, recycler }

class CollectorProfile {
  const CollectorProfile({
    required this.collectorId,
    required this.language,
    required this.operatingLocation,
    this.collectorName = '',
    this.role = UserRole.collector,
  });

  final String collectorId;
  final String collectorName;
  final String language;
  final String operatingLocation;
  final UserRole role;

  Map<String, dynamic> toJson() => {
        'collectorId': collectorId,
        'collectorName': collectorName,
        'language': language,
        'operatingLocation': operatingLocation,
        'role': role.name,
      };

  factory CollectorProfile.fromJson(Map<String, dynamic> json) =>
      CollectorProfile(
        collectorId: json['collectorId']?.toString() ?? '',
        collectorName: json['collectorName']?.toString() ?? '',
        language: json['language']?.toString() ?? 'mr',
        operatingLocation: json['operatingLocation']?.toString() ?? '',
        role: enumByName(UserRole.values, json['role'], UserRole.collector),
      );
}

class RecyclerProfile {
  const RecyclerProfile({
    required this.recyclerId,
    required this.facilityName,
    required this.facilityLocation,
    required this.authorizationNumber,
    required this.materialsAccepted,
  });

  final String recyclerId;
  final String facilityName;
  final String facilityLocation;
  final String authorizationNumber;
  final List<String> materialsAccepted;

  Map<String, dynamic> toJson() => {
        'recyclerId': recyclerId,
        'facilityName': facilityName,
        'facilityLocation': facilityLocation,
        'authorizationNumber': authorizationNumber,
        'materialsAccepted': materialsAccepted,
      };

  factory RecyclerProfile.fromJson(Map<String, dynamic> json) =>
      RecyclerProfile(
        recyclerId: json['recyclerId']?.toString() ?? '',
        facilityName: json['facilityName']?.toString() ?? '',
        facilityLocation: json['facilityLocation']?.toString() ?? '',
        authorizationNumber: json['authorizationNumber']?.toString() ?? '',
        materialsAccepted: List<String>.from(json['materialsAccepted'] ?? []),
      );
}

class MaterialDefinition {
  const MaterialDefinition({
    required this.id,
    required this.category,
    required this.subcategory,
    required this.names,
    required this.icon,
    required this.description,
    required this.recoverableMaterials,
    required this.hazardous,
    required this.handling,
  });

  final String id;
  final String category;
  final String subcategory;
  final Map<String, String> names;
  final IconSeed icon;
  final String description;
  final List<String> recoverableMaterials;
  final bool hazardous;
  final List<String> handling;

  String name(String language) => names[language] ?? names['en'] ?? category;
}

enum IconSeed {
  memory,
  cable,
  battery,
  television,
  display,
  motor,
  magnet,
  plastic,
}

class DraftImage {
  DraftImage({required this.id, required this.bytes, required this.source});

  final String id;
  final Uint8List bytes;
  final String source;
}

class LotMaterial {
  const LotMaterial({
    required this.materialId,
    required this.quantity,
    required this.weightKg,
    required this.condition,
    required this.sourceType,
    required this.confidence,
    required this.imageIds,
    required this.estimatedValue,
    required this.quotedRate,
    this.detectedMaterialId,
  });

  final String materialId;
  final int quantity;
  final double weightKg;
  final String condition;
  final String sourceType;
  final double confidence;
  final List<String> imageIds;
  final double estimatedValue;
  final double quotedRate;
  final String? detectedMaterialId;

  LotMaterial copyWith({
    int? quantity,
    double? weightKg,
    String? condition,
    String? sourceType,
    double? confidence,
    List<String>? imageIds,
    double? estimatedValue,
    double? quotedRate,
    String? detectedMaterialId,
  }) =>
      LotMaterial(
        materialId: materialId,
        quantity: quantity ?? this.quantity,
        weightKg: weightKg ?? this.weightKg,
        condition: condition ?? this.condition,
        sourceType: sourceType ?? this.sourceType,
        confidence: confidence ?? this.confidence,
        imageIds: imageIds ?? this.imageIds,
        estimatedValue: estimatedValue ?? this.estimatedValue,
        quotedRate: quotedRate ?? this.quotedRate,
        detectedMaterialId: detectedMaterialId ?? this.detectedMaterialId,
      );

  Map<String, dynamic> toJson() => {
        'materialId': materialId,
        'quantity': quantity,
        'weightKg': weightKg,
        'condition': condition,
        'sourceType': sourceType,
        'confidence': confidence,
        'imageIds': imageIds,
        'estimatedValue': estimatedValue,
        'quotedRate': quotedRate,
        'detectedMaterialId': detectedMaterialId,
      };

  factory LotMaterial.fromJson(Map<String, dynamic> json) => LotMaterial(
        materialId: json['materialId']?.toString() ?? 'mixed_plastics',
        quantity: (json['quantity'] as num?)?.round() ?? 1,
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
        condition: json['condition']?.toString() ?? 'mixed',
        sourceType: json['sourceType']?.toString() ?? 'manual',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        imageIds: (json['imageIds'] as List?)?.cast<String>() ?? const [],
        estimatedValue: (json['estimatedValue'] as num?)?.toDouble() ?? 0,
        quotedRate: (json['quotedRate'] as num?)?.toDouble() ?? 0,
        detectedMaterialId: json['detectedMaterialId']?.toString(),
      );
}

class LocationRecord {
  const LocationRecord({this.latitude, this.longitude, required this.label});

  final double? latitude;
  final double? longitude;
  final String label;
  bool get available => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'label': label,
      };

  factory LocationRecord.fromJson(Map<String, dynamic>? json) => LocationRecord(
        latitude: (json?['latitude'] as num?)?.toDouble(),
        longitude: (json?['longitude'] as num?)?.toDouble(),
        label: json?['label']?.toString() ?? 'Location unavailable',
      );
}

class StatusEvent {
  const StatusEvent({required this.status, required this.at, this.note = ''});
  final LotStatus status;
  final DateTime at;
  final String note;

  Map<String, dynamic> toJson() =>
      {'status': status.name, 'at': at.toIso8601String(), 'note': note};

  factory StatusEvent.fromJson(Map<String, dynamic> json) => StatusEvent(
        status: enumByName(LotStatus.values, json['status'], LotStatus.draft),
        at: DateTime.tryParse(json['at']?.toString() ?? '') ?? DateTime.now(),
        note: json['note']?.toString() ?? '',
      );
}

class DigitalLot {
  const DigitalLot({
    required this.lotId,
    required this.handoverReference,
    required this.collectorId,
    required this.createdAt,
    required this.materials,
    required this.imageBase64,
    required this.handoverImageBase64,
    required this.collectionLocation,
    required this.handoverLocation,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.syncState,
    required this.selectedRecyclerId,
    required this.selectedRecyclerName,
    required this.totalEstimatedValue,
    required this.finalWeightKg,
    required this.finalSaleValue,
    required this.recyclerConfirmed,
    required this.statusHistory,
    this.lastSyncError = '',
    this.offers = const [],
    this.agreement,
    this.agreedPrice,
    this.sourceLotIds,
  });

  final String lotId;
  final String handoverReference;
  final String collectorId;
  final DateTime createdAt;
  final List<LotMaterial> materials;
  final List<String> imageBase64;
  final String? handoverImageBase64;
  final LocationRecord collectionLocation;
  final LocationRecord handoverLocation;
  final LotStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final SyncState syncState;
  final String selectedRecyclerId;
  final String selectedRecyclerName;
  final double totalEstimatedValue;
  final double? finalWeightKg;
  final double? finalSaleValue;
  final bool recyclerConfirmed;
  final List<StatusEvent> statusHistory;
  final String lastSyncError;
  final List<RecyclerOffer> offers;
  final DigitalAgreement? agreement;
  final double? agreedPrice;
  final List<String>? sourceLotIds;

  double get totalWeightKg =>
      materials.fold(0, (sum, material) => sum + material.weightKg);
  double get ledgerValue => finalSaleValue ?? totalEstimatedValue;
  double get paidAmount =>
      paymentStatus == PaymentStatus.paid ? ledgerValue : 0;
  double get pendingAmount =>
      paymentStatus == PaymentStatus.paid ? 0 : ledgerValue;

  DigitalLot copyWith({
    LotStatus? status,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    SyncState? syncState,
    String? selectedRecyclerId,
    String? selectedRecyclerName,
    String? handoverImageBase64,
    LocationRecord? handoverLocation,
    double? finalWeightKg,
    double? finalSaleValue,
    bool? recyclerConfirmed,
    List<StatusEvent>? statusHistory,
    String? lastSyncError,
    List<RecyclerOffer>? offers,
    DigitalAgreement? agreement,
    double? agreedPrice,
    List<String>? sourceLotIds,
  }) =>
      DigitalLot(
        lotId: lotId,
        handoverReference: handoverReference,
        collectorId: collectorId,
        createdAt: createdAt,
        materials: materials,
        imageBase64: imageBase64,
        handoverImageBase64: handoverImageBase64 ?? this.handoverImageBase64,
        collectionLocation: collectionLocation,
        handoverLocation: handoverLocation ?? this.handoverLocation,
        status: status ?? this.status,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        syncState: syncState ?? this.syncState,
        selectedRecyclerId: selectedRecyclerId ?? this.selectedRecyclerId,
        selectedRecyclerName: selectedRecyclerName ?? this.selectedRecyclerName,
        totalEstimatedValue: totalEstimatedValue,
        finalWeightKg: finalWeightKg ?? this.finalWeightKg,
        finalSaleValue: finalSaleValue ?? this.finalSaleValue,
        recyclerConfirmed: recyclerConfirmed ?? this.recyclerConfirmed,
        statusHistory: statusHistory ?? this.statusHistory,
        lastSyncError: lastSyncError ?? this.lastSyncError,
        offers: offers ?? this.offers,
        agreement: agreement ?? this.agreement,
        agreedPrice: agreedPrice ?? this.agreedPrice,
        sourceLotIds: sourceLotIds ?? this.sourceLotIds,
      );

  Map<String, dynamic> toJson() => {
        'lotId': lotId,
        'handoverReference': handoverReference,
        'collectorId': collectorId,
        'createdAt': createdAt.toIso8601String(),
        'materials': materials.map((item) => item.toJson()).toList(),
        'imageBase64': imageBase64,
        'handoverImageBase64': handoverImageBase64,
        'collectionLocation': collectionLocation.toJson(),
        'handoverLocation': handoverLocation.toJson(),
        'status': status.name,
        'paymentMethod': paymentMethod.name,
        'paymentStatus': paymentStatus.name,
        'syncState': syncState.name,
        'selectedRecyclerId': selectedRecyclerId,
        'selectedRecyclerName': selectedRecyclerName,
        'totalEstimatedValue': totalEstimatedValue,
        'finalWeightKg': finalWeightKg,
        'finalSaleValue': finalSaleValue,
        'recyclerConfirmed': recyclerConfirmed,
        'statusHistory': statusHistory.map((event) => event.toJson()).toList(),
        'lastSyncError': lastSyncError,
        'offers': offers.map((offer) => offer.toJson()).toList(),
        'agreement': agreement?.toJson(),
        'agreedPrice': agreedPrice,
        'sourceLotIds': sourceLotIds,
      };

  factory DigitalLot.fromJson(Map<String, dynamic> json) => DigitalLot(
        lotId: json['lotId']?.toString() ?? '',
        handoverReference: json['handoverReference']?.toString() ?? '',
        collectorId: json['collectorId']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        materials: (json['materials'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(LotMaterial.fromJson)
            .toList(),
        imageBase64: (json['imageBase64'] as List?)?.cast<String>() ?? const [],
        handoverImageBase64: json['handoverImageBase64']?.toString(),
        collectionLocation: LocationRecord.fromJson(
            json['collectionLocation'] as Map<String, dynamic>?),
        handoverLocation: LocationRecord.fromJson(
            json['handoverLocation'] as Map<String, dynamic>?),
        status:
            enumByName(LotStatus.values, json['status'], LotStatus.lotCreated),
        paymentMethod: enumByName(
            PaymentMethod.values, json['paymentMethod'], PaymentMethod.cash),
        paymentStatus: enumByName(
            PaymentStatus.values, json['paymentStatus'], PaymentStatus.pending),
        syncState:
            enumByName(SyncState.values, json['syncState'], SyncState.pending),
        selectedRecyclerId: json['selectedRecyclerId']?.toString() ?? '',
        selectedRecyclerName: json['selectedRecyclerName']?.toString() ?? '',
        totalEstimatedValue:
            (json['totalEstimatedValue'] as num?)?.toDouble() ?? 0,
        finalWeightKg: (json['finalWeightKg'] as num?)?.toDouble(),
        finalSaleValue: (json['finalSaleValue'] as num?)?.toDouble(),
        recyclerConfirmed: json['recyclerConfirmed'] == true,
        statusHistory: (json['statusHistory'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(StatusEvent.fromJson)
            .toList(),
        lastSyncError: json['lastSyncError']?.toString() ?? '',
        offers: (json['offers'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(RecyclerOffer.fromJson)
            .toList(),
        agreement: json['agreement'] != null
            ? DigitalAgreement.fromJson(json['agreement'] as Map<String, dynamic>)
            : null,
        agreedPrice: (json['agreedPrice'] as num?)?.toDouble(),
        sourceLotIds: (json['sourceLotIds'] as List?)?.cast<String>(),
      );

  String toQrJson() => jsonEncode({
        'lotId': lotId,
        'handoverReference': handoverReference,
        'collectorId': collectorId,
        'materials': materials
            .map((item) => {
                  'materialId': item.materialId,
                  'quantity': item.quantity,
                  'weightKg': item.weightKg,
                })
            .toList(),
        'totalWeightKg': totalWeightKg,
        'estimatedValue': totalEstimatedValue,
        'recycler': selectedRecyclerName,
        'createdAt': createdAt.toIso8601String(),
        'collectionLocation': collectionLocation.label,
        'status': status.name,
        'paymentStatus': paymentStatus.name,
      });
}

class PricePoint {
  const PricePoint(this.date, this.value);
  final DateTime date;
  final double value;
}

class PriceRecord {
  const PriceRecord({
    required this.priceId,
    required this.materialId,
    required this.location,
    required this.updatedAt,
    required this.buyingPrice,
    required this.quotedPrice,
    required this.marketMin,
    required this.marketMax,
    required this.unit,
    required this.recyclerId,
    required this.history,
  });

  final String priceId;
  final String materialId;
  final String location;
  final DateTime updatedAt;
  final double buyingPrice;
  final double quotedPrice;
  final double marketMin;
  final double marketMax;
  final String unit;
  final String recyclerId;
  final List<PricePoint> history;

  int get trend {
    if (history.length < 2) return 0;
    final difference = history.last.value - history.first.value;
    if (difference.abs() < 1) return 0;
    return difference > 0 ? 1 : -1;
  }
}

class RecyclerRecord {
  const RecyclerRecord({
    required this.recyclerId,
    required this.name,
    required this.facilityLocation,
    required this.latitude,
    required this.longitude,
    required this.materialsAccepted,
    required this.authorizationStatus,
    required this.authorizationDetails,
    required this.contact,
    required this.offeredRates,
    required this.pickupAvailability,
    required this.serviceArea,
    this.completedTransactions = 0,
    this.priceConsistencyScore = 0.0,
    this.paymentCompletionScore = 0.0,
  });

  final String recyclerId;
  final String name;
  final String facilityLocation;
  final double latitude;
  final double longitude;
  final List<String> materialsAccepted;
  final String authorizationStatus;
  final String authorizationDetails;
  final String contact;
  final Map<String, double> offeredRates;
  final bool pickupAvailability;
  final String serviceArea;
  final int completedTransactions;
  final double priceConsistencyScore;
  final double paymentCompletionScore;
}

class SyncSummary {
  const SyncSummary({
    required this.online,
    required this.pending,
    required this.failed,
    required this.lastSynced,
  });

  final bool online;
  final int pending;
  final int failed;
  final DateTime? lastSynced;
}

class RecyclerOffer {
  const RecyclerOffer({
    required this.recyclerId,
    required this.recyclerName,
    required this.offeredRate,
    required this.distanceKm,
    required this.pickupAvailable,
    required this.authorizationStatus,
  });

  final String recyclerId;
  final String recyclerName;
  final double offeredRate;
  final double distanceKm;
  final bool pickupAvailable;
  final String authorizationStatus;

  Map<String, dynamic> toJson() => {
        'recyclerId': recyclerId,
        'recyclerName': recyclerName,
        'offeredRate': offeredRate,
        'distanceKm': distanceKm,
        'pickupAvailable': pickupAvailable,
        'authorizationStatus': authorizationStatus,
      };

  factory RecyclerOffer.fromJson(Map<String, dynamic> json) => RecyclerOffer(
        recyclerId: json['recyclerId']?.toString() ?? '',
        recyclerName: json['recyclerName']?.toString() ?? '',
        offeredRate: (json['offeredRate'] as num?)?.toDouble() ?? 0.0,
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
        pickupAvailable: json['pickupAvailable'] == true,
        authorizationStatus: json['authorizationStatus']?.toString() ?? 'Unverified',
      );
}

class DigitalAgreement {
  const DigitalAgreement({
    required this.lotId,
    required this.recyclerId,
    required this.agreedRate,
    required this.paymentMethod,
    required this.handoverMethod,
    required this.lockedAt,
    this.collectorAccepted = false,
    this.recyclerAccepted = false,
  });

  final String lotId;
  final String recyclerId;
  final double agreedRate;
  final PaymentMethod paymentMethod;
  final String handoverMethod;
  final DateTime lockedAt;
  final bool collectorAccepted;
  final bool recyclerAccepted;

  Map<String, dynamic> toJson() => {
        'lotId': lotId,
        'recyclerId': recyclerId,
        'agreedRate': agreedRate,
        'paymentMethod': paymentMethod.name,
        'handoverMethod': handoverMethod,
        'lockedAt': lockedAt.toIso8601String(),
        'collectorAccepted': collectorAccepted,
        'recyclerAccepted': recyclerAccepted,
      };

  factory DigitalAgreement.fromJson(Map<String, dynamic> json) => DigitalAgreement(
        lotId: json['lotId']?.toString() ?? '',
        recyclerId: json['recyclerId']?.toString() ?? '',
        agreedRate: (json['agreedRate'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: enumByName(PaymentMethod.values, json['paymentMethod'], PaymentMethod.cash),
        handoverMethod: json['handoverMethod']?.toString() ?? 'Drop-off',
        lockedAt: DateTime.tryParse(json['lockedAt']?.toString() ?? '') ?? DateTime.now(),
        collectorAccepted: json['collectorAccepted'] == true,
        recyclerAccepted: json['recyclerAccepted'] == true,
      );
}
