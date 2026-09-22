import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/ministry_data.dart';
import '../ministry_controller.dart';
import '../models/workflow_models.dart';
import '../services/workflow_services.dart';
import '../widgets/common.dart' hide LabelValue;
import '../widgets/ministry_components.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.controller, super.key});
  final MinistryController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  UserRole? selectedRole;

  late final TextEditingController name;
  late final TextEditingController id;
  late final TextEditingController location;

  late final TextEditingController facilityName;
  late final TextEditingController facilityLocation;
  late final TextEditingController authNumber;

  bool attempted = false;
  bool rejectedInput = false;

  bool get validNumber => RegExp(r'^\d{5,10}$').hasMatch(id.text);
  bool get validName => name.text.trim().length >= 2;
  bool get validFacility => facilityName.text.trim().length >= 2 && authNumber.text.trim().isNotEmpty;

  void _showLanguageSelector() {
    final c = widget.controller;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(c.t('chooseLanguage'),
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            for (final option in const [
              ('en', 'English'),
              ('mr', 'मराठी'),
              ('hi', 'हिन्दी'),
            ])
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Icon(
                  c.language == option.$1
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: c.language == option.$1 ? primary : textMuted,
                ),
                title: Text(option.$2,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  c.setLanguage(option.$1);
                  Navigator.pop(sheetContext);
                },
              ),
          ]),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.profile;
    name = TextEditingController(text: profile?.collectorName ?? '');
    id = TextEditingController(text: profile?.collectorId ?? '');
    location = TextEditingController(text: profile?.operatingLocation ?? '');

    final rProfile = widget.controller.recyclerProfile;
    facilityName = TextEditingController(text: rProfile?.facilityName ?? '');
    facilityLocation = TextEditingController(text: rProfile?.facilityLocation ?? '');
    authNumber = TextEditingController(text: rProfile?.authorizationNumber ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    id.dispose();
    location.dispose();
    facilityName.dispose();
    facilityLocation.dispose();
    authNumber.dispose();
    super.dispose();
  }

  Widget _buildRolePicker(MinistryController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Who are you?', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _RoleCard(
          title: 'Collector / Kabadiwala',
          subtitle: 'Individual scrap collector',
          icon: Icons.person_rounded,
          onTap: () => setState(() => selectedRole = UserRole.collector),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          title: 'Small Aggregator',
          subtitle: 'Consolidate scrap from multiple collectors',
          icon: Icons.store_rounded,
          onTap: () => setState(() => selectedRole = UserRole.aggregator),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          title: 'Authorized Recycler',
          subtitle: 'Registered facility',
          icon: Icons.factory_rounded,
          onTap: () => setState(() => selectedRole = UserRole.recycler),
        ),
      ],
    );
  }

  Widget _buildInformalForm(MinistryController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(c.t('onboardingTitle'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(c.t('onboardingSub')),
        const SizedBox(height: 22),
        TextField(
          controller: name,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: c.t('collectorName'),
            prefixIcon: const Icon(Icons.person_outline_rounded),
            errorText: attempted && !validName ? c.t('nameError') : null,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: id,
          keyboardType: TextInputType.number,
          maxLength: 10,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [
            StrictCollectorNumberFormatter(onRejected: () {
              if (!rejectedInput && mounted) {
                setState(() => rejectedInput = true);
              }
            }),
          ],
          onChanged: (_) => setState(() {
            attempted = true;
            rejectedInput = false;
          }),
          decoration: InputDecoration(
              labelText: c.t('collectorId'),
              prefixIcon: const Icon(Icons.phone_rounded),
              errorText: (attempted || rejectedInput) && !validNumber
                  ? c.t('phoneError')
                  : null),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: location,
          decoration: InputDecoration(
              labelText: c.t('location'),
              prefixIcon: const Icon(Icons.location_city_rounded)),
        ),
        if (c.lastError.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(c.lastError,
              style: const TextStyle(color: danger, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 16),
        PrimaryButton(
          label: c.t('continue'),
          icon: Icons.arrow_forward_rounded,
          onPressed: validNumber && validName
              ? () => c.saveProfile(id.text, location.text, selectedRole!, name.text)
              : null,
        ),
      ],
    );
  }

  Widget _buildRecyclerForm(MinistryController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Recycler Registration', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text('Enter authorized facility details.'),
        const SizedBox(height: 22),
        TextField(
          controller: facilityName,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Facility Name',
            prefixIcon: const Icon(Icons.factory_rounded),
            errorText: attempted && facilityName.text.isEmpty ? 'Required' : null,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: facilityLocation,
          decoration: const InputDecoration(
            labelText: 'Facility Location',
            prefixIcon: Icon(Icons.location_city_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: authNumber,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Authorization Number',
            prefixIcon: const Icon(Icons.verified_user_rounded),
            errorText: attempted && authNumber.text.isEmpty ? 'Required' : null,
          ),
        ),
        if (c.lastError.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(c.lastError,
              style: const TextStyle(color: danger, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Register Facility',
          icon: Icons.arrow_forward_rounded,
          onPressed: validFacility
              ? () => c.saveRecyclerProfile(facilityName.text, facilityLocation.text, authNumber.text, ['All'])
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListView(padding: const EdgeInsets.all(20), children: [
      SizedBox(
        height: MediaQuery.sizeOf(context).width < 380 ? 86 : 98,
        child: Stack(alignment: Alignment.topCenter, children: [
          Center(
            child: Semantics(
              image: true,
              label: 'Kabadiwala Connect logo',
              child: Image.asset(
                'assets/branding/kabadiwala_connect_logo.png',
                width: MediaQuery.sizeOf(context).width < 380 ? 178 : 205,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton.filledTonal(
              tooltip: 'Language',
              onPressed: _showLanguageSelector,
              style: IconButton.styleFrom(
                foregroundColor: primaryDark,
                backgroundColor: primaryLight,
                side: const BorderSide(color: Color(0xFFCFE2D2)),
              ),
              icon: const Icon(Icons.language_rounded),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Text(c.t('formalRecycling'),
          textAlign: TextAlign.center,
          style:
              const TextStyle(color: textMuted, fontWeight: FontWeight.w700)),
      const SizedBox(height: 28),
      if (selectedRole == null)
        _buildRolePicker(c)
      else if (selectedRole == UserRole.recycler)
        _buildRecyclerForm(c)
      else
        _buildInformalForm(c),
      
      if (selectedRole != null) ...[
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => selectedRole = null),
          child: const Text('Back to Role Selection'),
        ),
      ],
      const SizedBox(height: 20),
    ]);
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFEAF8ED),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryDark, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: textMuted, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: textMuted),
          ],
        ),
      ),
    );
  }
}

class StrictCollectorNumberFormatter extends TextInputFormatter {
  StrictCollectorNumberFormatter({required this.onRejected});
  final VoidCallback onRejected;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (RegExp(r'^\d{0,10}$').hasMatch(newValue.text)) return newValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => onRejected());
    return oldValue;
  }
}

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({required this.controller, super.key});
  final MinistryController controller;

  void _openPending() {
    controller.setLedgerFilter('pending');
    controller.go(WorkflowScreen.ledger);
  }

  void _openLedger() {
    controller.setLedgerFilter('all');
    controller.go(WorkflowScreen.ledger);
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        color: primary,
        onRefresh: controller.syncNow,
        child: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 380;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                compact ? 14 : 18, 10, compact ? 14 : 18, 24),
            children: [
              _HomeHeader(controller: controller, compact: compact),
              const SizedBox(height: 14),
              _WelcomeHero(controller: controller),
              const SizedBox(height: 14),
              SizedBox(
                height: compact ? 132 : 142,
                child: Row(children: [
                  Expanded(
                    child: _SummaryCard(
                      label: controller.t('earnings'),
                      value: controller.money(controller.totalEarnings),
                      caption:
                          _homeCopy(controller.language, 'collectionValue'),
                      icon: Icons.currency_rupee_rounded,
                      tint: const Color(0xFFEAF8ED),
                      accent: const Color(0xFF138347),
                      onTap: _openLedger,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      label: controller.t('pending'),
                      value: controller.money(controller.pendingEarnings),
                      caption: _homeCopy(controller.language, 'settlement'),
                      icon: Icons.schedule_rounded,
                      tint: const Color(0xFFFFF5DF),
                      accent: const Color(0xFFD59422),
                      onTap: _openPending,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      label: controller.t('myLots'),
                      value: '${controller.lots.length}',
                      caption: _homeCopy(controller.language, 'lotsCreated'),
                      icon: Icons.inventory_2_rounded,
                      tint: const Color(0xFFEAF7FC),
                      accent: const Color(0xFF1687B4),
                      onTap: _openLedger,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              _StartCollectionCard(controller: controller),
              const SizedBox(height: 7),
              Text(
                _homeCopy(controller.language, 'scanCollect'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 10,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Text(_homeCopy(controller.language, 'quickActions'),
                    style: const TextStyle(
                        color: textMain,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                if (!compact) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _homeCopy(controller.language, 'onePlace'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: compact ? 1.30 : 1.52,
                children: [
                  _QuickActionCard(
                    label: controller.t('priceBoard'),
                    subtitle: _homeCopy(controller.language, 'latestRates'),
                    icon: Icons.trending_up_rounded,
                    iconBackground: const Color(0xFFE4F6E9),
                    iconColor: const Color(0xFF08783C),
                    onTap: () => controller.go(WorkflowScreen.priceBoard),
                  ),
                  _QuickActionCard(
                    label: controller.t('myLots'),
                    subtitle: _homeCopy(controller.language, 'viewManage'),
                    icon: Icons.inventory_2_rounded,
                    iconBackground: const Color(0xFFEAF8ED),
                    iconColor: const Color(0xFF176B3A),
                    onTap: _openLedger,
                  ),
                  _QuickActionCard(
                    label: 'Schemes',
                    subtitle: 'EPR & Formalization',
                    icon: Icons.account_balance_rounded,
                    iconBackground: const Color(0xFFFFEDE2),
                    iconColor: const Color(0xFFB65E20),
                    onTap: () => controller.go(WorkflowScreen.schemes),
                  ),
                  _QuickActionCard(
                    label: controller.t('sync'),
                    subtitle: _syncSubtitle(controller),
                    icon: controller.syncing
                        ? Icons.sync_rounded
                        : (controller.online
                            ? Icons.sync_rounded
                            : Icons.cloud_off_rounded),
                    iconBackground: const Color(0xFFE0F4FC),
                    iconColor: const Color(0xFF087CA9),
                    count: controller.pendingSyncCount,
                    onTap: () => controller.go(WorkflowScreen.sync),
                  ),

                  _QuickActionCard(
                    label: controller.t('earnings'),
                    subtitle: _homeCopy(controller.language, 'incomeDetails'),
                    icon: Icons.account_balance_wallet_rounded,
                    iconBackground: const Color(0xFFE5F6E8),
                    iconColor: const Color(0xFF075E32),
                    onTap: _openLedger,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _MinistryAlignmentCard(),
            ],
          );
        }),
      );
}

String _greeting(String language) => switch (language) {
      'hi' => 'नमस्ते',
      'mr' => 'नमस्कार',
      _ => 'Welcome',
    };

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.controller, required this.compact});

  final MinistryController controller;
  final bool compact;

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(controller.t('chooseLanguage'),
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            for (final option in const [
              ('en', 'English'),
              ('mr', 'मराठी'),
              ('hi', 'हिन्दी'),
            ])
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Icon(
                  controller.language == option.$1
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: controller.language == option.$1 ? primary : textMuted,
                ),
                title: Text(option.$2,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  controller.setLanguage(option.$1);
                  Navigator.pop(sheetContext);
                },
              ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Image.asset(
            'assets/branding/kabadiwala_connect_logo.png',
            height: compact ? 43 : 50,
            alignment: Alignment.centerLeft,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => controller.go(WorkflowScreen.sync),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding:
                EdgeInsets.symmetric(horizontal: compact ? 9 : 12, vertical: 8),
            decoration: BoxDecoration(
              color: controller.online
                  ? const Color(0xFFEAF8ED)
                  : const Color(0xFFFFF3E4),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: controller.online
                      ? const Color(0xFFCFEAD4)
                      : const Color(0xFFF0D0A6)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: controller.online ? const Color(0xFF159447) : warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                controller.online
                    ? controller.t('online')
                    : controller.t('offline'),
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ]),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Language',
          onPressed: () => _showLanguageSelector(context),
          style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryDark,
              side: const BorderSide(color: Color(0xFFE2ECE3))),
          icon: const Icon(Icons.language_rounded),
        ),
      ]);
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.controller});

  final MinistryController controller;

  @override
  Widget build(BuildContext context) {
    final savedName = controller.profile?.collectorName.trim() ?? '';
    final displayName = savedName.isEmpty ? 'Kabadiwala' : savedName;
    return Container(
      constraints: const BoxConstraints(minHeight: 184),
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF4FAE9), Color(0xFFE1F4E7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(children: [
        Positioned(
          right: 3,
          bottom: -8,
          child: Icon(Icons.eco_rounded,
              size: 112, color: primary.withValues(alpha: .13)),
        ),
        Positioned(
          right: 44,
          top: 12,
          child: Transform.rotate(
            angle: -.35,
            child: const Icon(Icons.eco_rounded,
                size: 42, color: Color(0xFF6DBA6C)),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: .7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_greeting(controller.language)},',
                    style: const TextStyle(
                        color: textMain,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryDark,
                    fontSize: 32,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(_homeCopy(controller.language, 'goodAgain'),
                    style: const TextStyle(color: textMuted, fontSize: 12)),
                const SizedBox(height: 9),
                Text(
                  _homeCopy(controller.language, 'smallSteps'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.tint,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color tint;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: tint,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(minHeight: 137),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0E0B3D25),
                    blurRadius: 12,
                    offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration:
                        BoxDecoration(color: accent, shape: BoxShape.circle),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: const TextStyle(
                          color: textMain,
                          fontSize: 23,
                          fontWeight: FontWeight.w900)),
                ),
                const Spacer(),
                Text(caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: textMuted, fontSize: 10)),
              ],
            ),
          ),
        ),
      );
}

