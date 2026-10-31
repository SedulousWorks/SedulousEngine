namespace Sedulous.UI;

/// What the context is doing right now.
///
/// Tree mutations arriving during Animating defer to the mutation queue, an animation's
/// completion handler being a common place to remove the view that was animating.
enum UIContextPhase
{
	Idle,
	Layout,
	Drawing,
	Animating
}
