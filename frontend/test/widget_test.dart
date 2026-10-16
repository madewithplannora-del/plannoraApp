import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planera/features/common/widgets/custom_button.dart';
import 'package:planera/features/common/widgets/empty_view.dart';
import 'package:planera/features/common/widgets/status_badge.dart';

void main() {
  group('Common Widgets Tests', () {
    testWidgets('CustomButton displays text and triggers onPressed', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
      await tester.tap(find.text('Click Me'));
      expect(pressed, true);
    });

    testWidgets('CustomButton shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Submit',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('StatusBadge displays correct label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(label: 'Professional'),
          ),
        ),
      );

      expect(find.text('Professional'), findsOneWidget);
    });

    testWidgets('EmptyView displays title, message and button', (tester) async {
      bool buttonClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyView(
              icon: Icons.inbox,
              title: 'No Data Found',
              message: 'Please try again later',
              buttonText: 'Retry',
              onButtonPressed: () => buttonClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('No Data Found'), findsOneWidget);
      expect(find.text('Please try again later'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(buttonClicked, true);
    });
  });
}
