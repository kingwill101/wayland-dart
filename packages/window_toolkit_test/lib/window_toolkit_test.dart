/// Testing utilities for window_toolkit applications.
///
/// Provides:
/// - [TestHarness] — pump-driven widget testing (like Flutter's WidgetTester)
/// - [TestBackend] — compositor-less backend for offline testing
/// - [WidgetFinder] — locate widgets by type, text, etc.
///
/// ## Usage
///
/// ```dart
/// import 'package:test/test.dart';
/// import 'package:window_toolkit_test/window_toolkit_test.dart';
///
/// void main() {
///   test('button renders with correct text', () async {
///     final harness = TestHarness();
///     harness.pumpWidget(Button('OK', onPressed: () {}));
///     await harness.pump();
///
///     final btn = harness.find.byType<Button>();
///     expect(btn, isNotNull);
///     expect(btn!.text, 'OK');
///   });
/// }
/// ```
library window_toolkit_test;

export 'src/harness.dart';
export 'src/test_backend.dart';
