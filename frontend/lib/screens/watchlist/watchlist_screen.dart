import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hk_stock_app/constants/index.dart';
import 'package:hk_stock_app/models/index.dart';
import 'package:hk_stock_app/providers/watchlist_providers.dart';

/// Watchlist Screen - Display user's watched stocks with real API data
class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(watchlistFilterProvider);
    final filteredAsync = ref.watch(filteredWatchlistProvider);
    final allAsync = ref.watch(watchlistProvider);
    final statsAsync = ref.watch(watchlistStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Watchlist'),
        elevation: 0,
        backgroundColor: AppColors.darkBg,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(watchlistProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(watchlistProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Summary Card
            SliverToBoxAdapter(
              child: statsAsync.when(
                data: (stats) => _SummaryCard(stats: stats),
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Filter Chips
            SliverToBoxAdapter(
              child: _FilterBar(currentFilter: filter),
            ),

            // Watchlist items
            filteredAsync.when(
              data: (items) => items.isEmpty
                  ? SliverToBoxAdapter(
                      child: _EmptyState(
                        hasAll: allAsync.valueOrNull?.isNotEmpty == true,
                        filter: filter,
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _WatchlistTile(
                          item: items[i],
                          onRemove: () async {
                            try {
                              await ref
                                  .read(removeFromWatchlistProvider(items[i].ticker).future);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${items[i].name} removed from watchlist'),
                                    backgroundColor: AppColors.cardBg,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        childCount: items.length,
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: _ErrorCard(message: 'Failed to load watchlist: $err'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddModal(context, ref),
        backgroundColor: AppColors.accentBlue,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AddWatchlistModal(),
    );
  }
}

// ─────────────────────────────────────────────
// Summary Card
// ─────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _SummaryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats['total'] as int;
    final gainers = stats['gainers'] as int;
    final losers = stats['losers'] as int;
    final avgChangePct = (stats['avgChangePct'] as double?) ?? 0.0;
    final isPositive = avgChangePct >= 0;

    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Watchlist',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                '$total stocks',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              _StatBadge(
                label: 'UP',
                value: '$gainers',
                color: AppColors.upColor,
              ),
              const SizedBox(width: 8),
              _StatBadge(
                label: 'DOWN',
                value: '$losers',
                color: AppColors.downColor,
              ),
              const SizedBox(width: 8),
              _StatBadge(
                label: 'Avg',
                value:
                    '${isPositive ? '+' : ''}${avgChangePct.toStringAsFixed(2)}%',
                color: isPositive ? AppColors.upColor : AppColors.downColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Filter Bar
// ─────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  final String currentFilter;
  const _FilterBar({required this.currentFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = [
      ('all', 'All'),
      ('gainers', 'Gainers ↑'),
      ('losers', 'Losers ↓'),
      ('alerts', 'Alerts 🔔'),
    ];

    return Container(
      color: AppColors.darkBg,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: filters
              .map((f) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _FilterChip(
                      label: f.$2,
                      isActive: currentFilter == f.$1,
                      onTap: () => ref
                          .read(watchlistFilterProvider.notifier)
                          .state = f.$1,
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentBlue : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.accentBlue : AppColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Watchlist Tile
// ─────────────────────────────────────────────
class _WatchlistTile extends StatelessWidget {
  final WatchlistItem item;
  final VoidCallback onRemove;

  const _WatchlistTile({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isGainer = item.changePct >= 0;
    final color = isGainer ? AppColors.upColor : AppColors.downColor;
    final sign = isGainer ? '+' : '';
    final hasAlert = item.alertPrice != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          // Stock info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (hasAlert) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('🔔',
                            style: TextStyle(fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                Text(
                  item.ticker,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (hasAlert)
                  Text(
                    'Alert: HK\$${item.alertPrice!.toStringAsFixed(2)} '
                    '(${item.alertType ?? ''})',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.orange),
                  ),
              ],
            ),
          ),

          // Price & change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'HK\$${item.price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '$sign${item.changePct.toStringAsFixed(2)}%',
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                '$sign${item.change.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 11, color: color),
              ),
            ],
          ),

          // Remove button
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onRemove,
            color: Colors.grey,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add Watchlist Modal
// ─────────────────────────────────────────────
class _AddWatchlistModal extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddWatchlistModal> createState() =>
      _AddWatchlistModalState();
}

class _AddWatchlistModalState extends ConsumerState<_AddWatchlistModal> {
  final _controller = TextEditingController();
  bool _isAdding = false;
  String? _error;

  // Quick-add suggestions
  static const _suggestions = [
    ('0700', 'Tencent'),
    ('9988', 'Alibaba'),
    ('3690', 'Meituan'),
    ('1810', 'Xiaomi'),
    ('0005', 'HSBC'),
    ('2318', 'Ping An'),
    ('0941', 'China Mobile'),
    ('1299', 'AIA'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addTicker(String ticker) async {
    if (ticker.isEmpty) return;
    setState(() {
      _isAdding = true;
      _error = null;
    });
    try {
      await ref.read(addToWatchlistProvider(ticker.trim()).future);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$ticker added to watchlist'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAdding = false;
        _error = 'Failed to add $ticker: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text('Add to Watchlist',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Search input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Stock code (e.g. 0700)',
                    filled: true,
                    fillColor: AppColors.darkBg,
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.borderColor),
                    ),
                  ),
                  onSubmitted: _addTicker,
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    _isAdding ? null : () => _addTicker(_controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isAdding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Add',
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],

          const SizedBox(height: 16),
          const Text('Quick Add',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),

          // Quick add chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map((s) => ActionChip(
                      label: Text(
                        '${s.$1} ${s.$2}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: _isAdding ? null : () => _addTicker(s.$1),
                      backgroundColor: AppColors.darkBg,
                      side: const BorderSide(color: AppColors.borderColor),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasAll;
  final String filter;
  const _EmptyState({required this.hasAll, required this.filter});

  @override
  Widget build(BuildContext context) {
    final message = !hasAll
        ? 'Your watchlist is empty.\nTap + to add stocks.'
        : 'No stocks match "$filter" filter.';

    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border,
                size: 64, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
