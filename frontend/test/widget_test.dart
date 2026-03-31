// Basic smoke test for HK Stock App

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hk_stock_app/main.dart';

void main() {
  testWidgets('App smoke test - loads without crash', (WidgetTester tester) async {
    // Build app with ProviderScope
    await tester.pumpWidget(
      const ProviderScope(child: HKStockApp()),
    );
    
    // Verify bottom navigation bar exists
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
