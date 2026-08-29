import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_export.dart';
import '../../data/models/wallet_models.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'bloc/wallet_bloc.dart';

class WalletTransactionsScreen extends StatefulWidget {
  const WalletTransactionsScreen({super.key});

  static Widget builder(BuildContext context) {
    return const WalletTransactionsScreen();
  }

  @override
  State<WalletTransactionsScreen> createState() =>
      _WalletTransactionsScreenState();
}

class _WalletTransactionsScreenState extends State<WalletTransactionsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(const WalletLoadTransactionsEvent());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final bloc = context.read<WalletBloc>();
    final state = bloc.state;
    if (!state.hasMoreTransactions || state.isLoadingMoreTransactions) return;
    if (_scrollController.position.extentAfter < 200) {
      bloc.add(
        WalletLoadTransactionsEvent(page: state.transactionsPage + 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDs.surfaceBase,
      appBar: CustomAppBar(
        leading: AppbarLeadingImage(
          imagePath: ImageConstant.imgArrowDownPrimary,
          onTap: () => NavigatorService.goBack(),
        ),
        centerTitle: true,
        title: AppbarTitle(text: 'lbl_wallet_transactions'.tr),
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state.isLoadingTransactions && state.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppDs.space6.h),
                child: AppText(
                  'msg_wallet_transactions_empty'.tr,
                  variant: AppTextVariant.body,
                  color: AppDs.textOnDarkSecondary,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<WalletBloc>();
              bloc.add(const WalletLoadTransactionsEvent());
              await bloc.stream.firstWhere((s) => !s.isLoadingTransactions);
            },
            child: ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                AppDs.space4.h,
                AppDs.space4.v,
                AppDs.space4.h,
                AppDs.space8.v,
              ),
              itemCount: state.transactions.length +
                  (state.isLoadingMoreTransactions ? 1 : 0),
              separatorBuilder: (_, __) => SizedBox(height: AppDs.space2.v),
              itemBuilder: (context, index) {
                if (index >= state.transactions.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _TxnTile(tx: state.transactions[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  const _TxnTile({required this.tx});

  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final credit = tx.amount >= 0;
    final amountColor =
        credit ? const Color(0xFF4ADE80) : const Color(0xFFF87171);
    final title = tx.description.isNotEmpty
        ? tx.description
        : (tx.feature?.isNotEmpty == true ? tx.feature! : tx.type);

    return Container(
      padding: EdgeInsets.all(AppDs.space3.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
      ),
      child: Row(
        children: [
          Icon(
            credit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: amountColor,
            size: 22.adaptSize,
          ),
          SizedBox(width: AppDs.space3.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  variant: AppTextVariant.secondary,
                  color: Colors.white,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tx.createdAt != null && tx.createdAt!.isNotEmpty)
                  AppText(
                    tx.createdAt!,
                    variant: AppTextVariant.caption,
                    color: AppDs.textOnDarkSecondary,
                  ),
              ],
            ),
          ),
          AppText(
            '${credit ? '+' : ''}${tx.amount}',
            variant: AppTextVariant.title,
            color: amountColor,
          ),
        ],
      ),
    );
  }
}
