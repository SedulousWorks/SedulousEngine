namespace Sedulous.UI;

/// The timing function names a `transition` accepts.
///
/// These are quadratic curves rather than CSS cubic beziers; `cubic-bezier()` and `steps()`
/// are not supported.
enum TransitionEasing : uint8
{
	Linear,
	Ease,
	EaseIn,
	EaseOut,
	EaseInOut
}
