using System;

namespace Sedulous.Animation;

/// What a fired event is delivered to: its name, and the time in the clip it was placed at.
///
/// BORROWED for the call, so a handler that keeps the name copies it.
typealias AnimationEventHandler = delegate void(StringView name, float time);
