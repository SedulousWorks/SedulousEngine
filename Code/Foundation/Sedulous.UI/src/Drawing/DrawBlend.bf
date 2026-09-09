namespace Sedulous.UI;

/// What a running transition asks the drawable draw path to blend.
///
/// Set per child from the child's active transitions, and consumed ONCE by Drawable.Draw,
/// which clears it for any nested drawables it goes on to draw. Without that, a layer or
/// inset inside a cross-fading background would fade a second time.
struct DrawBlend
{
	/// A `background` drawable change in flight: From is drawn UNDER To at DrawableT.
	public Drawable FromDrawable = null;
	public Drawable ToDrawable = null;
	public float DrawableT = 1.0f;

	/// A control state change in flight: a state aware drawable draws FromState under
	/// ToState at StateT.
	public bool StateActive = false;
	public ControlState FromState = .Normal;
	public ControlState ToState = .Normal;
	public float StateT = 1.0f;

	public this() {}

	public bool IsActive => StateActive || (FromDrawable != null);
}
