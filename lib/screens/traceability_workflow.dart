import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/ministry_data.dart';
import '../ministry_controller.dart';
import '../models/workflow_models.dart';
import '../services/workflow_services.dart';
import '../widgets/common.dart' hide LabelValue;
import '../widgets/ministry_components.dart';

class LotDetailScreenV2 extends StatelessWidget {
  const LotDetailScreenV2({required this.controller, super.key});
  final MinistryController controller;

  @override
  Widget build(BuildContext context) {
    final lot = controller.selectedLot;
    if (lot == null) {
      return const EmptyState(
          icon: Icons.inventory_2_outlined, text: 'Lot unavailable.');
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      PageHeading(
          lot.lotId, 'Unique handover reference: ${lot.handoverReference}'),
      const SizedBox(height: 12),
      Center(
        child: QrImageView(
          data: lot.toQrJson(),
          size: 190,
          backgroundColor: Colors.white,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
        ),
      ),
      const SizedBox(height: 8),
      const Center(child: DemoLabel(text: 'QR contains this local lot record')),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            for (final item in lot.materials)
              LabelValue(
                  materialCatalog[item.materialId]!.name(controller.language),
                  '${item.quantity} item(s) • ${item.weightKg.toStringAsFixed(2)} kg'),
            const Divider(),
            LabelValue(controller.t('totalWeight'),
                '${lot.totalWeightKg.toStringAsFixed(2)} kg',
                strong: true),
            LabelValue(controller.t('estimatedValue'),
                controller.money(lot.totalEstimatedValue),
                strong: true),
            LabelValue('Collection location', lot.collectionLocation.label),
            LabelValue('Status', statusLabel(lot.status)),
            LabelValue('Payment', lot.paymentStatus.name),
            LabelValue('Sync', lot.syncState.name),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      if (lot.selectedRecyclerId.isEmpty)
        PrimaryButton(
            label: controller.t('findRecycler'),
            icon: Icons.factory_rounded,
            onPressed: () => controller.go(WorkflowScreen.recyclerMatch))
      else if (!lot.recyclerConfirmed)
        PrimaryButton(
            label: controller.t('handover'),
            icon: Icons.handshake_rounded,
            onPressed: () => controller.go(WorkflowScreen.handover))
      else
        InfoBand(
          icon: Icons.verified_rounded,
          title: 'Handover receipt',
          body:
              '${lot.selectedRecyclerName}\nFinal weight: ${lot.finalWeightKg?.toStringAsFixed(2)} kg\nFinal value: ${controller.money(lot.finalSaleValue ?? 0)}\nPayment: ${lot.paymentStatus.name}',
        ),
    ]);
  }
}

class RecyclerMatchScreenV2 extends StatelessWidget {
  const RecyclerMatchScreenV2({required this.controller, super.key});
  final MinistryController controller;

  @override
  Widget build(BuildContext context) {
    final matches = controller.recyclerMatches();
    return ListView(padding: const EdgeInsets.all(16), children: [
      PageHeading(controller.t('findRecycler'),
          'Rule-based ranking by compatibility, distance, rate and pickup.'),
      const SizedBox(height: 6),
      const DemoLabel(
          text: 'Demo recyclers - authorization verification required'),
      const SizedBox(height: 12),
      if (matches.isEmpty)
        const EmptyState(
            icon: Icons.factory_outlined,
            text: 'No compatible demo recycler found.'),
      ...matches.map((match) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.factory_rounded, color: primary),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(match.recycler.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17))),
                        Text('${match.score}%',
                            style: const TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 18)),
                      ]),
                      Text(match.recycler.authorizationStatus,
                          style: const TextStyle(
                              color: danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      Text(match.recycler.authorizationDetails,
                          style:
                              const TextStyle(color: textMuted, fontSize: 12)),
                      const SizedBox(height: 8),
                      ...match.reasons.map((reason) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(children: [
                              const Icon(Icons.check_rounded,
                                  size: 17, color: primary),
                              const SizedBox(width: 5),
                              Expanded(child: Text(reason)),
                            ]),
                          )),
                      Text(
                          'Offered estimate: ${controller.money(match.offeredValue)}',
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(
                          '${match.recycler.facilityLocation} • ${match.recycler.serviceArea}',
                          style: const TextStyle(color: textMuted)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MetricChip(icon: Icons.verified_rounded, label: '${match.recycler.completedTransactions} lots'),
                          _MetricChip(icon: Icons.price_check_rounded, label: '${match.recycler.priceConsistencyScore}% price'),
                          _MetricChip(icon: Icons.payments_rounded, label: '${match.recycler.paymentCompletionScore}% paid'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: OutlinedButton.icon(
                                onPressed: () => unsupported(context,
                                    'Calling is not connected in this prototype.'),
                                icon: const Icon(Icons.call_rounded),
                                label: const Text('Call'))),
                        const SizedBox(width: 6),
                        Expanded(
                            child: OutlinedButton.icon(
                                onPressed: () => unsupported(context,
                                    'Directions require a maps integration.'),
                                icon: const Icon(Icons.directions_rounded),
                                label: const Text('Directions'))),
                      ]),
                      const SizedBox(height: 6),
                      PrimaryButton(
                          label: 'Select recycler',
                          icon: Icons.check_circle_rounded,
                          onPressed: () =>
                              controller.chooseRecycler(match.recycler)),
                      if (match.recycler.pickupAvailability) ...[
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: () => controller.chooseRecycler(
                              match.recycler,
                              pickupRequested: true),
                          icon: const Icon(Icons.local_shipping_rounded),
                          label: const Text('Request pickup'),
                        ),
                      ],
                    ]),
              ),
            ),
          )),
    ]);
  }
}

