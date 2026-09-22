import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'data/ministry_data.dart';
import 'models/detection_result.dart';
import 'models/workflow_models.dart';
import 'repositories/workflow_repositories.dart';
import 'services/detection_service.dart';
import 'services/workflow_services.dart';

enum WorkflowScreen {
  onboarding,
  home,
  collectionMode,
  capture,
  review,
  priceBoard,
  safety,
  lotDetail,
  recyclerMatch,
  handover,
  payment,
  ledger,
  sync,
  recyclerDashboard,
  makeOffer,
  schemes,
  aggregateLots,
  unitEconomics,
  scanQR,
}

class MinistryController extends ChangeNotifier {
  MinistryController({
    LocalRepository? localRepository,
    RemoteRepository? remoteRepository,
    DetectionService? detectionService,
    ImagePicker? imagePicker,
    bool enableTts = true,
    bool? initialOnline,
    this.monitorConnectivity = true,
  })  : local = localRepository ?? SharedPreferencesLocalRepository(),
        remote = remoteRepository ?? DemoRemoteRepository(),
        detection = detectionService ?? DetectionService(),
        picker = imagePicker ?? ImagePicker(),
        tts = enableTts ? FlutterTts() : null,
        online = initialOnline ?? true {
    syncService = SyncService(local: local, remote: remote);
  }

  final LocalRepository local;
  final RemoteRepository remote;
  final DetectionService detection;
  final ImagePicker picker;
  final FlutterTts? tts;
  final bool monitorConnectivity;
  final valuation = const ValuationService();
  final recommendation = const RecyclerRecommendationService();
  final anomaly = const AnomalyDetectionService();
  late final SyncService syncService;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final List<WorkflowScreen> _history = [];
  int _sequence = 0;
  int _detectionGeneration = 0;

  WorkflowScreen screen = WorkflowScreen.onboarding;
  CollectorProfile? profile;
  RecyclerProfile? recyclerProfile;
  UserRole get userRole => profile?.role ?? UserRole.collector;
  
  String language = 'mr';
  bool loading = true;
  bool online;
  bool syncing = false;
  DateTime? lastSynced;
  CollectionMode collectionMode = CollectionMode.batch;
  final List<DraftImage> draftImages = [];
  final List<LotMaterial> draftMaterials = [];
  final Map<String, DetectionResult> detectionResults = {};
  final Set<String> safetyAcknowledgedMaterialIds = {};
  bool detecting = false;
  String detectionMessage = '';
  LocationRecord collectionLocation =
      const LocationRecord(label: 'Location unavailable');
  bool locating = false;
  final List<DigitalLot> lots = [];
  String selectedLotId = '';
  String selectedRecyclerId = '';
  PaymentMethod paymentMethod = PaymentMethod.cash;
  PaymentStatus paymentStatus = PaymentStatus.pending;
  String priceSearch = '';
  String priceMaterialFilter = 'all';
  String priceLocationFilter = 'Pune, Maharashtra';
  String ledgerFilter = 'all';
  String lastError = '';

  String t(String key) => mt(language, key);
  DigitalLot? get selectedLot =>
      lots.where((lot) => lot.lotId == selectedLotId).firstOrNull;
  RecyclerRecord? get selectedRecycler => demoRecyclers
      .where((item) => item.recyclerId == selectedRecyclerId)
      .firstOrNull;
  double get draftWeight =>
      draftMaterials.fold(0, (sum, item) => sum + item.weightKg);
  double get draftValue =>
      draftMaterials.fold(0, (sum, item) => sum + item.estimatedValue);
  bool get canCreateLot =>
      draftMaterials.isNotEmpty &&
      draftMaterials.every((item) => item.weightKg > 0) &&
      draftMaterials
          .where((item) => materialCatalog[item.materialId]?.hazardous == true)
          .every((item) =>
              safetyAcknowledgedMaterialIds.contains(item.materialId));
  int get pendingSyncCount => lots
      .where((lot) =>
          lot.syncState == SyncState.pending ||
          lot.syncState == SyncState.failed)
      .length;
  int get failedSyncCount =>
      lots.where((lot) => lot.syncState == SyncState.failed).length;
  double get totalEarnings => lots.fold(0, (sum, lot) => sum + lot.paidAmount);
  double get pendingEarnings =>
      lots.fold(0, (sum, lot) => sum + lot.pendingAmount);
  int get completedLots =>
      lots.where((lot) => lot.status == LotStatus.completed).length;

