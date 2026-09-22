import 'package:flutter/material.dart';

import 'ministry_controller.dart';
import 'screens/collection_workflow.dart';
import 'screens/dashboard_reference.dart';
import 'screens/traceability_workflow.dart';
import 'services/workflow_services.dart';
import 'services/dataset_service.dart';
import 'widgets/common.dart' hide LabelValue;
import 'widgets/ministry_components.dart';
import 'screens/unit_economics.dart';
import 'screens/qr_scanner_screen.dart';
import 'models/workflow_models.dart';

class MinistryApp extends StatefulWidget {
  const MinistryApp({super.key, this.controller});
  final MinistryController? controller;

  @override
  State<MinistryApp> createState() => _MinistryAppState();
}

class _MinistryAppState extends State<MinistryApp> {
  late final MinistryController controller;
  late final bool ownsController;
  bool showSplash = true;
  bool initializationFailed = false;

  @override
  void initState() {
    super.initState();
    ownsController = widget.controller == null;
    controller = widget.controller ?? MinistryController();
    controller.addListener(_refresh);
    _initialize();
  }

  Future<void> _initialize() async {
    final minimumDisplay =
        Future<void>.delayed(const Duration(milliseconds: 1600));
    try {
      await Future.wait([controller.load(), minimumDisplay]);
      if (mounted) setState(() => showSplash = false);
    } catch (_) {
      await minimumDisplay;
      if (mounted) setState(() => initializationFailed = true);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    if (ownsController) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kabadiwala Connect',
        theme: buildTheme(),
        home: showSplash
            ? _SplashScreen(
                failed: initializationFailed,
                onRetry: initializationFailed
                    ? () {
                        setState(() => initializationFailed = false);
                        _initialize();
                      }
                    : null,
              )
            : _AppShell(controller: controller),
      );
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({required this.failed, this.onRetry});
  final bool failed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: .92, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, scale, child) => Opacity(
                  opacity: scale,
                  child: Transform.scale(scale: scale, child: child),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Semantics(
                    image: true,
                    label: 'Kabadiwala Connect logo',
                    child: Image.asset(
                      'assets/branding/kabadiwala_connect_logo.png',
                      width: 290,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (!failed)
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  else ...[
                    const Text(
                      'The app could not finish loading.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ),
      );
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.controller});
  final MinistryController controller;

  @override
  Widget build(BuildContext context) {
    final onboarding = controller.screen == WorkflowScreen.onboarding;
    final child = switch (controller.screen) {
      WorkflowScreen.onboarding => OnboardingScreen(controller: controller),
      WorkflowScreen.home => controller.userRole == UserRole.recycler
          ? RecyclerDashboardV2(controller: controller)
          : HomeDashboard(controller: controller),
      WorkflowScreen.collectionMode =>
        CollectionModeScreen(controller: controller),
      WorkflowScreen.capture => CaptureBatchScreen(controller: controller),
      WorkflowScreen.review => MaterialReviewScreen(controller: controller),
      WorkflowScreen.priceBoard => PriceBoardScreen(controller: controller),
      WorkflowScreen.safety => SafetyScreenV2(controller: controller),
      WorkflowScreen.lotDetail => LotDetailScreenV2(controller: controller),
      WorkflowScreen.recyclerMatch =>
        RecyclerMatchScreenV2(controller: controller),
      WorkflowScreen.handover => HandoverScreenV2(controller: controller),
      WorkflowScreen.payment => PaymentScreenV2(controller: controller),
      WorkflowScreen.ledger => LedgerScreenV2(controller: controller),
      WorkflowScreen.sync => SyncScreenV2(controller: controller),
      WorkflowScreen.recyclerDashboard =>
        RecyclerDashboardV2(controller: controller),
      WorkflowScreen.makeOffer =>
        MakeOfferScreenV2(controller: controller),
      WorkflowScreen.schemes =>
        SchemesScreen(controller: controller),
      WorkflowScreen.aggregateLots =>
        AggregateLotsScreen(controller: controller),
      WorkflowScreen.unitEconomics =>
        UnitEconomicsScreen(controller: controller),
      WorkflowScreen.scanQR =>
        QRScannerScreen(controller: controller),
    };
    return PopScope(
      canPop: onboarding || controller.screen == WorkflowScreen.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.back();
      },
      child: Scaffold(
        appBar: onboarding || controller.screen == WorkflowScreen.home
            ? null
            : AppBar(
                leading: IconButton(
                    tooltip: 'Back',
                    onPressed: controller.back,
                    icon: const Icon(Icons.arrow_back_rounded)),
                titleSpacing: 0,
                title: const Text(
                  'Kabadiwala Connect',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                actions: [
                  IconButton.filledTonal(
                    tooltip: controller.t('home'),
                    onPressed: controller.goHome,
                    style: IconButton.styleFrom(
                      foregroundColor: primary,
                      backgroundColor: primaryLight,
                    ),
                    icon: const Icon(Icons.home_rounded),
                  ),
                  _StatusButton(controller: controller),
                  PopupMenuButton<String>(
                    tooltip: 'Language',
                    initialValue: controller.language,
                    icon: const Icon(Icons.language_rounded),
                    onSelected: controller.setLanguage,
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'en', child: Text('English')),
                      PopupMenuItem(value: 'hi', child: Text('हिंदी')),
                      PopupMenuItem(value: 'mr', child: Text('मराठी')),
                    ],
                  ),
                ],
              ),
        body: SafeArea(
          top: onboarding || controller.screen == WorkflowScreen.home,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: child,
            ),
          ),
        ),
        bottomNavigationBar: controller.screen == WorkflowScreen.home
            ? _HomeBottomNavigation(controller: controller)
            : null,
      ),
    );
  }
}

