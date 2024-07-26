enum InputProperty {
  pointer(0x00),
  direct(0x01),
  buttonpad(0x02),
  semiMT(0x03),
  topButtonpad(0x04),
  pointingStick(0x05),
  accelerometer(0x06),
  propMax(0x1f),
  propCnt(0x20); // propMax + 1

  final int value;
  const InputProperty(this.value);
}

enum EventType {
  syn(0x00),
  key(0x01),
  rel(0x02),
  abs(0x03),
  msc(0x04),
  sw(0x05),
  led(0x11),
  snd(0x12),
  rep(0x14),
  ff(0x15),
  pwr(0x16),
  ffStatus(0x17),
  evMax(0x1f),
  evCnt(0x20); // evMax + 1

  final int value;
  const EventType(this.value);
}

enum SynEvent {
  report(0),
  config(1),
  mtReport(2),
  dropped(3),
  synMax(0xf),
  synCnt(0x10); // synMax + 1

  final int value;
  const SynEvent(this.value);
}

enum Key {
  reserved(0),
  esc(1),
  key1(2),
  key2(3),
  key3(4),
  key4(5),
  key5(6),
  key6(7),
  key7(8),
  key8(9),
  key9(10),
  key0(11),
  minus(12),
  equal(13),
  backspace(14),
  tab(15),
  q(16),
  w(17),
  e(18),
  r(19),
  t(20),
  y(21),
  u(22),
  i(23),
  o(24),
  p(25),
  leftBrace(26),
  rightBrace(27),
  enter(28),
  leftCtrl(29),
  a(30),
  s(31),
  d(32),
  f(33),
  g(34),
  h(35),
  j(36),
  k(37),
  l(38),
  semicolon(39),
  apostrophe(40),
  grave(41),
  leftShift(42),
  backslash(43),
  z(44),
  x(45),
  c(46),
  v(47),
  b(48),
  n(49),
  m(50),
  comma(51),
  dot(52),
  slash(53),
  rightShift(54),
  kpAsterisk(55),
  leftAlt(56),
  space(57),
  capsLock(58),
  f1(59),
  f2(60),
  f3(61),
  f4(62),
  f5(63),
  f6(64),
  f7(65),
  f8(66),
  f9(67),
  f10(68),
  numLock(69),
  scrollLock(70),
  kp7(71),
  kp8(72),
  kp9(73),
  kpMinus(74),
  kp4(75),
  kp5(76),
  kp6(77),
  kpPlus(78),
  kp1(79),
  kp2(80),
  kp3(81),
  kp0(82),
  kpDot(83),
  zenkakuHankaku(85),
  key102nd(86),
  f11(87),
  f12(88),
  ro(89),
  katakana(90),
  hiragana(91),
  henkan(92),
  katakanaHiragana(93),
  muhenkan(94),
  kpJPComma(95),
  kpEnter(96),
  rightCtrl(97),
  kpSlash(98),
  sysRq(99),
  rightAlt(100),
  lineFeed(101),
  home(102),
  up(103),
  pageUp(104),
  left(105),
  right(106),
  end(107),
  down(108),
  pageDown(109),
  insert(110),
  delete(111),
  macro(112),
  mute(113),
  volumeDown(114),
  volumeUp(115),
  power(116), // SC System Power Down
  kpEqual(117),
  kpPlusMinus(118),
  pause(119),
  scale(120), // AL Compiz Scale (Expose)
  kpComma(121),
  hangeul(122),
  hanguel(122),
  hanja(123),
  yen(124),
  leftMeta(125),
  rightMeta(126),
  compose(127),
  stop(128), // AC Stop
  again(129),
  props(130), // AC Properties
  undo(131), // AC Undo
  front(132),
  copy(133), // AC Copy
  open(134), // AC Open
  paste(135), // AC Paste
  find(136), // AC Search
  cut(137), // AC Cut
  help(138), // AL Integrated Help Center
  menu(139), // Menu (show menu)
  calc(140), // AL Calculator
  setup(141),
  sleep(142), // SC System Sleep
  wakeUp(143), // System Wake Up
  file(144), // AL Local Machine Browser
  sendFile(145),
  deleteFile(146),
  xfer(147),
  prog1(148),
  prog2(149),
  www(150), // AL Internet Browser
  msDos(151),
  coffee(152), // AL Terminal Lock/Screensaver
  screenLock(152),
  rotateDisplay(153), // Display orientation for e.g. tablets
  direction(153),
  cycleWindows(154),
  mail(155),
  bookmarks(156), // AC Bookmarks
  computer(157),
  back(158), // AC Back
  forward(159), // AC Forward
  closeCD(160),
  ejectCD(161),
  ejectCloseCD(162),
  nextSong(163),
  playPause(164),
  previousSong(165),
  stopCD(166),
  record(167),
  rewind(168),
  phone(169), // Media Select Telephone
  iso(170),
  config(171), // AL Consumer Control Configuration
  homepage(172), // AC Home
  refresh(173), // AC Refresh
  exit(174), // AC Exit
  move(175),
  edit(176),
  scrollUp(177),
  scrollDown(178),
  kpLeftParen(179),
  kpRightParen(180),
  newKey(181), // AC New
  redo(182), // AC Redo/Repeat
  f13(183),
  f14(184),
  f15(185),
  f16(186),
  f17(187),
  f18(188),
  f19(189),
  f20(190),
  f21(191),
  f22(192),
  f23(193),
  f24(194),
  playCD(200),
  pauseCD(201),
  prog3(202),
  prog4(203),
  allApplications(204), // AC Desktop Show All Applications
  dashboard(204),
  suspend(205),
  close(206), // AC Close
  play(207),
  fastForward(208),
  bassBoost(209),
  print(210), // AC Print
  hp(211),
  camera(212),
  sound(213),
  question(214),
  email(215),
  chat(216),
  search(217),
  connect(218),
  finance(219), // AL Checkbook/Finance
  sport(220),
  shop(221),
  altErase(222),
  cancel(223), // AC Cancel
  brightnessDown(224),
  brightnessUp(225),
  media(226),
  switchVideoMode(227), // Cycle between available video outputs (Monitor/LCD/TV-out/etc)
  kbdIllumToggle(228),
  kbdIllumDown(229),
  kbdIllumUp(230),
  send(231), // AC Send
  reply(232), // AC Reply
  forwardMail(233), // AC Forward Msg
  save(234), // AC Save
  documents(235),
  battery(236),
  bluetooth(237),
  wlan(238),
  uwb(239),
  unknown(240),
  videoNext(241), // drive next video source
  videoPrev(242), // drive previous video source
  brightnessCycle(243), // brightness up, after max is min
  brightnessAuto(244), // Set Auto Brightness: manual brightness control is off, rely on ambient
  brightnessZero(244),
  displayOff(245), // display device to off state
  wwan(246), // Wireless WAN (LTE, UMTS, GSM, etc.)
  wimax(246),
  rfKill(247), // Key that controls all radios
  micMute(248), // Mute / unmute the microphone
  btnMisc(0x100),
  btn0(0x100),
  btn1(0x101),
  btn2(0x102),
  btn3(0x103),
  btn4(0x104),
  btn5(0x105),
  btn6(0x106),
  btn7(0x107),
  btn8(0x108),
  btn9(0x109),
  btnMouse(0x110),
  btnLeft(0x110),
  btnRight(0x111),
  btnMiddle(0x112),
  btnSide(0x113),
  btnExtra(0x114),
  btnForward(0x115),
  btnBack(0x116),
  btnTask(0x117),
  btnJoystick(0x120),
  btnTrigger(0x120),
  btnThumb(0x121),
  btnThumb2(0x122),
  btnTop(0x123),
  btnTop2(0x124),
  btnPinkie(0x125),
  btnBase(0x126),
  btnBase2(0x127),
  btnBase3(0x128),
  btnBase4(0x129),
  btnBase5(0x12a),
  btnBase6(0x12b),
  btnDead(0x12f),
  btnGamepad(0x130),
  btnSouth(0x130),
  btnA(0x130),
  btnEast(0x131),
  btnB(0x131),
  btnC(0x132),
  btnNorth(0x133),
  btnX(0x133),
  btnWest(0x134),
  btnY(0x134),
  btnZ(0x135),
  btnTL(0x136),
  btnTR(0x137),
  btnTL2(0x138),
  btnTR2(0x139),
  btnSelect(0x13a),
  btnStart(0x13b),
  btnMode(0x13c),
  btnThumbL(0x13d),
  btnThumbR(0x13e),
  btnDigi(0x140),
  btnToolPen(0x140),
  btnToolRubber(0x141),
  btnToolBrush(0x142),
  btnToolPencil(0x143),
  btnToolAirbrush(0x144),
  btnToolFinger(0x145),
  btnToolMouse(0x146),
  btnToolLens(0x147),
  btnToolQuintTap(0x148), // Five fingers on trackpad
  btnStylus3(0x149),
  btnTouch(0x14a),
  btnStylus(0x14b),
  btnStylus2(0x14c),
  btnToolDoubleTap(0x14d),
  btnToolTripleTap(0x14e),
  btnToolQuadTap(0x14f), // Four fingers on trackpad
  btnWheel(0x150),
  btnGearDown(0x150),
  btnGearUp(0x151),
  keyOK(0x160),
  keySelect(0x161),
  keyGoto(0x162),
  keyClear(0x163),
  keyPower2(0x164),
  keyOption(0x165),
  keyInfo(0x166), // AL OEM Features/Tips/Tutorial
  keyTime(0x167),
  keyVendor(0x168),
  keyArchive(0x169),
  keyProgram(0x16a), // Media Select Program Guide
  keyChannel(0x16b),
  keyFavorites(0x16c),
  keyEPG(0x16d),
  keyPVR(0x16e), // Media Select Home
  keyMHP(0x16f),
  keyLanguage(0x170),
  keyTitle(0x171),
  keySubtitle(0x172),
  keyAngle(0x173),
  keyFullScreen(0x174), // AC View Toggle
  keyZoom(0x174),
  keyMode(0x175),
  keyKeyboard(0x176),
  keyAspectRatio(0x177), // HUTRR37: Aspect
  keyScreen(0x177),
  keyPC(0x178), // Media Select Computer
  keyTV(0x179), // Media Select TV
  keyTV2(0x17a), // Media Select Cable
  keyVCR(0x17b), // Media Select VCR
  keyVCR2(0x17c), // VCR Plus
  keySat(0x17d), // Media Select Satellite
  keySat2(0x17e),
  keyCD(0x17f), // Media Select CD
  keyTape(0x180), // Media Select Tape
  keyRadio(0x181),
  keyTuner(0x182), // Media Select Tuner
  keyPlayer(0x183),
  keyText(0x184),
  keyDVD(0x185), // Media Select DVD
  keyAux(0x186),
  keyMP3(0x187),
  keyAudio(0x188), // AL Audio Browser
  keyVideo(0x189), // AL Movie Browser
  keyDirectory(0x18a),
  keyList(0x18b),
  keyMemo(0x18c), // Media Select Messages
  keyCalendar(0x18d),
  keyRed(0x18e),
  keyGreen(0x18f),
  keyYellow(0x190),
  keyBlue(0x191),
  keyChannelUp(0x192), // Channel Increment
  keyChannelDown(0x193), // Channel Decrement
  keyFirst(0x194),
  keyLast(0x195), // Recall Last
  keyAB(0x196),
  keyNext(0x197),
  keyRestart(0x198),
  keySlow(0x199),
  keyShuffle(0x19a),
  keyBreak(0x19b),
  keyPrevious(0x19c),
  keyDigits(0x19d),
  keyTeen(0x19e),
  keyTwen(0x19f),
  keyVideoPhone(0x1a0), // Media Select Video Phone
  keyGames(0x1a1), // Media Select Games
  keyZoomIn(0x1a2), // AC Zoom In
  keyZoomOut(0x1a3), // AC Zoom Out
  keyZoomReset(0x1a4), // AC Zoom
  keyWordProcessor(0x1a5), // AL Word Processor
  keyEditor(0x1a6), // AL Text Editor
  keySpreadsheet(0x1a7), // AL Spreadsheet
  keyGraphicsEditor(0x1a8), // AL Graphics Editor
  keyPresentation(0x1a9), // AL Presentation App
  keyDatabase(0x1aa), // AL Database App
  keyNews(0x1ab), // AL Newsreader
  keyVoiceMail(0x1ac), // AL Voicemail
  keyAddressBook(0x1ad), // AL Contacts/Address Book
  keyMessenger(0x1ae), // AL Instant Messaging
  keyDisplayToggle(0x1af), // Turn display (LCD) on and off
  keyBrightnessToggle(0x1af),
  keySpellCheck(0x1b0), // AL Spell Check
  keyLogoff(0x1b1), // AL Logoff
  keyDollar(0x1b2),
  keyEuro(0x1b3),
  keyFrameBack(0x1b4), // Consumer - transport controls
  keyFrameForward(0x1b5),
  keyContextMenu(0x1b6), // GenDesc - system context menu
  keyMediaRepeat(0x1b7), // Consumer - transport control
  key10ChannelsUp(0x1b8), // 10 channels up (10+)
  key10ChannelsDown(0x1b9), // 10 channels down (10-)
  keyImages(0x1ba), // AL Image Browser
  keyNotificationCenter(0x1bc), // Show/hide the notification center
  keyPickupPhone(0x1bd), // Answer incoming call
  keyHangupPhone(0x1be), // Decline incoming call
  keyDelEOL(0x1c0),
  keyDelEOS(0x1c1),
  keyInsLine(0x1c2),
  keyDelLine(0x1c3),
  keyFn(0x1d0),
  keyFnEsc(0x1d1),
  keyFnF1(0x1d2),
  keyFnF2(0x1d3),
  keyFnF3(0x1d4),
  keyFnF4(0x1d5),
  keyFnF5(0x1d6),
  keyFnF6(0x1d7),
  keyFnF7(0x1d8),
  keyFnF8(0x1d9),
  keyFnF9(0x1da),
  keyFnF10(0x1db),
  keyFnF11(0x1dc),
  keyFnF12(0x1dd),
  keyFn1(0x1de),
  keyFn2(0x1df),
  keyFnD(0x1e0),
  keyFnE(0x1e1),
  keyFnF(0x1e2),
  keyFnS(0x1e3),
  keyFnB(0x1e4),
  keyFnRightShift(0x1e5),
  keyBrlDot1(0x1f1),
  keyBrlDot2(0x1f2),
  keyBrlDot3(0x1f3),
  keyBrlDot4(0x1f4),
  keyBrlDot5(0x1f5),
  keyBrlDot6(0x1f6),
  keyBrlDot7(0x1f7),
  keyBrlDot8(0x1f8),
  keyBrlDot9(0x1f9),
  keyBrlDot10(0x1fa),
  keyNumeric0(0x200), // used by phones, remote controls, and other keypads
  keyNumeric1(0x201),
  keyNumeric2(0x202),
  keyNumeric3(0x203),
  keyNumeric4(0x204),
  keyNumeric5(0x205),
  keyNumeric6(0x206),
  keyNumeric7(0x207),
  keyNumeric8(0x208),
  keyNumeric9(0x209),
  keyNumericStar(0x20a),
  keyNumericPound(0x20b),
  keyNumericA(0x20c), // Phone key A - HUT Telephony 0xb9
  keyNumericB(0x20d),
  keyNumericC(0x20e),
  keyNumericD(0x20f),
  keyCameraFocus(0x210),
  keyWpsButton(0x211), // WiFi Protected Setup key
  keyTouchpadToggle(0x212), // Request switch touchpad on or off
  keyTouchpadOn(0x213),
  keyTouchpadOff(0x214),
  keyCameraZoomIn(0x215),
  keyCameraZoomOut(0x216),
  keyCameraUp(0x217),
  keyCameraDown(0x218),
  keyCameraLeft(0x219),
  keyCameraRight(0x21a),
  keyAttendantOn(0x21b),
  keyAttendantOff(0x21c),
  keyAttendantToggle(0x21d), // Attendant call on or off
  keyLightsToggle(0x21e), // Reading light on or off
  btnDpadUp(0x220),
  btnDpadDown(0x221),
  btnDpadLeft(0x222),
  btnDpadRight(0x223),
  keyAlsToggle(0x230), // Ambient light sensor
  keyRotateLockToggle(0x231), // Display rotation lock
  keyButtonConfig(0x240), // AL Button Configuration
  keyTaskManager(0x241), // AL Task/Project Manager
  keyJournal(0x242), // AL Log/Journal/Timecard
  keyControlPanel(0x243), // AL Control Panel
  keyAppSelect(0x244), // AL Select Task/Application
  keyScreenSaver(0x245), // AL Screen Saver
  keyVoiceCommand(0x246), // Listening Voice Command
  keyAssistant(0x247), // AL Context-aware desktop assistant
  keyKbdLayoutNext(0x248), // AC Next Keyboard Layout Select
  keyEmojiPicker(0x249), // Show/hide emoji picker (HUTRR101)
  keyDictate(0x24a), // Start or Stop Voice Dictation Session (HUTRR99)
  keyCameraAccessEnable(0x24b), // Enables programmatic access to camera devices. (HUTRR72)
  keyCameraAccessDisable(0x24c), // Disables programmatic access to camera devices. (HUTRR72)
  keyCameraAccessToggle(0x24d), // Toggles the current state of the camera access control. (HUTRR72)
  keyBrightnessMin(0x250), // Set Brightness to Minimum
  keyBrightnessMax(0x251), // Set Brightness to Maximum
  keyKbdInputAssistPrev(0x260),
  keyKbdInputAssistNext(0x261),
  keyKbdInputAssistPrevGroup(0x262),
  keyKbdInputAssistNextGroup(0x263),
  keyKbdInputAssistAccept(0x264),
  keyKbdInputAssistCancel(0x265),
  keyRightUp(0x266),
  keyRightDown(0x267),
  keyLeftUp(0x268),
  keyLeftDown(0x269),
  keyRootMenu(0x26a), // Show Device's Root Menu
  keyMediaTopMenu(0x26b), // Show Top Menu of the Media (e.g. DVD)
  keyNumeric11(0x26c),
  keyNumeric12(0x26d),
  keyAudioDesc(0x26e), // Toggle Audio Description
  key3DMode(0x26f),
  keyNextFavorite(0x270),
  keyStopRecord(0x271),
  keyPauseRecord(0x272),
  keyVod(0x273), // Video on Demand
  keyUnmute(0x274),
  keyFastReverse(0x275),
  keySlowReverse(0x276),
  keyData(0x277), // Control a data application associated with the currently viewed channel
  keyOnScreenKeyboard(0x278),
  keyPrivacyScreenToggle(0x279), // Electronic privacy screen control
  keySelectiveScreenshot(0x27a), // Select an area of screen to be copied
  keyNextElement(0x27b), // Move the focus to the next or previous user controllable element within a UI container
  keyPreviousElement(0x27c),
  keyAutopilotEngageToggle(0x27d), // Toggle Autopilot engagement
  keyMarkWaypoint(0x27e), // Shortcut Keys
  keySOS(0x27f),
  keyNavChart(0x280),
  keyFishingChart(0x281),
  keySingleRangeRadar(0x282),
  keyDualRangeRadar(0x283),
  keyRadarOverlay(0x284),
  keyTraditionalSonar(0x285),
  keyClearVuSonar(0x286),
  keySideVuSonar(0x287),
  keyNavInfo(0x288),
  keyBrightnessMenu(0x289),
  keyMacro1(0x290), // Keys for controlling the host-side software responsible for the macro handling
  keyMacro2(0x291),
  keyMacro3(0x292),
  keyMacro4(0x293),
  keyMacro5(0x294),
  keyMacro6(0x295),
  keyMacro7(0x296),
  keyMacro8(0x297),
  keyMacro9(0x298),
  keyMacro10(0x299),
  keyMacro11(0x29a),
  keyMacro12(0x29b),
  keyMacro13(0x29c),
  keyMacro14(0x29d),
  keyMacro15(0x29e),
  keyMacro16(0x29f),
  keyMacro17(0x2a0),
  keyMacro18(0x2a1),
  keyMacro19(0x2a2),
  keyMacro20(0x2a3),
  keyMacro21(0x2a4),
  keyMacro22(0x2a5),
  keyMacro23(0x2a6),
  keyMacro24(0x2a7),
  keyMacro25(0x2a8),
  keyMacro26(0x2a9),
  keyMacro27(0x2aa),
  keyMacro28(0x2ab),
  keyMacro29(0x2ac),
  keyMacro30(0x2ad),
  keyMacroRecordStart(0x2b0),
  keyMacroRecordStop(0x2b1),
  keyMacroPresetCycle(0x2b2),
  keyMacroPreset1(0x2b3),
  keyMacroPreset2(0x2b4),
  keyMacroPreset3(0x2b5),
  keyKbdLCDMenu1(0x2b8),
  keyKbdLCDMenu2(0x2b9),
  keyKbdLCDMenu3(0x2ba),
  keyKbdLCDMenu4(0x2bb),
  keyKbdLCDMenu5(0x2bc),
  btnTriggerHappy(0x2c0),
  btnTriggerHappy1(0x2c0),
  btnTriggerHappy2(0x2c1),
  btnTriggerHappy3(0x2c2),
  btnTriggerHappy4(0x2c3),
  btnTriggerHappy5(0x2c4),
  btnTriggerHappy6(0x2c5),
  btnTriggerHappy7(0x2c6),
  btnTriggerHappy8(0x2c7),
  btnTriggerHappy9(0x2c8),
  btnTriggerHappy10(0x2c9),
  btnTriggerHappy11(0x2ca),
  btnTriggerHappy12(0x2cb),
  btnTriggerHappy13(0x2cc),
  btnTriggerHappy14(0x2cd),
  btnTriggerHappy15(0x2ce),
  btnTriggerHappy16(0x2cf),
  btnTriggerHappy17(0x2d0),
  btnTriggerHappy18(0x2d1),
  btnTriggerHappy19(0x2d2),
  btnTriggerHappy20(0x2d3),
  btnTriggerHappy21(0x2d4),
  btnTriggerHappy22(0x2d5),
  btnTriggerHappy23(0x2d6),
  btnTriggerHappy24(0x2d7),
  btnTriggerHappy25(0x2d8),
  btnTriggerHappy26(0x2d9),
  btnTriggerHappy27(0x2da),
  btnTriggerHappy28(0x2db),
  btnTriggerHappy29(0x2dc),
  btnTriggerHappy30(0x2dd),
  btnTriggerHappy31(0x2de),
  btnTriggerHappy32(0x2df),
  btnTriggerHappy33(0x2e0),
  btnTriggerHappy34(0x2e1),
  btnTriggerHappy35(0x2e2),
  btnTriggerHappy36(0x2e3),
  btnTriggerHappy37(0x2e4),
  btnTriggerHappy38(0x2e5),
  btnTriggerHappy39(0x2e6),
  btnTriggerHappy40(0x2e7),
  keyMinInteresting(113), // AL Integrated Help Center
  keyMax(0x2ff),
  keyCnt(0x300);