  List<PriceRecord> get filteredPrices => demoPrices.where((price) {
        final material = materialCatalog[price.materialId]!;
        final query = priceSearch.trim().toLowerCase();
        final matchesSearch = query.isEmpty ||
            material.name(language).toLowerCase().contains(query) ||
            material.category.toLowerCase().contains(query);
        final matchesMaterial = priceMaterialFilter == 'all' ||
            price.materialId == priceMaterialFilter;
        return matchesSearch &&
            matchesMaterial &&
            price.location == priceLocationFilter;
      }).toList();

  List<DigitalLot> get filteredLots => lots
      .where((lot) {
        if (ledgerFilter == 'paid') {
          return lot.paymentStatus == PaymentStatus.paid;
        }
        if (ledgerFilter == 'pending') {
          return lot.paymentStatus == PaymentStatus.pending;
        }
        return true;
      })
      .toList()
      .reversed
      .toList();

  Future<void> load() async {
    profile = await local.loadProfile();
    recyclerProfile = await local.loadRecyclerProfile();
    if (profile != null) {
      language = profile!.language;
      if (profile!.role == UserRole.recycler && recyclerProfile == null) {
        screen = WorkflowScreen.onboarding;
      } else if (profile!.role != UserRole.recycler && profile!.collectorName.trim().isEmpty) {
        screen = WorkflowScreen.onboarding;
      } else {
        screen = WorkflowScreen.home;
      }
    }
    lots
      ..clear()
      ..addAll(await local.loadLots());
    lastSynced = await local.loadLastSync();
    await tts?.setSpeechRate(.46);
    loading = false;
    notifyListeners();
    if (monitorConnectivity) {
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (results) => setOnline(
              results.any((result) => result != ConnectivityResult.none)));
      try {
        final results = await Connectivity().checkConnectivity();
        setOnline(results.any((result) => result != ConnectivityResult.none));
      } catch (_) {
        // Connectivity is advisory; core local workflows remain available.
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    tts?.stop();
    super.dispose();
  }

  void go(WorkflowScreen next, {bool remember = true}) {
    if (screen == next) return;
    if (remember) _history.add(screen);
    screen = next;
    notifyListeners();
  }

  void back() {
    if (_history.isEmpty) {
      screen =
          profile == null ? WorkflowScreen.onboarding : WorkflowScreen.home;
    } else {
      screen = _history.removeLast();
    }
    notifyListeners();
  }

  void goHome() {
    if (profile == null) return;
    _history.clear();
    screen = WorkflowScreen.home;
    notifyListeners();
  }

  Future<void> logout() async {
    await local.clearProfile();
    profile = null;
    recyclerProfile = null;
    _history.clear();
    screen = WorkflowScreen.onboarding;
    lastError = '';
    notifyListeners();
  }

  void setLanguage(String value) {
    language = value;
    if (profile != null) {
      profile = CollectorProfile(
        collectorId: profile!.collectorId,
        collectorName: profile!.collectorName,
        language: value,
        operatingLocation: profile!.operatingLocation,
        role: profile!.role,
      );
      local.saveProfile(profile!);
    }
    notifyListeners();
  }

  void setPriceSearch(String value) {
    priceSearch = value;
    notifyListeners();
  }

  void setPriceMaterialFilter(String value) {
    priceMaterialFilter = value;
    notifyListeners();
  }

  void setLedgerFilter(String value) {
    ledgerFilter = value;
    notifyListeners();
  }

  Future<void> saveProfile(
    String collectorId,
    String operatingLocation,
    UserRole role, [
    String collectorName = '',
  ]) async {
    final mobile = collectorId.trim();
    if (!RegExp(r'^\d{5,10}$').hasMatch(mobile)) {
      lastError = t('phoneError');
      notifyListeners();
      return;
    }
    profile = CollectorProfile(
      collectorId: mobile,
      collectorName: collectorName.trim(),
      language: language,
      operatingLocation: operatingLocation.trim().isEmpty
          ? 'Location not provided'
          : operatingLocation.trim(),
      role: role,
    );
    await local.saveProfile(profile!);
    lastError = '';
    screen = WorkflowScreen.home;
    _history.clear();
    notifyListeners();
  }

  Future<void> saveRecyclerProfile(
    String facilityName,
    String facilityLocation,
    String authorizationNumber,
    List<String> materialsAccepted,
  ) async {
    if (facilityName.trim().isEmpty || authorizationNumber.trim().isEmpty) {
      lastError = 'Facility Name and Authorization Number are required.';
      notifyListeners();
      return;
    }
    recyclerProfile = RecyclerProfile(
      recyclerId: 'REC-${DateTime.now().millisecondsSinceEpoch}',
      facilityName: facilityName.trim(),
      facilityLocation: facilityLocation.trim(),
      authorizationNumber: authorizationNumber.trim(),
      materialsAccepted: materialsAccepted,
    );
    profile = CollectorProfile(
      collectorId: recyclerProfile!.recyclerId,
      collectorName: recyclerProfile!.facilityName,
      language: language,
      operatingLocation: recyclerProfile!.facilityLocation,
      role: UserRole.recycler,
    );
    await local.saveRecyclerProfile(recyclerProfile!);
    await local.saveProfile(profile!);
    lastError = '';
    screen = WorkflowScreen.recyclerDashboard;
    _history.clear();
    notifyListeners();
  }

  void startCollection(CollectionMode mode) {
    collectionMode = mode;
    draftImages.clear();
    draftMaterials.clear();
    detectionResults.clear();
    safetyAcknowledgedMaterialIds.clear();
    _detectionGeneration++;
    detectionMessage = '';
    collectionLocation = const LocationRecord(label: 'Location unavailable');
    selectedRecyclerId = '';
    paymentMethod = PaymentMethod.cash;
    paymentStatus = PaymentStatus.pending;
    go(WorkflowScreen.capture);
  }

  Future<bool> addCameraPhoto() async {
    try {
      final image = await picker.pickImage(
          source: ImageSource.camera, imageQuality: 72, maxWidth: 1280);
      if (image == null) return false;
      await _addFiles([image]);
      return true;
    } catch (_) {
      lastError = 'Camera unavailable. Use gallery or manual material entry.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addGalleryPhotos() async {
    try {
      final files = collectionMode == CollectionMode.batch
          ? await picker.pickMultiImage(imageQuality: 72, maxWidth: 1280)
          : <XFile>[
              if (await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 72,
                      maxWidth: 1280)
                  case final image?)
                image
            ];
      if (files.isEmpty) return false;
      await _addFiles(files);
      return true;
    } catch (_) {
      lastError = 'Gallery unavailable. You can add materials manually.';
      notifyListeners();
      return false;
    }
  }

  Future<void> _addFiles(List<XFile> files) async {
    if (detecting && collectionMode == CollectionMode.batch) return;
    final generation = ++_detectionGeneration;
    if (collectionMode == CollectionMode.single) {
      draftImages.clear();
      draftMaterials.clear();
      detectionResults.clear();
      safetyAcknowledgedMaterialIds.clear();
    }
    final added = <DraftImage>[];
    for (final file
        in files.take(collectionMode == CollectionMode.batch ? 8 : 1)) {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty ||
          bytes.length > 8 * 1024 * 1024 ||
          !_isSupportedImage(bytes)) {
        lastError = t('detectionUnavailable');
        continue;
      }
      final image = DraftImage(
        id: 'IMG-${DateTime.now().microsecondsSinceEpoch}-${added.length}',
        bytes: bytes,
        source: 'device',
      );
      draftImages.add(image);
      added.add(image);
    }
    notifyListeners();
    if (added.isEmpty) return;
    if (online) {
      await detectImages(added, generation: generation);
      if (collectionMode == CollectionMode.single &&
          generation == _detectionGeneration) {
        go(WorkflowScreen.review);
      }
    } else {
      detectionMessage = t('detectionUnavailable');
      notifyListeners();
    }
  }

