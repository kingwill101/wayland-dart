class ModifierKeys {
  static const int shift = 1 << 0; // Bit 0
  static const int capsLock = 1 << 1; // Bit 1
  static const int control = 1 << 2; // Bit 2
  static const int alt = 1 << 3; // Bit 3
  static const int numLock = 1 << 4; // Bit 4
  static const int superKey = 1 << 5; // Bit 5
}

class ModifierState {
  int modsDepressed;
  int modsLatched;
  int modsLocked;
  int group;

  ModifierState({
    required this.modsDepressed,
    required this.modsLatched,
    required this.modsLocked,
    required this.group,
  });
  bool get shiftPressed => (modsDepressed & ModifierKeys.shift) != 0;
  bool get capsLockPressed => (modsDepressed & ModifierKeys.capsLock) != 0;
  bool get controlPressed => (modsDepressed & ModifierKeys.control) != 0;
  bool get altPressed => (modsDepressed & ModifierKeys.alt) != 0;
  bool get numLockPressed => (modsDepressed & ModifierKeys.numLock) != 0;
  bool get superKeyPressed => (modsDepressed & ModifierKeys.superKey) != 0;

  bool get capsLockActivated => (modsLocked & ModifierKeys.capsLock) != 0;
  bool get numLockActivated => (modsLocked & ModifierKeys.numLock) != 0;

  @override
  String toString() {
    return """ModifierState(capsLockActivated: $capsLockActivated numLockActivated: $numLockActivated shiftPressed:$shiftPressed capsLockPressed: $capsLockPressed controlPressed: $controlPressed altPressed: $altPressed numLockPressed: $numLockPressed superKeyPressed: $superKeyPressed""";
  }
}