class _HomeBottomNavigation extends StatelessWidget {
  const _HomeBottomNavigation({required this.controller});

  final MinistryController controller;

  Future<void> _confirmLogout(BuildContext sheetContext) async {
    final confirmed = await showDialog<bool>(
      context: sheetContext,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: danger, size: 34),
        title: Text(controller.t('logoutTitle')),
        content: Text(controller.t('logoutMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(controller.t('cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: danger),
            icon: const Icon(Icons.logout_rounded),
            label: Text(controller.t('logout')),
          ),
        ],
      ),
    );
    if (confirmed != true || !sheetContext.mounted) return;
    Navigator.pop(sheetContext);
    await controller.logout();
  }

  void _showProfile(BuildContext context) {
    final profile = controller.profile;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE6F6E9), Color(0xFFF4FAEE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFCFE5D2)),
              ),
              child: Column(children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x35176B3A),
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                Text(
                  (profile?.collectorName ?? '').trim().isEmpty
                      ? 'Kabadiwala'
                      : profile!.collectorName,
                  textAlign: TextAlign.center,
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 5),
                Text(controller.t('profile'),
                    style: const TextStyle(
                        color: primary, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 16),
            _ProfileInfoRow(
              icon: Icons.badge_outlined,
              label: controller.t('collectorNumber'),
              value: profile?.collectorId ?? '—',
            ),
            const SizedBox(height: 10),
            _ProfileInfoRow(
              icon: Icons.location_on_outlined,
              label: controller.t('operatingArea'),
              value: (profile?.operatingLocation ?? '').isEmpty
                  ? '—'
                  : profile!.operatingLocation,
            ),
            const SizedBox(height: 10),
            _ProfileInfoRow(
              icon: Icons.language_rounded,
              label: controller.t('language'),
              value: switch (controller.language) {
                'mr' => 'मराठी',
                'hi' => 'हिन्दी',
                _ => 'English',
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  controller.go(WorkflowScreen.unitEconomics);
                },
                icon: const Icon(Icons.show_chart_rounded),
                label: const Text('View Unit Economics', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final data = DatasetService.generateDatasets(controller.lots);
                  // In a real app this would save to a file or share it. 
                  // For the demo we just print it to show it works.
                  print('Datasets Generated: ${data.keys.join(', ')}');
                  ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('Datasets logged to console.')));
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Export Datasets (Demo)', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  controller.resetDemo();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo state reset. Offline mode active.')));
                },
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Reset Demo State', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(sheetContext),
                style: OutlinedButton.styleFrom(
                  foregroundColor: danger,
                  side: const BorderSide(color: Color(0xFFF0B8B8)),
                  backgroundColor: const Color(0xFFFFF7F7),
                  minimumSize: const Size.fromHeight(54),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: Text(controller.t('logout'),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 12,
        shadowColor: const Color(0x220B3D25),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(children: [
              _BottomDestination(
                icon: Icons.home_rounded,
                label: controller.t('home'),
                selected: true,
                onTap: () {},
              ),
              _BottomDestination(
                icon: Icons.bar_chart_rounded,
                label: controller.t('priceBoard'),
                onTap: () => controller.go(WorkflowScreen.priceBoard),
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: controller.t('start'),
                  child: Center(
                    child: InkWell(
                      onTap: () => controller.go(WorkflowScreen.collectionMode),
                      customBorder: const CircleBorder(),
                      child: Ink(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x44176B3A),
                              blurRadius: 14,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.document_scanner_rounded,
                            color: Colors.white, size: 29),
                      ),
                    ),
                  ),
                ),
              ),
              _BottomDestination(
                icon: Icons.inventory_2_outlined,
                label: controller.t('myLots'),
                onTap: () => controller.go(WorkflowScreen.ledger),
              ),
              _BottomDestination(
                icon: Icons.person_outline_rounded,
                label: controller.t('profile'),
                onTap: () => _showProfile(context),
              ),
            ]),
          ),
        ),
      );
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: textMuted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: textMain, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ]),
      );
}

class _BottomDestination extends StatelessWidget {
  const _BottomDestination({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon,
                  size: 24,
                  color: selected ? primary : const Color(0xFF68716C)),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? primary : const Color(0xFF68716C),
                ),
              ),
            ]),
          ),
        ),
      );
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({required this.controller});
  final MinistryController controller;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => controller.go(WorkflowScreen.sync),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(children: [
            Icon(
                controller.online
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_off_rounded,
                size: 18,
                color: controller.online ? primary : warning),
            const SizedBox(width: 4),
            Text(
                controller.online
                    ? controller.t('online')
                    : controller.t('offline'),
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            if (controller.pendingSyncCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration:
                    const BoxDecoration(color: warning, shape: BoxShape.circle),
                child: Text('${controller.pendingSyncCount}',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ]),
        ),
      );
}
