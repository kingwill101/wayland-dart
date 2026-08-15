import 'package:test/test.dart';
import 'package:bardash/src/native/hyprland_ipc.dart';

void main() {
  test('accepts successful Hyprland dispatch responses', () {
    expect(hyprctlResultSucceeded('ok\n'), isTrue);
    expect(hyprctlResultSucceeded('dispatched'), isTrue);
    expect(hyprctlResultSucceeded(0), isTrue);
  });

  test('rejects failed Hyprland dispatch responses', () {
    expect(hyprctlResultSucceeded(null), isFalse);
    expect(hyprctlResultSucceeded('Invalid dispatcher'), isFalse);
    expect(hyprctlResultSucceeded('error: unknown workspace'), isFalse);
    expect(hyprctlResultSucceeded(''), isFalse);
  });
}
