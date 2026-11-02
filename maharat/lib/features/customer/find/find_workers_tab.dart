import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/worker_card.dart';
import '../../../state/app_state.dart';
import '../worker_profile/worker_profile_screen.dart';

class FindWorkersTab extends StatefulWidget {
  const FindWorkersTab({super.key});

  @override
  State<FindWorkersTab> createState() => _FindWorkersTabState();
}

class _FindWorkersTabState extends State<FindWorkersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedNeighbourhood = 'All';
  double _minRating = 0.0;
  bool _availableTodayOnly = false;
  String _sortBy = 'Rating'; // 'Rating', 'Experience', 'Visit Fee'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final allWorkers = appState.workers;

    // Filtering logic
    List filteredWorkers = allWorkers.where((worker) {
      // Category filter
      if (_selectedCategory != 'All' &&
          worker.trade.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }
      // Search query
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchesName = worker.name.toLowerCase().contains(query);
        final matchesTrade = worker.trade.toLowerCase().contains(query);
        final matchesArea = worker.neighbourhood.toLowerCase().contains(query);
        if (!matchesName && !matchesTrade && !matchesArea) return false;
      }
      // Neighbourhood filter
      if (_selectedNeighbourhood != 'All' &&
          worker.neighbourhood != _selectedNeighbourhood) {
        return false;
      }
      // Rating filter
      if (worker.rating < _minRating) return false;
      // Availability filter
      if (_availableTodayOnly && !worker.isAvailableToday) return false;

      return true;
    }).toList();

    // Sorting logic
    if (_sortBy == 'Rating') {
      filteredWorkers.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'Experience') {
      filteredWorkers.sort(
        (a, b) => b.experienceYears.compareTo(a.experienceYears),
      );
    } else if (_sortBy == 'Visit Fee') {
      filteredWorkers.sort((a, b) => a.visitFee.compareTo(b.visitFee));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find Local Workers'),
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filters Header Container
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search plumber, electrician, name...',
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
                const SizedBox(height: 12),

                // Category Horizontal Chips
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
                const SizedBox(height: 10),

                // Secondary Filter Controls Row
                Row(
                  children: [
                    // Area Filter Dropdown
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedNeighbourhood,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.arrow_drop_down_rounded,
                              color: AppColors.secondaryText,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                            items:
                                [
                                  'All',
                                  ...AppConstants.bahawalpurNeighbourhoods,
                                ].map((area) {
                                  return DropdownMenuItem<String>(
                                    value: area,
                                    child: Text(
                                      area == 'All' ? 'All Areas' : area,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedNeighbourhood = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Sort By Dropdown
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          icon: const Icon(
                            Icons.sort_rounded,
                            size: 16,
                            color: AppColors.secondaryText,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                          items: ['Rating', 'Experience', 'Visit Fee'].map((s) {
                            return DropdownMenuItem<String>(
                              value: s,
                              child: Text('Sort: $s'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _sortBy = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Available Today Chip Toggle
                    FilterChip(
                      selected: _availableTodayOnly,
                      label: const Text(
                        'Available Today',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selectedColor: AppColors.lightMint,
                      checkmarkColor: AppColors.primary,
                      onSelected: (val) =>
                          setState(() => _availableTodayOnly = val),
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
                ),
              ],
            ),
          ),

          // Worker Results List
          Expanded(
            child: filteredWorkers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredWorkers.length,
                    itemBuilder: (context, index) {
                      final worker = filteredWorkers[index];
                      return WorkerCard(
                        worker: worker,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  WorkerProfileScreen(worker: worker),
                            ),
                          );
                        },
                        onWhatsAppTap: () =>
                            _openContactDialog(context, worker, true),
                        onCallTap: () =>
                            _openContactDialog(context, worker, false),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.white,
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
          if (selected) {
            setState(() {
              _selectedCategory = label;
            });
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.secondaryText.withAlpha(120),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Workers Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your search criteria or area filter.',
            style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(140, 40),
            ),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedCategory = 'All';
                _selectedNeighbourhood = 'All';
                _availableTodayOnly = false;
                _minRating = 0.0;
              });
            },
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  void _openContactDialog(BuildContext context, worker, bool isWhatsApp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isWhatsApp ? Icons.chat_bubble_rounded : Icons.call_rounded,
              color: isWhatsApp ? AppColors.whatsappGreen : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(isWhatsApp ? 'WhatsApp Contact' : 'Direct Call'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect directly with ${worker.name} (${worker.trade})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Phone: ${worker.phone}',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightMint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Maharat charges 0% commission. Contact worker directly!',
                style: TextStyle(fontSize: 12, color: AppColors.darkGreen),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isWhatsApp
                  ? AppColors.whatsappGreen
                  : AppColors.primary,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isWhatsApp
                        ? 'Opening WhatsApp chat with ${worker.name}...'
                        : 'Calling ${worker.name} at ${worker.phone}...',
                  ),
                ),
              );
            },
            child: Text(isWhatsApp ? 'Open WhatsApp' : 'Call Now'),
          ),
        ],
      ),
    );
  }
}
