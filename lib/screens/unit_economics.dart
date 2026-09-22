import 'package:flutter/material.dart';
import '../ministry_controller.dart';
import '../widgets/common.dart';
import '../widgets/ministry_components.dart';

class UnitEconomicsScreen extends StatelessWidget {
  const UnitEconomicsScreen({required this.controller, super.key});
  final MinistryController controller;

  @override
  Widget build(BuildContext context) {
    // These numbers would ideally come from the DatasetService or active transaction data.
    // For demonstration, we use realistic modeled metrics for a typical collector's monthly operation.
    const double currentEarnings = 12000.0;
    const double platformEarnings = 15800.0;
    
    // Breakdown for Current Route
    const double currentGross = 16000.0;
    const double currentTransport = 1500.0;
    const double currentMiddlemanDeductions = 2500.0;
    
    // Breakdown for Platform Route
    const double platformGross = 17000.0; // Slightly better market matching
    const double platformTransport = 800.0; // Optimized logistics
    const double platformFee = 400.0; // Platform transaction/SaaS fee (if applicable)

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Economics', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PageHeading('Impact Analysis', 'Comparative economic model for scrap collectors.'),
          const SizedBox(height: 16),
          _RouteCard(
            title: 'Current Route',
            gross: currentGross,
            deductions: [
              _Deduction('Transport', currentTransport),
              _Deduction('Middleman Margin', currentMiddlemanDeductions),
            ],
            net: currentEarnings,
            color: const Color(0xFFFFF5DF),
            accent: const Color(0xFFB45309),
          ),
          const SizedBox(height: 16),
          _RouteCard(
            title: 'Platform Route',
            gross: platformGross,
            deductions: [
              _Deduction('Optimized Transport', platformTransport),
              _Deduction('Platform Service Fee', platformFee),
            ],
            net: platformEarnings,
            color: const Color(0xFFEAF8ED),
            accent: const Color(0xFF138347),
            highlight: true,
          ),
          const SizedBox(height: 24),
          const Text('Platform Sustainability', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
            'The platform does not charge the collector a fee. Sustainability is achieved through:\n\n'
            '1. B2B Recycler Subscriptions: Recyclers pay for access to verified, sorted material streams.\n'
            '2. Government Integration: Institutional funding for maintaining EPR datasets and scheme navigation.\n'
            '3. Aggregated Logistics: Monetizing optimized transport routes for bulk pickups.',
            style: TextStyle(color: Color(0xFF475569), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Deduction {
  const _Deduction(this.label, this.amount);
  final String label;
  final double amount;
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.title,
    required this.gross,
    required this.deductions,
    required this.net,
    required this.color,
    required this.accent,
    this.highlight = false,
  });

  final String title;
  final double gross;
  final List<_Deduction> deductions;
  final double net;
  final Color color;
  final Color accent;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: highlight ? const BorderSide(color: Color(0xFF138347), width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent)),
            const Divider(height: 24),
            _LineItem('Gross Sale Value', gross, isBold: true),
            const SizedBox(height: 8),
            ...deductions.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _LineItem('- ${d.label}', -d.amount, color: const Color(0xFFDC2626)),
            )),
            const Divider(height: 24),
            _LineItem('Net Earnings', net, isBold: true, color: accent, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem(this.label, this.amount, {this.isBold = false, this.color, this.size});
  final String label;
  final double amount;
  final bool isBold;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w800 : FontWeight.w500, fontSize: size, color: color)),
        Text('₹${amount.abs().toStringAsFixed(0)}', style: TextStyle(fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, fontSize: size, color: color)),
      ],
    );
  }
}
