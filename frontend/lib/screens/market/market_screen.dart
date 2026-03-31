import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hk_stock_app/constants/index.dart';
import 'package:hk_stock_app/providers/market_providers.dart';
import 'package:hk_stock_app/widgets/index.dart';

/// Market Screen - displays market indices, movers, sectors
class MarketScreen extends ConsumerWidget {
  const MarketScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Market'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Gainers'),
              Tab(text: 'Losers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Overview (Indices)
            _buildOverviewTab(context, ref),
            
            // Tab 2: Gainers
            _buildGainersTab(context, ref),
            
            // Tab 3: Losers
            _buildLosersTab(context, ref),
          ],
        ),
      ),
    );
  }
  
  /// Build Overview tab - shows market indices and movers
  Widget _buildOverviewTab(BuildContext context, WidgetRef ref) {
    final indicesAsync = ref.watch(marketIndicesProvider);
    final moversAsync = ref.watch(marketMoversProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(marketIndicesProvider);
        ref.refresh(marketMoversProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indices section
              Text(
                'Market Indices',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSizes.paddingM),
              
              // Indices grid or loading
              indicesAsync.when(
                data: (indices) => GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSizes.paddingM,
                  mainAxisSpacing: AppSizes.paddingM,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: indices
                      .map((index) => IndexCard(index: index))
                      .toList(),
                ),
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Center(
                  child: Text('Error loading indices: $error'),
                ),
              ),
              
              const SizedBox(height: AppSizes.paddingL),
              
              // Most Active section
              Text(
                'Most Active',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSizes.paddingM),
              
              // Most active stocks
              moversAsync.when(
                data: (movers) => Column(
                  children: movers.turnover
                      .take(5)
                      .map((mover) => StockRow(
                            mover: mover,
                            showVolume: true,
                          ))
                      .toList(),
                ),
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Center(
                  child: Text('Error loading movers: $error'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build Gainers tab
  Widget _buildGainersTab(BuildContext context, WidgetRef ref) {
    final moversAsync = ref.watch(marketMoversProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(marketMoversProvider);
      },
      child: moversAsync.when(
        data: (movers) => ListView.builder(
          itemCount: movers.gainers.length,
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) => StockRow(
            mover: movers.gainers[index],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading gainers: $error'),
        ),
      ),
    );
  }
  
  /// Build Losers tab
  Widget _buildLosersTab(BuildContext context, WidgetRef ref) {
    final moversAsync = ref.watch(marketMoversProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(marketMoversProvider);
      },
      child: moversAsync.when(
        data: (movers) => ListView.builder(
          itemCount: movers.losers.length,
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) => StockRow(
            mover: movers.losers[index],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading losers: $error'),
        ),
      ),
    );
  }
}
