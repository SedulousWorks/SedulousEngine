using Sedulous.Core;

namespace Sedulous.UI;

/// Animates a two component vector, each component independently.
class Float2Animation : Animation
{
	private Float2 mFrom;
	private Float2 mTo;
	/// OWNED.
	private delegate void(Float2) mSetter ~ delete _;

	/// OWNERSHIP of the setter transfers.
	public this(Float2 from, Float2 to, float duration, delegate void(Float2) setter,
		EasingFunction easing = null) : base(duration, easing)
	{
		mFrom = from;
		mTo = to;
		mSetter = setter;
	}

	public Float2 From => mFrom;
	public Float2 To => mTo;

	protected override void Apply(float t) =>
		mSetter(.(mFrom.X + (mTo.X - mFrom.X) * t, mFrom.Y + (mTo.Y - mFrom.Y) * t));
}