class _StartCollectionCard extends StatelessWidget {
  const _StartCollectionCard({required this.controller});

  final MinistryController controller;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: controller.t('start'),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () => controller.go(WorkflowScreen.collectionMode),
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF159447), Color(0xFF075E32)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3B08783C),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(children: [
                Positioned(
                  right: -15,
                  bottom: -32,
                  child: Icon(Icons.eco_rounded,
                      color: Colors.white.withValues(alpha: .13), size: 110),
                ),
                Center(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.add_a_photo_rounded,
                        color: Colors.white, size: 29),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Text(controller.t('start'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white, size: 18),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
    this.count = 0,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 10,
                    offset: Offset(0, 3)),
              ],
            ),
            child: Row(children: [
              Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: 46,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                if (count > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints:
                          const BoxConstraints(minWidth: 19, minHeight: 19),
                      decoration: const BoxDecoration(
                          color: warning, shape: BoxShape.circle),
                      child: Text('$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                  ),
              ]),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: textMain,
                            fontSize: 13,
                            height: 1.12,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: textMuted, fontSize: 10)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: textMuted, size: 18),
            ]),
          ),
        ),
      );
}

class _MinistryAlignmentCard extends StatelessWidget {
  const _MinistryAlignmentCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF2FAEA), Color(0xFFDFF3DF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFC9E3C8)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(children: [
          Positioned(
            right: -18,
            bottom: -30,
            child: Icon(Icons.eco_rounded,
                size: 105, color: primary.withValues(alpha: .12)),
          ),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                  color: Color(0xFFE1F5E4), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_rounded,
                  color: primaryDark, size: 27),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('A GREENER, STRONGER INDIA',
                        style: TextStyle(
                            color: primary,
                            fontSize: 9,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w900)),
                    SizedBox(height: 5),
                    Text('Ministry of Mines alignment',
                        style: TextStyle(
                            color: textMain,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text(
                      'Formal recycling, traceable handovers and awareness of potentially recoverable critical materials.',
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                  ]),
            ),
          ]),
        ]),
      );
}