  Future<void> detectImages(List<DraftImage> images, {int? generation}) async {
    if (images.isEmpty) return;
    final requestGeneration = generation ?? ++_detectionGeneration;
    detecting = true;
    detectionMessage = t('identifying');
    notifyListeners();
    var suggestions = 0;
    for (final image in images) {
      final result = await detection.detect(image.bytes);
      if (requestGeneration != _detectionGeneration) return;
      detectionResults[image.id] = result;
      final grouped = _groupDetection(result, image.id);
      if (grouped) suggestions++;
    }
    if (requestGeneration != _detectionGeneration) return;
    detecting = false;
    detectionMessage = suggestions == 0
        ? t('uncertainDetection')
        : '${t('aiSuggestion')}: $suggestions. ${t('verifyAi')}';
    notifyListeners();
  }

  Future<void> retryDetection(String imageId) async {
    if (detecting || !online) return;
    final image = draftImages.where((item) => item.id == imageId).firstOrNull;
    if (image == null) return;
    draftMaterials.removeWhere((item) => item.imageIds.contains(imageId));
    detectionResults.remove(imageId);
    safetyAcknowledgedMaterialIds.clear();
    await detectImages([image]);
  }

  bool _groupDetection(DetectionResult result, String imageId) {
    final candidates = <DetectionBox>[
      ...result.predictions.where((item) =>
          item.confidence >= .45 &&
          materialCatalog.containsKey(_normalizeMaterialId(item.categoryId))),
    ];
    if (candidates.isEmpty && result.categoryId != null) {
      candidates.add(DetectionBox(
        categoryId: _normalizeMaterialId(result.categoryId!),
        className: result.className ?? result.categoryId!,
        confidence: result.confidence,
        x: 0,
        y: 0,
        width: 0,
        height: 0,
      ));
    }
    var added = false;
    for (final candidate in candidates) {
      final id = _normalizeMaterialId(candidate.categoryId);
      if (!materialCatalog.containsKey(id)) continue;
      final index = draftMaterials.indexWhere((item) => item.materialId == id);
      if (index >= 0) {
        final current = draftMaterials[index];
        draftMaterials[index] = current.copyWith(
          quantity: current.quantity + 1,
          confidence: max(current.confidence, candidate.confidence),
          imageIds: {...current.imageIds, imageId}.toList(),
          detectedMaterialId: current.detectedMaterialId ?? id,
        );
      } else {
        draftMaterials.add(LotMaterial(
          materialId: id,
          quantity: 1,
          weightKg: 0,
          condition: 'mixed',
          sourceType: 'ai_suggestion_unverified',
          confidence: candidate.confidence,
          imageIds: [imageId],
          estimatedValue: 0,
          quotedRate: valuation.priceFor(id).buyingPrice,
          detectedMaterialId: id,
        ));
      }
      added = true;
    }
    return added;
  }

