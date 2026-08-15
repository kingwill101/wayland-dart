/// Tweens map [Animation<double>] values to concrete types.
///
/// This file now re-exports from [animatable] for backward compatibility.
/// New code should import [animatable] directly for the full set of tweens
/// (including [ColorTween], [OffsetTween], [SizeTween], [RectTween]).
library;

export 'animatable.dart' show Tween;
