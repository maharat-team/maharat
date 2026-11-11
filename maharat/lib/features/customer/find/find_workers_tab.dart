import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/geo.dart';
import '../../../core/widgets/contact_dialog.dart';
import '../../../core/widgets/contractor_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/worker_card.dart';
import '../../../models/contractor_model.dart';
import '../../../models/worker_model.dart';
import '../../../state/app_state.dart';
import '../contractor_profile/contractor_profile_screen.dart';
import '../worker_profile/worker_profile_screen.dart';

enum _SortBy { rating, nearest, experience, visitFee }

class FindWorkersTab extends StatefulWidget {
  const FindWorkersTab({super.key});

  @override
  State<FindWorkersTab> createState() => _FindWorkersTabState();
}

class _FindWorkersTabState extends State<FindWorkersTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _showContractors = false;
  String _selectedCategory = 'All';
  String _selectedNeighbourhood = 'All';
  bool _availableTodayOnly = false;
  _SortBy _sortBy = _SortBy.rating;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _sortLabel(_SortBy sort) => switch (sort) {
    _SortBy.rating => context.tr('Rating', 'ریٹنگ'),
    _SortBy.nearest => context.tr('Nearest', 'قریب ترین'),
    _SortBy.experience => context.tr('Experience', 'تجربہ'),
    _SortBy.visitFee => context.tr('Visit fee', 'وزٹ فیس'),
  };

  bool _matchesQuery(List<String> fields) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return fields.any((f) => f.toLowerCase().contains(query));
  }

  List<WorkerModel> _filteredWorkers(AppState appState) {
    final here = appState.myLocation;
    final list = appState.workers.where((worker) {
      if (_selectedCategory != 'All' && worker.trade != _selectedCategory) {
        return false;
      }
      if (!_matchesQuery([
        worker.name,
        worker.trade,
        Labels.trades[worker.trade] ?? '',
        worker.neighbourhood,
        Labels.areas[worker.neighbourhood] ?? '',
      ])) {
        return false;
      }
      if (_selectedNeighbourhood != 'All' &&
          !worker.serviceAreas.contains(_selectedNeighbourhood)) {
        return false;
      }
      if (_availableTodayOnly && !worker.isAvailableToday) return false;
      return true;
    }).toList();

    switch (_sortBy) {
      case _SortBy.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _SortBy.experience:
        list.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
      case _SortBy.visitFee:
        list.sort((a, b) => a.visitFee.compareTo(b.visitFee));
      case _SortBy.nearest:
        double key(WorkerModel w) =>
            distanceBetween(here, w.baseLocation) ?? double.infinity;
        list.sort((a, b) => key(a).compareTo(key(b)));
    }
    return list;
  }

  List<ContractorModel> _filteredContractors(AppState appState) {
    final here = appState.myLocation;
    final list = appState.contractors.where((shop) {
      if (_selectedCategory != 'All' &&
          !shop.trades.contains(_selectedCategory)) {
        return false;
      }
      if (!_matchesQuery([
        shop.businessName,
        shop.ownerName,
        ...shop.trades,
        ...shop.trades.map((t) => Labels.trades[t] ?? ''),
        shop.neighbourhood,
      ])) {
        return false;
      }
      if (_selectedNeighbourhood != 'All' &&
          !shop.serviceAreas.contains(_selectedNeighbourhood)) {
        return false;
      }
      return true;
    }).toList();

    if (_sortBy == _SortBy.nearest) {
      double key(ContractorModel c) =>
          distanceBetween(here, c.location) ?? double.infinity;
      list.sort((a, b) => key(a).compareTo(key(b)));
    } else {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  void _reset() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'All';
      _selectedNeighbourhood = 'All';
      _availableTodayOnly = false;
      _sortBy = _SortBy.rating;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final here = appState.myLocation;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('Find Help', 'تلاش کریں')),
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        icon: const Icon(Icons.engineering_rounded, size: 18),
                        label: Text(context.tr('Workers', 'کاریگر')),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: const Icon(Icons.storefront_rounded, size: 18),
                        label: Text(context.tr('Shops', 'دکانیں')),
                      ),
                    ],
                    selected: {_showContractors},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) =>
                        setState(() => _showContractors = value.first),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: _showContractors
                        ? context.tr(
                            'Search shop name, trade...',
                            'دکان کا نام، کام تلاش کریں...',
                          )
                        : context.tr(
                            'Search plumber, electrician, name...',
                            'پلمبر، الیکٹریشن، نام تلاش کریں...',
                          ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.secondaryText,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('All'),
                      ...AppConstants.categories.map(
                        (c) => _buildCategoryChip(c.nameEn),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final areaWidth = constraints.maxWidth < 220
                        ? constraints.maxWidth
                        : 220.0;
                    final sortWidth = constraints.maxWidth < 180
                        ? constraints.maxWidth
                        : 180.0;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: areaWidth,
                          child: _buildFilterDropdown<String>(
                            value: _selectedNeighbourhood,
                            options: [
                              'All',
                              ...AppConstants.bahawalpurNeighbourhoods,
                            ],
                            labelBuilder: (area) => area == 'All'
                                ? context.tr('All areas', 'تمام علاقے')
                                : context.areaName(area),
                            onChanged: (value) =>
                                setState(() => _selectedNeighbourhood = value),
                          ),
                        ),
                        SizedBox(
                          width: sortWidth,
                          child: _buildFilterDropdown<_SortBy>(
                            value: _sortBy,
                            options: _showContractors
                                ? const [_SortBy.rating, _SortBy.nearest]
                                : _SortBy.values,
                            labelBuilder: (sort) => context.tr(
                              'Sort: ${_sortLabel(sort)}',
                              'ترتیب: ${_sortLabel(sort)}',
                            ),
                            icon: Icons.sort_rounded,
                            onChanged: (value) {
                              if (value == _SortBy.nearest && here == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.tr(
                                        'Add your home location in Profile to sort by distance.',
                                        'فاصلے کے لحاظ سے ترتیب کے لیے پروفائل میں گھر کا مقام شامل کریں۔',
                                      ),
                                    ),
                                  ),
                                );
                              }
                              setState(() => _sortBy = value);
                            },
                          ),
                        ),
                        if (!_showContractors)
                          FilterChip(
                            selected: _availableTodayOnly,
                            label: Text(
                              context.tr('Available today', 'آج دستیاب'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selectedColor: AppColors.lightMint,
                            checkmarkColor: AppColors.primary,
                            onSelected: (value) =>
                                setState(() => _availableTodayOnly = value),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: _availableTodayOnly
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _showContractors
                ? _buildContractorList(appState)
                : _buildWorkerList(appState),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerList(AppState appState) {
    if (appState.workers.isEmpty) {
      return _buildNoDataState(
        status: appState.workersStatus,
        error: appState.workersError,
        onRetry: appState.refreshWorkers,
        emptyTitle: context.tr(
          'No verified workers yet',
          'ابھی کوئی تصدیق شدہ کاریگر نہیں',
        ),
      );
    }
    final workers = _filteredWorkers(appState);
    if (workers.isEmpty) return _buildEmptyState();
    final here = appState.myLocation;
    return RefreshIndicator(
      onRefresh: appState.refreshWorkers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: workers.length,
        itemBuilder: (context, index) {
          final worker = workers[index];
          return WorkerCard(
            worker: worker,
            distanceKm: distanceBetween(here, worker.baseLocation),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WorkerProfileScreen(worker: worker),
              ),
            ),
            onWhatsAppTap: () => showContactDialog(
              context,
              name: worker.name,
              subtitle: context.tradeName(worker.trade),
              phone: worker.phone,
              isWhatsApp: true,
            ),
            onCallTap: () => showContactDialog(
              context,
              name: worker.name,
              subtitle: context.tradeName(worker.trade),
              phone: worker.phone,
              isWhatsApp: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildContractorList(AppState appState) {
    if (appState.contractors.isEmpty) {
      return _buildNoDataState(
        status: appState.contractorsStatus,
        error: appState.contractorsError,
        onRetry: appState.refreshContractors,
        emptyTitle: context.tr(
          'No verified shops yet',
          'ابھی کوئی تصدیق شدہ دکان نہیں',
        ),
      );
    }
    final shops = _filteredContractors(appState);
    if (shops.isEmpty) return _buildEmptyState();
    final here = appState.myLocation;
    return RefreshIndicator(
      onRefresh: appState.refreshContractors,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: shops.length,
        itemBuilder: (context, index) {
          final shop = shops[index];
          return ContractorCard(
            contractor: shop,
            distanceKm: distanceBetween(here, shop.location),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ContractorProfileScreen(contractor: shop),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoDataState({
    required LoadStatus status,
    required String? error,
    required Future<void> Function() onRetry,
    required String emptyTitle,
  }) {
    switch (status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorRetryView(
          message:
              error ?? context.tr('Could not load.', 'لوڈ نہیں ہو سکا۔'),
          onRetry: onRetry,
        );
      case LoadStatus.ready:
        return EmptyStateView(
          icon: Icons.engineering_outlined,
          title: emptyTitle,
          subtitle: context.tr(
            'They will appear here as they join and get verified.',
            'شامل ہونے اور تصدیق کے بعد یہاں نظر آئیں گے۔',
          ),
        );
    }
  }

  Widget _buildCategoryChip(String value) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: ChoiceChip(
        label: Text(
          value == 'All' ? context.tr('All', 'سب') : context.tradeName(value),
        ),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.white,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.white : AppColors.primaryText,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        onSelected: (selected) {
          if (selected) setState(() => _selectedCategory = value);
        },
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required List<T> options,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onChanged,
    IconData? icon,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: options.contains(value) ? value : options.first,
          isExpanded: true,
          icon: Icon(
            icon ?? Icons.arrow_drop_down_rounded,
            size: icon == null ? 24 : 16,
            color: AppColors.secondaryText,
          ),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<T>(
                  value: option,
                  child: Text(
                    labelBuilder(option),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.secondaryText.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('Nothing found', 'کچھ نہیں ملا'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                'Try a different search or area.',
                'کوئی اور تلاش یا علاقہ آزمائیں۔',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(140, 40),
              ),
              onPressed: _reset,
              child: Text(context.tr('Reset filters', 'فلٹر ری سیٹ کریں')),
            ),
          ],
        ),
      ),
    );
  }
}
