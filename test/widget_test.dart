import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/main.dart';

void main() {
  testWidgets('shows the task manager home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('Feyisa'), findsOneWidget);
    expect(find.text("Today's Tasks"), findsOneWidget);
  });
}