String _syncSubtitle(MinistryController controller) {
  if (controller.syncing) return 'Syncing…';
  if (!controller.online) return controller.t('offline');
  if (controller.pendingSyncCount > 0) {
    return '${controller.pendingSyncCount} ${controller.t('pendingSync')}';
  }
  return _homeCopy(controller.language, 'updated');
}

String _homeCopy(String language, String key) {
  const copy = <String, Map<String, String>>{
    'en': {
      'collectionValue': 'Total collection value',
      'settlement': 'Awaiting settlement',
      'lotsCreated': 'Total lots created',
      'scanCollect': 'SCAN  •  COLLECT  •  MAKE A DIFFERENCE',
      'quickActions': 'Quick actions',
      'onePlace': 'Everything you need, in one place',
      'latestRates': 'Check latest rates',
      'viewManage': 'View and manage',
      'workSafe': 'Work safe, stay safe',
      'partnerTrack': 'Partner and track',
      'incomeDetails': 'View income details',
      'updated': 'Your data is updated',
      'goodAgain': 'Good to see you again!',
      'smallSteps': 'Small steps. A cleaner, greener tomorrow.',
    },
    'hi': {
      'collectionValue': 'कुल संग्रह मूल्य',
      'settlement': 'भुगतान की प्रतीक्षा',
      'lotsCreated': 'कुल बनाए गए लॉट',
      'scanCollect': 'स्कैन  •  संग्रह  •  बदलाव',
      'quickActions': 'त्वरित कार्य',
      'onePlace': 'आपकी जरूरत की हर चीज',
      'latestRates': 'नवीनतम भाव देखें',
      'viewManage': 'देखें और संभालें',
      'workSafe': 'सुरक्षित काम करें',
      'partnerTrack': 'साझेदार और ट्रैक',
      'incomeDetails': 'आय का विवरण देखें',
      'updated': 'डेटा अपडेट है',
      'goodAgain': 'आपसे फिर मिलकर खुशी हुई!',
      'smallSteps': 'छोटे कदम। एक स्वच्छ, हरित कल।',
    },
    'mr': {
      'collectionValue': 'एकूण संकलन मूल्य',
      'settlement': 'देयकाची प्रतीक्षा',
      'lotsCreated': 'एकूण तयार लॉट',
      'scanCollect': 'स्कॅन  •  संकलन  •  बदल',
      'quickActions': 'जलद कृती',
      'onePlace': 'सर्व गरजा एकाच ठिकाणी',
      'latestRates': 'नवीनतम भाव पहा',
      'viewManage': 'पहा आणि व्यवस्थापित करा',
      'workSafe': 'सुरक्षित काम करा',
      'partnerTrack': 'भागीदार आणि ट्रॅक',
      'incomeDetails': 'उत्पन्न तपशील पहा',
      'updated': 'डेटा अद्ययावत आहे',
      'goodAgain': 'तुम्हाला पुन्हा पाहून आनंद झाला!',
      'smallSteps': 'छोटी पावले. स्वच्छ, हरित उद्या.',
    },
  };
  return copy[language]?[key] ?? copy['en']![key] ?? key;
}

