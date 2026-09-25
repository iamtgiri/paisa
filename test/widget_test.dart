import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paisa/main.dart';

void main() {
  testWidgets('PaisaApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PaisaApp()));
    expect(find.byType(PaisaApp), findsOneWidget);
  });
}