void unsupported(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

class HandoverScreenV2 extends StatefulWidget {
  const HandoverScreenV2({required this.controller, super.key});
  final MinistryController controller;

  @override
  State<HandoverScreenV2> createState() => _HandoverScreenV2State();
}

class _HandoverScreenV2State extends State<HandoverScreenV2> {
  late final TextEditingController weight;
  late final TextEditingController value;
  AnomalyResult? anomalyResult;

  @override
  void initState() {
    super.initState();
    final lot = widget.controller.selectedLot;
    weight = TextEditingController(
        text: lot?.totalWeightKg.toStringAsFixed(2) ?? '');
    value = TextEditingController(
        text: lot?.totalEstimatedValue.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    weight.dispose();
    value.dispose();
    super.dispose();
  }

  void _check() =>
      setState(() => anomalyResult = widget.controller.checkFinalValue(
          double.tryParse(weight.text) ?? 0,
          double.tryParse(value.text) ?? -1));

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final lot = c.selectedLot;
    if (lot == null) {
      return const EmptyState(
          icon: Icons.error_outline_rounded, text: 'Lot unavailable.');
    }
    if (lot.recyclerConfirmed) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        const InfoBand(
            icon: Icons.verified_rounded,
            title: 'Receipt already confirmed',
            body: 'Duplicate handover confirmation is blocked.'),
        const SizedBox(height: 12),
        PrimaryButton(
            label: c.t('payment'),
            onPressed: () => c.go(WorkflowScreen.payment)),
      ]);
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      PageHeading(
          c.t('handover'), '${lot.lotId} • ${lot.selectedRecyclerName}'),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            LabelValue('Expected weight',
                '${lot.totalWeightKg.toStringAsFixed(2)} kg'),
            LabelValue('Quoted value', c.money(lot.totalEstimatedValue)),
            LabelValue('Collection GPS', lot.collectionLocation.label),
            LabelValue('Handover reference', lot.handoverReference),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Handover photograph',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                lot.handoverImageBase64 == null
                    ? 'Optional evidence photo not added.'
                    : 'Evidence photo saved locally.',
                style: const TextStyle(color: textMuted),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => c.addHandoverPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => c.addHandoverPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Gallery'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
          controller: weight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'Final verified weight (kg)',
              prefixIcon: Icon(Icons.scale_rounded)),
          onChanged: (_) => _check()),
      const SizedBox(height: 10),
      TextField(
          controller: value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'Final sale value (₹)',
              prefixIcon: Icon(Icons.currency_rupee_rounded)),
          onChanged: (_) => _check()),
      if (anomalyResult case final result?)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: InfoBand(
              icon: result.unusual
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_rounded,
              title: result.unusual ? 'Rule-based warning' : 'Reference check',
              body: result.message,
              dangerStyle: result.unusual),
        ),
      const SizedBox(height: 12),
      PrimaryButton(
          label: 'Confirm receipt',
          icon: Icons.verified_rounded,
          onPressed: () async {
            _check();
            await c.confirmReceipt(double.tryParse(weight.text) ?? 0,
                double.tryParse(value.text) ?? -1);
          }),
      if (c.lastError.isNotEmpty)
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(c.lastError,
                style: const TextStyle(
                    color: danger, fontWeight: FontWeight.w700))),
    ]);
  }
}