class PriceBoardScreen extends StatelessWidget {
  const PriceBoardScreen({required this.controller, super.key});
  final MinistryController controller;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PageHeading(controller.t('priceBoard'),
              '7-day seeded reference history for Pune.'),
          const SizedBox(height: 6),
          DemoLabel(text: controller.t('referenceOnly')),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search material'),
            onChanged: (value) {
              controller.setPriceSearch(value);
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: controller.priceMaterialFilter,
            decoration: const InputDecoration(labelText: 'Material filter'),
            items: [
              const DropdownMenuItem(
                  value: 'all', child: Text('All materials')),
              ...materialCatalog.values.map((item) => DropdownMenuItem(
                  value: item.id, child: Text(item.name(controller.language)))),
            ],
            onChanged: (value) {
              controller.setPriceMaterialFilter(value ?? 'all');
            },
          ),
          const SizedBox(height: 12),
          if (controller.filteredPrices.isEmpty)
            const EmptyState(
                icon: Icons.search_off_rounded,
                text: 'No matching reference prices.')
          else
            ...controller.filteredPrices.map((price) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PriceCard(controller: controller, price: price),
                )),
        ],
      );
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.controller, required this.price});
  final MinistryController controller;
  final PriceRecord price;

  @override
  Widget build(BuildContext context) {
    final material = materialCatalog[price.materialId]!;
    final trendIcon = price.trend > 0
        ? Icons.trending_up_rounded
        : (price.trend < 0
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded);
    final trendLabel = price.trend > 0
        ? 'Increasing'
        : (price.trend < 0 ? 'Decreasing' : 'Stable');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(materialIcon(material.icon), color: primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text(material.name(controller.language),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 17))),
            IconButton(
                tooltip: 'Speak reference price',
                onPressed: () => controller.speak(
                    '${material.name(controller.language)}. ${price.marketMin.round()} to ${price.marketMax.round()} rupees per kilogram. Demo reference data.'),
                icon: const Icon(Icons.volume_up_rounded)),
          ]),
          Text(
              '${controller.money(price.marketMin)}-${controller.money(price.marketMax)} / ${price.unit}',
              style: const TextStyle(
                  fontSize: 20, color: primary, fontWeight: FontWeight.w900)),
          Text('${price.location} • Updated ${shortDate(price.updatedAt)}',
              style: const TextStyle(color: textMuted, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
              height: 54,
              child: CustomPaint(
                  painter: _Sparkline(price.history),
                  child: const SizedBox.expand())),
          const SizedBox(height: 6),
          Row(children: [
            Icon(trendIcon, size: 18, color: primary),
            const SizedBox(width: 4),
            Text('$trendLabel • 7 days',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }
}

class _Sparkline extends CustomPainter {
  const _Sparkline(this.points);
  final List<PricePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final values = points.map((point) => point.value).toList();
    final low = values.reduce(min);
    final high = values.reduce(max);
    final range = max(1, high - low);
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y =
          size.height - ((values[index] - low) / range * (size.height - 8)) - 4;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _Sparkline oldDelegate) =>
      oldDelegate.points != points;
}

class SafetyScreenV2 extends StatelessWidget {
  const SafetyScreenV2({required this.controller, super.key});
  final MinistryController controller;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PageHeading(controller.t('safety'), controller.t('safetyIntro')),
          const SizedBox(height: 12),
          ...materialCatalog.values.where((item) => item.hazardous).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SafetyNoticeCard(
                    title: controller.t('${item.id}WarningTitle'),
                    body: controller.t('${item.id}WarningBody'),
                    instructions: controller.t('${item.id}WarningSteps'),
                    speakLabel: controller.t('speakSafety'),
                    onSpeak: () => controller.speak(
                        safetyLines(controller.language, item.id).join('. ')),
                  ),
                ),
              ),
        ],
      );
}