  String _normalizeMaterialId(String id) => switch (id) {
        'cable' => 'cables',
        'batteries' => 'battery',
        'display' || 'screen' => 'lcd',
        'mixed' || 'plastic' => 'mixed_plastics',
        _ => id,
      };

  void addManualMaterial(String materialId) {
    safetyAcknowledgedMaterialIds.remove(materialId);
    final index =
        draftMaterials.indexWhere((item) => item.materialId == materialId);
    if (index >= 0) {
      final current = draftMaterials[index];
      draftMaterials[index] = current.copyWith(quantity: current.quantity + 1);
    } else {
      draftMaterials.add(LotMaterial(
        materialId: materialId,
        quantity: 1,
        weightKg: 0,
        condition: 'mixed',
        sourceType: 'manual',
        confidence: 1,
        imageIds: const [],
        estimatedValue: 0,
        quotedRate: valuation.priceFor(materialId).buyingPrice,
        detectedMaterialId: null,
      ));
    }
    notifyListeners();
  }

  void updateMaterial(int index,
      {int? quantity, double? weightKg, String? condition}) {
    if (index < 0 || index >= draftMaterials.length) return;
    final item = draftMaterials[index];
    final weight = max(0.0, weightKg ?? item.weightKg);
    draftMaterials[index] = item.copyWith(
      quantity: max(1, quantity ?? item.quantity).toInt(),
      weightKg: weight,
      condition: condition,
      estimatedValue: valuation.estimate(item.materialId, weight),
    );
    notifyListeners();
  }

