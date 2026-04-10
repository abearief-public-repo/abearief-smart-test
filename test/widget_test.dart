import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_test/main.dart';
import 'package:smart_test/utils/calculator.dart';
import 'package:smart_test/utils/digits_only_formatter.dart';

void main() {
  // ==========================================================================
  // Unit Tests: reverseNumber
  // ==========================================================================
  group('reverseNumber', () {
    test('reverses 21 to 12', () {
      expect(reverseNumber(21), 12);
    });

    test('reverses 30 to 3 (not 03)', () {
      expect(reverseNumber(30), 3);
    });

    test('reverses 12 to 21', () {
      expect(reverseNumber(12), 21);
    });

    test('reverses single digit to itself', () {
      expect(reverseNumber(5), 5);
    });

    test('reverses 100 to 1', () {
      expect(reverseNumber(100), 1);
    });

    test('reverses 0 to 0', () {
      expect(reverseNumber(0), 0);
    });

    test('reverses palindrome 121 to 121', () {
      expect(reverseNumber(121), 121);
    });

    test('reverses large number 123456789 to 987654321', () {
      expect(reverseNumber(123456789), 987654321);
    });

    test('reverses 1000 to 1 (multiple trailing zeros)', () {
      expect(reverseNumber(1000), 1);
    });
  });

  // ==========================================================================
  // Unit Tests: calculateDifference
  // ==========================================================================
  group('calculateDifference', () {
    test('21 and 12 gives 9', () {
      expect(calculateDifference(21, 12), 9);
    });

    test('30 and 3 gives 27', () {
      expect(calculateDifference(30, 3), 27);
    });

    test('12 and 21 gives 9', () {
      expect(calculateDifference(12, 21), 9);
    });

    test('same number gives 0', () {
      expect(calculateDifference(11, 11), 0);
    });

    test('palindrome gives 0', () {
      expect(calculateDifference(121, 121), 0);
    });

    test('single digit same gives 0', () {
      expect(calculateDifference(5, 5), 0);
    });
  });

  // ==========================================================================
  // Unit Tests: DigitsOnlyFormatter
  // ==========================================================================
  group('DigitsOnlyFormatter', () {
    final formatter = DigitsOnlyFormatter();

    /// Helper: simulasi user mengetik [newText] dari state kosong.
    TextEditingValue apply(String newText) {
      return formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        ),
      );
    }

    test('keeps digits unchanged', () {
      expect(apply('12345').text, '12345');
    });

    test('strips decimal point (1.2 becomes 12)', () {
      expect(apply('1.2').text, '12');
    });

    test('strips comma (1,2 becomes 12)', () {
      expect(apply('1,2').text, '12');
    });

    test('strips letters mixed with digits (abc123 becomes 123)', () {
      expect(apply('abc123').text, '123');
    });

    test('strips all letters (abc becomes empty)', () {
      expect(apply('abc').text, '');
    });

    test('handles empty string', () {
      expect(apply('').text, '');
    });

    test('strips spaces and symbols', () {
      expect(apply('1 2 3!@#').text, '123');
    });

    test('strips negative sign', () {
      expect(apply('-42').text, '42');
    });

    test('cursor is at end after filtering', () {
      final result = apply('1.2.3');
      expect(result.text, '123');
      expect(result.selection.baseOffset, 3);
    });
  });

  // ==========================================================================
  // Widget Tests: SmartTestApp
  // ==========================================================================
  group('SmartTestApp widget', () {
    testWidgets('renders input field and submit button', (tester) async {
      await tester.pumpWidget(const SmartTestApp());

      expect(find.text('Smart Test'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows result after submit with value 21', (tester) async {
      await tester.pumpWidget(const SmartTestApp());

      await tester.enterText(find.byType(TextField), '21');
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('21'), findsWidgets);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
    });

    testWidgets('shows result after submit with value 30', (tester) async {
      await tester.pumpWidget(const SmartTestApp());

      await tester.enterText(find.byType(TextField), '30');
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('30'), findsWidgets);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('27'), findsOneWidget);
    });

    testWidgets('shows error on empty submit', (tester) async {
      await tester.pumpWidget(const SmartTestApp());

      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Masukkan angka terlebih dahulu'), findsOneWidget);
    });

    testWidgets('shows error when input exceeds 18 digits', (tester) async {
      await tester.pumpWidget(const SmartTestApp());

      // 19 digit — melebihi batas aman int64
      await tester.enterText(find.byType(TextField), '1234567890123456789');
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Maksimal 18 digit'), findsOneWidget);
    });

    testWidgets('result updates on second submit', (tester) async {
      await tester.pumpWidget(const SmartTestApp());

      // Submit pertama: 21
      await tester.enterText(find.byType(TextField), '21');
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(find.text('9'), findsOneWidget);

      // Submit kedua: 30 — hasil harus update, bukan menumpuk
      await tester.enterText(find.byType(TextField), '30');
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(find.text('27'), findsOneWidget);
      expect(find.text('9'), findsNothing);
    });
  });
}