class PaymentScreenV2 extends StatefulWidget {
  const PaymentScreenV2({required this.controller, super.key});
  final MinistryController controller;

  @override
  State<PaymentScreenV2> createState() => _PaymentScreenV2State();
}

class _PaymentScreenV2State extends State<PaymentScreenV2> {
  PaymentMethod method = PaymentMethod.cash;
  PaymentStatus status = PaymentStatus.pending;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final lot = c.selectedLot;
    return ListView(padding: const EdgeInsets.all(16), children: [
      PageHeading(c.t('payment'),
          '${lot?.lotId ?? ''} • ${c.money(lot?.ledgerValue ?? 0)}'),
      const SizedBox(height: 12),
      _PaymentMethodOption(
        selected: method == PaymentMethod.cash,
        icon: Icons.payments_rounded,
        label: c.t('cash'),
        onTap: () => setState(() => method = PaymentMethod.cash),
      ),
      const SizedBox(height: 8),
      _PaymentMethodOption(
        selected: method == PaymentMethod.upi,
        icon: Icons.phone_android_rounded,
        label: c.t('upi'),
        onTap: () => setState(() => method = PaymentMethod.upi),
      ),
      const SizedBox(height: 12),
      if (method == PaymentMethod.upi)
        const InfoBand(
            icon: Icons.info_outline_rounded,
            title: 'Digital payment is simulated',
            body: 'No gateway transaction occurs in this prototype.'),
      const SizedBox(height: 12),
      SegmentedButton<PaymentStatus>(
        segments: [
          ButtonSegment(value: PaymentStatus.paid, label: Text(c.t('paid'))),
          ButtonSegment(
              value: PaymentStatus.pending, label: Text(c.t('pending'))),
        ],
        selected: {status},
        onSelectionChanged: (selected) =>
            setState(() => status = selected.first),
      ),
      const SizedBox(height: 16),
      PrimaryButton(
          label: 'Save payment status',
          icon: Icons.receipt_long_rounded,
          onPressed: () => c.finishPayment(method, status)),
    ]);
  }
}

class _PaymentMethodOption extends StatelessWidget {
  const _PaymentMethodOption({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? primaryLight : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: selected ? primary : border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(icon, color: primary),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w800))),
              Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? primary : textMuted),
            ]),
          ),
        ),
      );
}

class LedgerScreenV2 extends StatelessWidget {
  const LedgerScreenV2({required this.controller, super.key});
  final MinistryController controller;

  @override
  Widget build(BuildContext context) {
    final pendingLots = controller.lots.where((l) => l.paymentStatus == PaymentStatus.pending && l.status == LotStatus.received).toList();
    
    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PageHeading(controller.t('earnings'),
              'Persistent local lot and payment history.'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: MetricTile(
                    label: controller.t('paid'),
                    value: controller.money(controller.totalEarnings),
                    icon: Icons.check_circle_rounded)),
            const SizedBox(width: 8),
            Expanded(
                child: MetricTile(
                    label: controller.t('pending'),
                    value: controller.money(controller.pendingEarnings),
                    icon: Icons.schedule_rounded)),
          ]),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('All')),
              ButtonSegment(value: 'paid', label: Text('Paid')),
              ButtonSegment(value: 'pending', label: Text('Pending')),
            ],
            selected: {controller.ledgerFilter},
            onSelectionChanged: (selected) {
              controller.setLedgerFilter(selected.first);
            },
          ),
          if (controller.userRole == UserRole.aggregator && pendingLots.length > 1) ...[
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Consolidate ${pendingLots.length} Pending Lots',
              icon: Icons.call_merge_rounded,
              onPressed: () => controller.go(WorkflowScreen.aggregateLots),
            ),
          ],
          const SizedBox(height: 12),
          if (controller.filteredLots.isEmpty)
            const EmptyState(
                icon: Icons.receipt_long_outlined,
                text: 'No lots in this filter.'),
          ...controller.filteredLots.map((lot) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    onTap: () => controller.selectLot(lot.lotId),
                    leading:
                        const Icon(Icons.inventory_2_rounded, color: primary),
                    title: Text(lot.lotId,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text(
                        '${lot.materials.length} material groups • ${lot.totalWeightKg.toStringAsFixed(2)} kg\n${lot.selectedRecyclerName.isEmpty ? 'Recycler not selected' : lot.selectedRecyclerName} • ${shortDate(lot.createdAt)}'),
                    isThreeLine: true,
                    trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(controller.money(lot.ledgerValue),
                              style: const TextStyle(
                                  color: primary, fontWeight: FontWeight.w900)),
                          Text(lot.paymentStatus.name,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: lot.paymentStatus == PaymentStatus.paid
                                      ? primary
                                      : warning,
                                  fontWeight: FontWeight.w800)),
                          Text(statusLabel(lot.status),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                        ]),
                  ),
                ),
              )),
        ],
      );
  }
}