class SchemesScreen extends StatelessWidget {
  const SchemesScreen({required this.controller, super.key});
  final MinistryController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const PageHeading('Government & EPR Schemes', 'Access formal recycling initiatives, certification guidance, and available MSME support.'),
      const SizedBox(height: 12),
      const _SchemeCard(
        title: 'EPR Registration (CPCB)',
        authority: 'Central Pollution Control Board',
        eligibility: 'Authorized Recyclers, Dismantlers, Refurbishers',
        description: 'Mandatory registration under E-Waste (Management) Rules, 2022 to generate and trade EPR certificates.',
        documents: 'Consent to Operate, GST, PAN, Factory License, Machinery Details',
        actionLabel: 'View EPR Portal Guide',
      ),
      const SizedBox(height: 10),
      const _SchemeCard(
        title: 'MSME Sustainable (ZED) Certification',
        authority: 'Ministry of MSME',
        eligibility: 'All MSME units (Collectors & Aggregators acting as micro-enterprises)',
        description: 'Financial assistance and certification for adopting Zero Defect Zero Effect (ZED) practices.',
        documents: 'Udyam Registration, Aadhaar, Bank Details',
        actionLabel: 'Apply for ZED',
      ),
      const SizedBox(height: 10),
      const _SchemeCard(
        title: 'Informal Sector Formalization Grant',
        authority: 'State Pollution Control Board',
        eligibility: 'Individual Kabadiwalas & Scrap Aggregators',
        description: 'Provides safety gear, formal identity cards, and micro-loans to transition into the formal ecosystem.',
        documents: 'Aadhaar, Municipal Permit, Bank Account',
        actionLabel: 'Check State Eligibility',
      ),
    ]);
  }
}

class _SchemeCard extends StatelessWidget {
  const _SchemeCard({
    required this.title,
    required this.authority,
    required this.eligibility,
    required this.description,
    required this.documents,
    required this.actionLabel,
  });

  final String title;
  final String authority;
  final String eligibility;
  final String description;
  final String documents;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_rounded, color: primary),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
              ],
            ),
            const SizedBox(height: 6),
            Text(authority, style: const TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 12)),
            const Divider(),
            LabelValue('Eligibility', eligibility),
            LabelValue('About', description),
            LabelValue('Required Documents', documents),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: actionLabel,
                icon: Icons.open_in_new_rounded,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This would open the official scheme portal or application form.')));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
