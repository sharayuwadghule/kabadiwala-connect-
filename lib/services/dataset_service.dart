import 'dart:convert';
import '../models/dataset_models.dart';
import '../models/workflow_models.dart';
import '../data/ministry_data.dart';
import 'package:crypto/crypto.dart';

class DatasetService {
  /// Generates the Transaction, Traceability, and Collector datasets from local lots
  static Map<String, dynamic> generateDatasets(List<DigitalLot> lots) {
    final transactions = <TransactionDatasetRecord>[];
    final traceability = <TraceabilityDatasetRecord>[];
    final collectorMap = <String, CollectorDatasetRecord>{};

    for (final lot in lots) {
      // Create Transaction Record
      transactions.add(TransactionDatasetRecord(
        lotId: lot.lotId,
        collectorId: _anonymize(lot.collectorId),
        materialIds: lot.materials.map((m) => m.materialId).toList(),
        totalWeightKg: lot.totalWeightKg,
        quotedPrice: lot.totalEstimatedValue,
        finalPrice: lot.finalSaleValue,
        recyclerId: lot.selectedRecyclerId.isNotEmpty ? lot.selectedRecyclerId : 'unassigned',
        collectionLocation: lot.collectionLocation.label,
        handoverLocation: lot.selectedRecyclerId.isNotEmpty ? 'Recycler Facility' : 'N/A',
        timestamp: lot.createdAt,
        paymentStatus: lot.paymentStatus.name,
        transactionStatus: lot.status.name,
      ));

      // Create Traceability Record
      traceability.add(TraceabilityDatasetRecord(
        lotId: lot.lotId,
        photos: lot.handoverImageBase64 != null ? [lot.handoverImageBase64!] : [],
        weightKg: lot.totalWeightKg,
        timestamp: lot.createdAt,
        gpsCoords: '${lot.collectionLocation.latitude},${lot.collectionLocation.longitude}',
        handoverReference: lot.handoverReference,
        recyclerConfirmed: lot.recyclerConfirmed,
        statusHistory: lot.statusHistory.map((s) => s.status.name).toList(),
      ));

      // Aggregate Collector Data
      final anonId = _anonymize(lot.collectorId);
      final existing = collectorMap[anonId];
      if (existing != null) {
        collectorMap[anonId] = CollectorDatasetRecord(
          collectorId: anonId,
          language: existing.language,
          generalArea: existing.generalArea,
          transactionCount: existing.transactionCount + 1,
          totalEarnings: existing.totalEarnings + (lot.finalSaleValue ?? 0.0),
        );
      } else {
        collectorMap[anonId] = CollectorDatasetRecord(
          collectorId: anonId,
          language: 'en', // default or retrieved from settings
          generalArea: 'Maharashtra', // extrapolated from location data
          transactionCount: 1,
          totalEarnings: lot.finalSaleValue ?? 0.0,
        );
      }
    }

    return {
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'traceability': traceability.map((e) => e.toJson()).toList(),
      'collectors': collectorMap.values.map((e) => e.toJson()).toList(),
    };
  }

  /// Hashes a collector's phone number or ID to remove PII
  static String _anonymize(String identifier) {
    final bytes = utf8.encode(identifier + "SALT_2026");
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 12);
  }
}