class SyncScreenV2 extends StatelessWidget {
  const SyncScreenV2({required this.controller, super.key});
  final MinistryController controller;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PageHeading(controller.t('sync'),
              'Local records remain usable without a network.'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                LabelValue(
                    'Connection',
                    controller.online
                        ? controller.t('online')
                        : controller.t('offline'),
                    strong: true),
                LabelValue('Pending records', '${controller.pendingSyncCount}'),
                LabelValue('Failed syncs', '${controller.failedSyncCount}'),
                LabelValue(
                    'Last synced',
                    controller.lastSynced == null
                        ? 'Never'
                        : dateTimeLabel(controller.lastSynced!)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
              label: controller.syncing ? 'Syncing...' : controller.t('retry'),
              icon: Icons.sync_rounded,
              onPressed: !controller.online || controller.syncing
                  ? null
                  : controller.syncNow),
          if (!controller.online)
            const Padding(
                padding: EdgeInsets.only(top: 10),
                child: InfoBand(
                    icon: Icons.cloud_off_rounded,
                    title: 'Offline',
                    body: 'New lots are saved locally as Pending Sync.')),
        ],
      );
}

class RecyclerDashboardV2 extends StatelessWidget {
  const RecyclerDashboardV2({required this.controller, super.key});
  final MinistryController controller;