  final int value;
  const Key(this.value);
}

enum RelativeAxis {
  x(0x00),
  y(0x01),
  z(0x02),
  rx(0x03),
  ry(0x04),
  rz(0x05),
  hwheel(0x06),
  dial(0x07),
  wheel(0x08),
  misc(0x09),
  reserved(0x0a),
  wheelHiRes(0x0b),
  hwheelHiRes(0x0c),
  relMax(0x0f),
  relCnt(0x10); // relMax + 1

  final int value;
  const RelativeAxis(this.value);
}

enum AbsoluteAxis {
  x(0x00),
  y(0x01),
  z(0x02),
  rx(0x03),
  ry(0x04),
  rz(0x05),
  throttle(0x06),
  rudder(0x07),
  wheel(0x08),
  gas(0x09),
  brake(0x0a),
  hat0x(0x10),
  hat0y(0x11),
  hat1x(0x12),
  hat1y(0x13),
  hat2x(0x14),
  hat2y(0x15),
  hat3x(0x16),
  hat3y(0x17),
  pressure(0x18),
  distance(0x19),
  tiltX(0x1a),
  tiltY(0x1b),
  toolWidth(0x1c),
  volume(0x20),
  profile(0x21),
  misc(0x28),
  reserved(0x2e),
  mtSlot(0x2f), // MT slot being modified
  mtTouchMajor(0x30), // Major axis of touching ellipse
  mtTouchMinor(0x31), // Minor axis (omit if circular)
  mtWidthMajor(0x32), // Major axis of approaching ellipse
  mtWidthMinor(0x33), // Minor axis (omit if circular)
  mtOrientation(0x34), // Ellipse orientation
  mtPositionX(0x35), // Center X touch position
  mtPositionY(0x36), // Center Y touch position
  mtToolType(0x37), // Type of touching device
  mtBlobID(0x38), // Group a set of packets as a blob
  mtTrackingID(0x39), // Unique ID of initiated contact
  mtPressure(0x3a), // Pressure on contact area
  mtDistance(0x3b), // Contact hover distance
  mtToolX(0x3c), // Center X tool position
  mtToolY(0x3d), // Center Y tool position
  absMax(0x3f),
  absCnt(0x40); // absMax + 1

