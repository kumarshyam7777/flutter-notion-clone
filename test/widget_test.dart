import 'package:flutter_test/flutter_test.dart';

import 'package:notion_clone/main.dart';

void main() {
  testWidgets('app builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NotionCloneApp());

    expect(find.byType(NotionCloneApp), findsOneWidget);
  });
}