  @override
  Widget build(BuildContext context) {
    final incoming = controller.lots
        .where((lot) => !lot.recyclerConfirmed)
        .toList()
        .reversed
        .toList();
    final completed =
        controller.lots.where((lot) => lot.recyclerConfirmed).toList();
    final todayWeight =
        completed.fold<double>(0, (sum, lot) => sum + (lot.finalWeightKg ?? 0));
    final todayValue = completed.fold<double>(
        0, (sum, lot) => sum + (lot.finalSaleValue ?? 0));
    return ListView(padding: const EdgeInsets.all(16), children: [
      PageHeading(controller.t('recycler'),
          'Operational demo view for lot receipt and payment status.'),
      const SizedBox(height: 6),
      const DemoLabel(text: 'Demo operational data'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: MetricTile(
                label: 'Incoming',
                value: '${incoming.length}',
                icon: Icons.move_to_inbox_rounded)),
        const SizedBox(width: 8),
        Expanded(
            child: MetricTile(
                label: 'Today kg',
                value: todayWeight.toStringAsFixed(1),
                icon: Icons.scale_rounded)),
        const SizedBox(width: 8),
        Expanded(
            child: MetricTile(
                label: 'Value',
                value: controller.money(todayValue),
                icon: Icons.currency_rupee_rounded)),
      ]),
      const SizedBox(height: 14),
      const Text('Incoming lots',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      if (incoming.isEmpty)
        const EmptyState(icon: Icons.inbox_rounded, text: 'No incoming lots.'),
      ...incoming.map((lot) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading:
                    const Icon(Icons.qr_code_scanner_rounded, color: primary),
                title: Text(lot.lotId,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(
                    '${lot.collectorId} • ${lot.materials.length} materials • ${lot.totalWeightKg.toStringAsFixed(2)} kg\n${lot.collectionLocation.label}'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => controller.selectLot(lot.lotId,
                    target: lot.selectedRecyclerId.isEmpty
                        ? WorkflowScreen.recyclerMatch
                        : WorkflowScreen.handover),
              ),
            ),
          )),
      const SizedBox(height: 8),
      OutlinedButton.icon(
          onPressed: () => controller.go(WorkflowScreen.scanQR),
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Scan Incoming Lot QR')),
      if (completed.isNotEmpty) ...[
        const SizedBox(height: 24),
        const Text('Completed / In Facility',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        ...completed.map((lot) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(lot.lotId,
                              style: const TextStyle(fontWeight: FontWeight.w900)),
                          _MetricChip(icon: Icons.inventory_rounded, label: lot.status.name),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${lot.totalWeightKg.toStringAsFixed(2)} kg received',
                          style: const TextStyle(color: textMuted)),
                      const SizedBox(height: 12),
                      if (lot.status == LotStatus.completed)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => controller.processLot(lot.lotId),
                            icon: const Icon(Icons.recycling_rounded),
                            label: const Text('Mark Processed'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    ]);
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF5E6A75)),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF5E6A75), fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class AggregateLotsScreen extends StatelessWidget {
  const AggregateLotsScreen({required this.controller, super.key});
  final MinistryController controller;

  @override
  Widget build(BuildContext context) {
    final pendingLots = controller.lots.where((l) => l.paymentStatus == PaymentStatus.pending && l.status == LotStatus.received).toList();
    if (pendingLots.isEmpty) {
      return const EmptyState(icon: Icons.error_outline_rounded, text: 'No lots available to consolidate.');
    }
    
    // Calculate total materials and weights
    final materialMap = <String, double>{};
    for (final lot in pendingLots) {
      for (final item in lot.materials) {
        materialMap[item.materialId] = (materialMap[item.materialId] ?? 0) + item.weightKg;
      }
    }
    final totalWeight = materialMap.values.fold<double>(0, (sum, weight) => sum + weight);

    return ListView(padding: const EdgeInsets.all(16), children: [
      PageHeading('Consolidate Lots', 'Combine ${pendingLots.length} pending lots into a single large batch for downstream processing.'),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Source Lots', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 8),
              ...pendingLots.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.lotId, style: const TextStyle(fontFamily: 'monospace')),
                    Text('${l.totalWeightKg.toStringAsFixed(2)} kg'),
                  ],
                ),
              )),
              const Divider(height: 24),
              const Text('Consolidated Batch', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 8),
              ...materialMap.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(materialCatalog[e.key]!.name(controller.language)),
                    Text('${e.value.toStringAsFixed(2)} kg', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Weight', style: TextStyle(fontWeight: FontWeight.w900)),
                  Text('${totalWeight.toStringAsFixed(2)} kg', style: const TextStyle(color: primary, fontWeight: FontWeight.w900)),
                ],
              ),
            ]
          ),
        )
      ),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'Confirm Consolidation',
        icon: Icons.check_circle_rounded,
        onPressed: () => controller.aggregateLots(pendingLots.map((l) => l.lotId).toList()),
      ),
    ]);
  }
}

class MakeOfferScreenV2 extends StatefulWidget {
  const MakeOfferScreenV2({required this.controller, super.key});
  final MinistryController controller;

  @override
  State<MakeOfferScreenV2> createState() => _MakeOfferScreenV2State();
}

class _MakeOfferScreenV2State extends State<MakeOfferScreenV2> {
  double? _offerPrice;

  @override
  Widget build(BuildContext context) {
    // We access the lot via ID because selectedLot getter is removed.
    final lotId = widget.controller.selectedLotId;
    final lot = lotId != null ? widget.controller.lots.where((l) => l.lotId == lotId).firstOrNull : null;
    if (lot == null) return const Center(child: Text('Lot unavailable'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PageHeading('Make Offer', 'Submit a custom offer for this lot'),
        const SizedBox(height: 16),
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Offer Price per kg (₹)', border: OutlineInputBorder()),
          onChanged: (v) => setState(() => _offerPrice = double.tryParse(v)),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Submit Offer',
          icon: Icons.check_circle_rounded,
          onPressed: _offerPrice != null
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer submitted')));
                  widget.controller.go(WorkflowScreen.recyclerDashboard);
                }
              : null,
        ),
      ],
    );
  }
}
