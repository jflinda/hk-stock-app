import 'package:flutter/material.dart';
import 'package:hk_stock_app/constants/index.dart';
import 'package:hk_stock_app/models/index.dart';

/// Stock Row Widget - displays a single stock in a list/table format
class StockRow extends StatelessWidget {
  final Mover mover;
  final VoidCallback? onTap;
  final bool showVolume;
  
  const StockRow({
    super.key,
    required this.mover,
    this.onTap,
    this.showVolume = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final color = mover.isUp ? AppColors.upColor : AppColors.downColor;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: AppSizes.paddingS,
          ),
          child: Row(
            children: [
              // Ticker and name
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mover.ticker,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (mover.name != null)
                      Text(
                        mover.name!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Price
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${mover.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (showVolume)
                      Text(
                        mover.displayVolume,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(width: AppSizes.paddingS),
              
              // Change percentage
              SizedBox(
                width: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          mover.isUp ? '▲' : '▼',
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingXs),
                        Text(
                          '${mover.pct.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
