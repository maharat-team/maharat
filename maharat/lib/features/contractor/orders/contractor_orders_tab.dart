import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/request_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/job_request_model.dart';
import '../../../state/app_state.dart';
import 'contractor_order_screen.dart';

/// Orders customers sent to the shop: new, in progress, and finished.
class ContractorOrdersTab extends StatelessWidget {
  const ContractorOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final orders = appState.contractorOrders;
    final newOrders = orders
        .where((o) => o.isActive && o.orderStatus == OrderStatus.pending)
        .toList();
    final inProgress = orders
        .where((o) => o.isActive && o.orderStatus == OrderStatus.accepted)
        .toList();
    final done = orders.where((o) => !o.isActive).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(context.tr('Orders', 'آرڈرز')),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.secondaryText,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: context.tr('New (${newOrders.length})', 'نئے (${newOrders.length})')),
              Tab(
                text: context.tr(
                  'In progress (${inProgress.length})',
                  'جاری (${inProgress.length})',
                ),
              ),
              Tab(text: context.tr('Done', 'مکمل')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrderList(
              orders: newOrders,
              empty: context.tr(
                'No new orders. Customers find your shop under Find → Shops.',
                'کوئی نیا آرڈر نہیں۔ گاہک آپ کی دکان تلاش → دکانیں میں دیکھتے ہیں۔',
              ),
            ),
            _OrderList(
              orders: inProgress,
              empty: context.tr('Nothing in progress.', 'کوئی کام جاری نہیں۔'),
            ),
            _OrderList(
              orders: done,
              empty: context.tr('No finished orders yet.', 'ابھی کوئی آرڈر مکمل نہیں۔'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<JobRequestModel> orders;
  final String empty;

  const _OrderList({required this.orders, required this.empty});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    if (orders.isEmpty) {
      if (appState.jobsStatus == LoadStatus.error) {
        return ErrorRetryView(
          message: appState.jobsError ?? '',
          onRetry: appState.refreshJobs,
        );
      }
      return RefreshIndicator(
        onRefresh: appState.refreshJobs,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            EmptyStateView(icon: Icons.receipt_long_outlined, title: empty),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: appState.refreshJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final (statusText, statusColor) = orderStatusText(context, order);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ContractorOrderScreen(orderId: order.id),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${context.tradeName(order.tradeCategory)} · ${context.urgencyName(order.urgency)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          relativeDate(order.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${order.customerName} · ${context.areaName(order.location)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