  void replaceMaterial(int index, String materialId) {
    if (index < 0 || index >= draftMaterials.length) return;
    final old = draftMaterials[index];
    safetyAcknowledgedMaterialIds
      ..remove(old.materialId)
      ..remove(materialId);
    final rate = valuation.priceFor(materialId).buyingPrice;
    draftMaterials[index] = LotMaterial(
      materialId: materialId,
      quantity: old.quantity,
      weightKg: old.weightKg,
      condition: old.condition,
      sourceType: 'manual_correction',
      confidence: 1,
      imageIds: old.imageIds,
      estimatedValue: old.weightKg * rate,
      quotedRate: rate,
      detectedMaterialId: old.detectedMaterialId,
    );
    _mergeDuplicateMaterials();
    notifyListeners();
  }

  void _mergeDuplicateMaterials() {
    final grouped = <String, LotMaterial>{};
    for (final item in draftMaterials) {
      final current = grouped[item.materialId];
      grouped[item.materialId] = current == null
          ? item
          : current.copyWith(
              quantity: current.quantity + item.quantity,
              weightKg: current.weightKg + item.weightKg,
              imageIds: {...current.imageIds, ...item.imageIds}.toList(),
              estimatedValue: current.estimatedValue + item.estimatedValue,
            );
    }
    draftMaterials
      ..clear()
      ..addAll(grouped.values);
  }

  void removeMaterial(int index) {
    if (index < 0 || index >= draftMaterials.length) return;
    final removed = draftMaterials.removeAt(index);
    if (!draftMaterials.any((item) => item.materialId == removed.materialId)) {
      safetyAcknowledgedMaterialIds.remove(removed.materialId);
    }
    notifyListeners();
  }

  void acknowledgeSafety(String materialId) {
    if (materialCatalog[materialId]?.hazardous != true) return;
    safetyAcknowledgedMaterialIds.add(materialId);
    notifyListeners();
  }

  bool safetyAcknowledged(String materialId) =>
      safetyAcknowledgedMaterialIds.contains(materialId);

