import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:planera/features/auth/login_screen.dart';
import 'package:planera/providers/auth_provider.dart';
import 'package:planera/providers/customer_provider.dart';
import 'package:planera/providers/freelancer_provider.dart';

void main() {
  Widget createLoginTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => FreelancerProvider()),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  testWidgets('LoginScreen renders branding, input fields, and action buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(createLoginTestWidget());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email or Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('LoginScreen shows validation errors when submitted empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(createLoginTestWidget());

    // Tap "Sign In" with empty fields
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Please enter your email or username'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });
}