  final int value;
  const AbsoluteAxis(this.value);
}

enum SwitchEvent {
  lid(0x00), // set = lid shut
  tabletMode(0x01), // set = tablet mode
  headphoneInsert(0x02), // set = inserted
  rfKillAll(0x03), // rfkill master switch, type "any" set = radio enabled
  radio(0x03), // deprecated
  microphoneInsert(0x04), // set = inserted
  dock(0x05), // set = plugged into dock
  lineoutInsert(0x06), // set = inserted
  jackPhysicalInsert(0x07), // set = mechanical switch set
  videooutInsert(0x08), // set = inserted
  cameraLensCover(0x09), // set = lens covered
  keypadSlide(0x0a), // set = keypad slide out
  frontProximity(0x0b), // set = front proximity sensor active
  rotateLock(0x0c), // set = rotate locked/disabled
  lineinInsert(0x0d), // set = inserted
  muteDevice(0x0e), // set = device disabled
  penInserted(0x0f), // set = pen inserted
  machineCover(0x10), // set = cover closed
  swMax(0x10),
  swCnt(0x11); // swMax + 1

  final int value;
  const SwitchEvent(this.value);
}

enum MiscEvent {
  serial(0x00),
  pulseLED(0x01),
  gesture(0x02),
  raw(0x03),
  scan(0x04),
  timestamp(0x05),
  mscMax(0x07),
  mscCnt(0x08); // mscMax + 1

  final int value;
  const MiscEvent(this.value);
}

enum LED {
  numL(0x00),
  capsL(0x01),
  scrollL(0x02),
  compose(0x03),
  kana(0x04),
  sleep(0x05),
  suspend(0x06),
  mute(0x07),
  misc(0x08),
  mail(0x09),
  charging(0x0a),
  ledMax(0x0f),
  ledCnt(0x10); // ledMax + 1

  final int value;
  const LED(this.value);
}

enum AutoRepeat {
  delay(0x00),
  period(0x01),
  repMax(0x01),
  repCnt(0x02); // repMax + 1

  final int value;
  const AutoRepeat(this.value);
}

enum Sound {
  click(0x00),
  bell(0x01),
  tone(0x02),
  sndMax(0x07),
  sndCnt(0x08); // sndMax + 1

  final int value;
  const Sound(this.value);
}