  Future<void> requestLocation() async {
    locating = true;
    notifyListeners();
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        collectionLocation =
            const LocationRecord(label: 'Location unavailable');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      collectionLocation = LocationRecord(
        latitude: position.latitude,
        longitude: position.longitude,
        label:
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
      );
    } catch (_) {
      collectionLocation = const LocationRecord(label: 'Location unavailable');
    } finally {
      locating = false;
      notifyListeners();
    }
  }

  void useDemoLocation() {
    collectionLocation = const LocationRecord(
      latitude: 18.5204,
      longitude: 73.8567,
      label: 'Demo location: Pune, Maharashtra',
    );
    notifyListeners();
  }

  Future<DigitalLot?> createLot() async {
    if (!canCreateLot || profile == null) {
      final hasUnacknowledgedHazard = draftMaterials.any((item) =>
          materialCatalog[item.materialId]?.hazardous == true &&
          !safetyAcknowledgedMaterialIds.contains(item.materialId));
      final hasInvalidWeight = draftMaterials.any((item) => item.weightKg <= 0);
      lastError = draftMaterials.isEmpty
          ? 'Add at least one material.'
          : hasInvalidWeight
              ? 'Enter a weight greater than zero for every material.'
              : hasUnacknowledgedHazard
                  ? t('safetyRequired')
                  : t('phoneError');
      notifyListeners();
      return null;
    }
    if (!collectionLocation.available &&
        collectionLocation.label == 'Location unavailable') {
      await requestLocation();
    }
    final now = DateTime.now();
    final suffix = ((now.millisecondsSinceEpoch + _sequence++) % 1000000)
        .toString()
        .padLeft(6, '0');
    final lotId = 'KBC-${now.year}-$suffix';
    final status = online ? LotStatus.lotCreated : LotStatus.pendingSync;
    final lot = DigitalLot(
      lotId: lotId,
      handoverReference: 'HO-$suffix',
      collectorId: profile!.collectorId,
      createdAt: now,
      materials: List.unmodifiable(draftMaterials),
      imageBase64: draftImages
          .take(4)
          .map((image) => base64Encode(image.bytes))
          .toList(),
      handoverImageBase64: null,
      collectionLocation: collectionLocation,
      handoverLocation:
          const LocationRecord(label: 'Handover location pending'),
      status: status,
      paymentMethod: paymentMethod,
      paymentStatus: PaymentStatus.pending,
      syncState: SyncState.pending,
      selectedRecyclerId: '',
      selectedRecyclerName: '',
      totalEstimatedValue: draftValue,
      finalWeightKg: null,
      finalSaleValue: null,
      recyclerConfirmed: false,
      statusHistory: [StatusEvent(status: status, at: now)],
    );
    lots.add(lot);
    selectedLotId = lotId;
    await _persistLots();
    go(WorkflowScreen.lotDetail);
    if (online) unawaited(syncNow());
    return lot;
  }

  List<RecyclerMatch> recyclerMatches([DigitalLot? lot]) {
    final target = lot ?? selectedLot;
    if (target == null) return [];
    return recommendation.recommend(
        materials: target.materials, location: target.collectionLocation);
  }

  void handleScannedLotId(String scannedId) {
    // Attempt to find the lot locally
    try {
      final lot = lots.firstWhere((l) => l.lotId == scannedId);
      selectedLotId = lot.lotId;
      notifyListeners();
      go(WorkflowScreen.lotDetail); // Go to verification screen
    } catch (_) {
      // Not found locally. If online, we would fetch from backend here.
      lastError = 'Lot $scannedId not found locally. Ensure it is synced.';
      notifyListeners();
    }
  }

  Future<void> chooseRecycler(RecyclerRecord recycler,
      {bool pickupRequested = false}) async {
    final lot = selectedLot;
    if (lot == null) return;
    selectedRecyclerId = recycler.recyclerId;
    final updated = lot.copyWith(
      selectedRecyclerId: recycler.recyclerId,
      selectedRecyclerName: recycler.name,
      status: pickupRequested
          ? LotStatus.pickupRequested
          : LotStatus.recyclerSelected,
      syncState: SyncState.pending,
      statusHistory: [
        ...lot.statusHistory,
        StatusEvent(
            status: pickupRequested
                ? LotStatus.pickupRequested
                : LotStatus.recyclerSelected,
            at: DateTime.now()),
      ],
    );
    await _replaceLot(updated);
    go(WorkflowScreen.handover);
  }

  Future<bool> addHandoverPhoto(ImageSource source) async {
    final lot = selectedLot;
    if (lot == null) return false;
    try {
      final image = await picker.pickImage(
          source: source, imageQuality: 65, maxWidth: 960);
      if (image == null) return false;
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) return false;
      await _replaceLot(lot.copyWith(
          handoverImageBase64: base64Encode(bytes),
          syncState: SyncState.pending));
      return true;
    } catch (_) {
      lastError = 'Handover photo unavailable. You can continue without it.';
      notifyListeners();
      return false;
    }
  }

  AnomalyResult checkFinalValue(double weight, double value) {
    final lot = selectedLot;
    if (lot == null) {
      return const AnomalyResult(unusual: true, message: 'Lot unavailable.');
    }
    return anomaly.check(
        finalValue: value, finalWeightKg: weight, materials: lot.materials);
  }

  Future<bool> confirmReceipt(double finalWeight, double finalValue) async {
    final lot = selectedLot;
    if (lot == null || lot.recyclerConfirmed) return false;
    if (finalWeight <= 0 || finalValue < 0 || lot.selectedRecyclerId.isEmpty) {
      lastError =
          'Recycler, final weight and a valid final value are required.';
      notifyListeners();
      return false;
    }
    final recycler = selectedRecycler ??
        demoRecyclers
            .firstWhere((item) => item.recyclerId == lot.selectedRecyclerId);
    final updated = lot.copyWith(
      status: LotStatus.received,
      finalWeightKg: finalWeight,
      finalSaleValue: finalValue,
      recyclerConfirmed: true,
      handoverLocation: LocationRecord(
        latitude: recycler.latitude,
        longitude: recycler.longitude,
        label: recycler.facilityLocation,
      ),
      syncState: SyncState.pending,
      statusHistory: [
        ...lot.statusHistory,
        StatusEvent(status: LotStatus.received, at: DateTime.now()),
      ],
    );
    await _replaceLot(updated);
    go(WorkflowScreen.payment);
    return true;
  }

  Future<void> finishPayment(PaymentMethod method, PaymentStatus status) async {
    final lot = selectedLot;
    if (lot == null || !lot.recyclerConfirmed) return;
    final finalStatus = status == PaymentStatus.paid
        ? LotStatus.completed
        : LotStatus.paymentPending;
    final updated = lot.copyWith(
      paymentMethod: method,
      paymentStatus: status,
      status: finalStatus,
      syncState: SyncState.pending,
      statusHistory: [
        ...lot.statusHistory,
        StatusEvent(status: finalStatus, at: DateTime.now()),
      ],
    );
    await _replaceLot(updated);
    go(WorkflowScreen.ledger);
    if (online) unawaited(syncNow());
  }

  Future<void> markPaymentPaid(String lotId) async {
    final lot = lots.where((item) => item.lotId == lotId).firstOrNull;
    if (lot == null || lot.paymentStatus == PaymentStatus.paid) return;
    final updated = lot.copyWith(
      paymentStatus: PaymentStatus.paid,
      status: LotStatus.completed,
      syncState: SyncState.pending,
      statusHistory: [
        ...lot.statusHistory,
        StatusEvent(status: LotStatus.completed, at: DateTime.now()),
      ],
    );
    await _replaceLot(updated);
  }

  void selectLot(String lotId,
      {WorkflowScreen target = WorkflowScreen.lotDetail}) {
    selectedLotId = lotId;
    final lot = selectedLot;
    selectedRecyclerId = lot?.selectedRecyclerId ?? '';
    go(target);
  }

  Future<void> submitOffer(double offeredRate, double distanceKm, bool pickupAvailable) async {
    final lot = selectedLot;
    if (lot == null) return;
    
    final recycler = demoRecyclers.first; // Mocking current recycler
    final offer = RecyclerOffer(
      recyclerId: recycler.recyclerId,
      recyclerName: recycler.name,
      offeredRate: offeredRate,
      distanceKm: distanceKm,
      pickupAvailable: pickupAvailable,
      authorizationStatus: recycler.authorizationStatus,
    );

    final updated = lot.copyWith(
      offers: [...lot.offers, offer],
      syncState: SyncState.pending,
    );
    await _replaceLot(updated);
    go(WorkflowScreen.recyclerDashboard);
  }

  Future<void> acceptOffer(RecyclerOffer offer, bool pickupRequested) async {
    final lot = selectedLot;
    if (lot == null) return;

    final agreement = DigitalAgreement(
      lotId: lot.lotId,
      recyclerId: offer.recyclerId,
      agreedRate: offer.offeredRate,
      paymentMethod: PaymentMethod.cash,
      handoverMethod: pickupRequested ? 'Pickup' : 'Drop-off',
      lockedAt: DateTime.now(),
      recyclerAccepted: true,
      collectorAccepted: true,
    );

    final updated = lot.copyWith(
      selectedRecyclerId: offer.recyclerId,
      selectedRecyclerName: offer.recyclerName,
      agreement: agreement,
      agreedPrice: offer.offeredRate,
      status: pickupRequested ? LotStatus.pickupRequested : LotStatus.recyclerSelected,
      syncState: SyncState.pending,
      statusHistory: [
        ...lot.statusHistory,
        StatusEvent(
          status: pickupRequested ? LotStatus.pickupRequested : LotStatus.recyclerSelected,
          at: DateTime.now(),
        ),
      ],
    );
    await _replaceLot(updated);
    go(WorkflowScreen.handover);
  }

  Future<void> aggregateLots(List<String> sourceLotIds) async {
    final sourceLots = lots.where((l) => sourceLotIds.contains(l.lotId)).toList();
    if (sourceLots.isEmpty) return;
    
    // Combine materials
    final materialMap = <String, double>{};
    final materialQuantities = <String, int>{};
    for (final lot in sourceLots) {
      for (final item in lot.materials) {
        materialMap[item.materialId] = (materialMap[item.materialId] ?? 0) + item.weightKg;
        materialQuantities[item.materialId] = (materialQuantities[item.materialId] ?? 0) + item.quantity;
      }
    }
    
    final combinedMaterials = materialMap.entries.map((e) => LotMaterial(
      materialId: e.key,
      quantity: materialQuantities[e.key] ?? 1,
      weightKg: e.value,
      condition: 'mixed',
      sourceType: 'aggregated',
      confidence: 1.0,
      imageIds: const [],
      estimatedValue: 0.0,
      quotedRate: 0.0,
    )).toList();
    
    final newLot = DigitalLot(
      lotId: 'LOT-${DateTime.now().millisecondsSinceEpoch}',
      collectorId: sourceLots.first.collectorId,
      collectionLocation: sourceLots.first.collectionLocation,
      materials: combinedMaterials,
      status: LotStatus.sorted, // Status for aggregated lots
      sourceLotIds: sourceLotIds,
      handoverReference: 'CONSOLIDATED',
      createdAt: DateTime.now(),
      imageBase64: const [],
      handoverImageBase64: null,
      handoverLocation: const LocationRecord(latitude: 0, longitude: 0, label: 'Pending'),
      paymentMethod: PaymentMethod.cash,
      paymentStatus: PaymentStatus.pending,
      syncState: SyncState.pending,
      selectedRecyclerId: '',
      selectedRecyclerName: '',
      totalEstimatedValue: 0.0,
      finalWeightKg: 0.0,
      finalSaleValue: null,
      recyclerConfirmed: false,
      statusHistory: [StatusEvent(status: LotStatus.sorted, at: DateTime.now())],
    );
    
    lots.add(newLot);
    
    // Mark source lots as completed or processed
    for (var lot in sourceLots) {
      final updated = lot.copyWith(
        statusHistory: [...lot.statusHistory, StatusEvent(status: LotStatus.processed, at: DateTime.now())],
      );
      final index = lots.indexWhere((l) => l.lotId == lot.lotId);
      if (index >= 0) lots[index] = updated;
    }
    
    await _persistLots();
    selectedLotId = newLot.lotId;
    go(WorkflowScreen.recyclerMatch);
  }

  Future<void> processLot(String lotId) async {
    final lot = lots.firstWhere((l) => l.lotId == lotId);
    if (lot.status == LotStatus.processed) return;
    
    final updated = lot.copyWith(
      statusHistory: [...lot.statusHistory, StatusEvent(status: LotStatus.processed, at: DateTime.now())],
    );
    await _replaceLot(updated);
    go(WorkflowScreen.recyclerDashboard);
  }

  void setOnline(bool value) {
    if (online == value) return;
    online = value;
    notifyListeners();
    if (online && pendingSyncCount > 0) unawaited(syncNow());
  }

  Future<void> resetDemo() async {
    lots.clear();
    await _persistLots();
    selectedLotId = '';
    online = false;
    notifyListeners();
    go(WorkflowScreen.home);
  }

  Future<void> syncNow() async {
    if (!online || syncing) return;
    syncing = true;
    notifyListeners();
    final synced = await syncService.sync(lots);
    lots
      ..clear()
      ..addAll(synced);
    lastSynced = await local.loadLastSync();
    syncing = false;
    notifyListeners();
  }

  Future<void> _replaceLot(DigitalLot value) async {
    final index = lots.indexWhere((lot) => lot.lotId == value.lotId);
    if (index < 0) return;
    lots[index] = value;
    await _persistLots();
    notifyListeners();
  }

  Future<void> _persistLots() => local.saveLots(lots);

  Future<void> speak(String message) async {
    final service = tts;
    if (service == null) return;
    await service.stop();
    await service.setLanguage(
        language == 'mr' ? 'mr-IN' : (language == 'hi' ? 'hi-IN' : 'en-IN'));
    await service.speak(message);
  }

  String money(num value) => '₹${value.round()}';

  bool _isSupportedImage(Uint8List bytes) {
    final jpeg = bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff;
    final png = bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47;
    final webp = bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
    return jpeg || png || webp;
  }
}
