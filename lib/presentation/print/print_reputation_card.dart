import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';

class PrintReputationCard extends StatefulWidget {
  const PrintReputationCard({super.key});

  @override
  State<PrintReputationCard> createState() => _PrintReputationCardState();
}

class _PrintReputationCardState extends State<PrintReputationCard> {
  final _repo = PrintRepository();
  PrintReputation? _rep;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repo.myReputation();
    if (!mounted) return;
    if (result is PrintSuccess<PrintReputation>) {
      setState(() => _rep = result.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rep = _rep;
    if (rep == null) return const SizedBox.shrink();
    Widget row(String label, double value) => Padding(
      padding: EdgeInsets.only(bottom: 6.v),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
              color: AppDs.printGold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: EdgeInsets.only(bottom: AppDs.space4.v),
      padding: EdgeInsets.all(14.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'lbl_print_customer_rating'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.v),
          row('lbl_print_customer_rating'.tr, rep.rating),
          row('lbl_print_dim_communication'.tr, rep.communication),
          row('lbl_print_dim_payment'.tr, rep.payment),
          row('lbl_print_dim_professionalism'.tr, rep.professionalism),
        ],
      ),
    );
  }
}
