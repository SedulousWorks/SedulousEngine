using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// Which way an animation's iterations run (CSS's animation-direction).
enum AnimationDirection : uint8
{
	Normal,
	Reverse,
	/// Forwards, then backwards, ...
	Alternate,
	/// Backwards, then forwards, ...
	AlternateReverse
}

/// What an animation's values do outside its run (CSS's animation-fill-mode): none leaves the
/// cascade's, forwards holds the last frame after it ends, backwards shows the first during
/// its delay, both does both.
enum AnimationFill : uint8
{
	None,
	Forwards,
	Backwards,
	Both
}

/// One entry of an `animation:` list: the @keyframes it plays and how.
struct AnimationSpec
{
	/// The @keyframes' name, BORROWED from the list that holds the entry.
	public StringView Name = default;
	/// Seconds, one iteration.
	public float Duration = 0.0f;
	/// Seconds.
	public float Delay = 0.0f;
	public TimingFunction Easing = .Ease;
	/// Negative: infinite.
	public float Iterations = 1.0f;
	public AnimationDirection Direction = .Normal;
	public AnimationFill Fill = .None;

	public this() {}
}

/// A parsed `animation:` list, shared by every StyleValue carrying it. An EMPTY list is
/// `animation: none`.
class AnimationList : RefCounted
{
	public List<AnimationSpec> Specs = new .() ~ delete _;
	/// The names the specs borrow.
	private List<String> mNames = new .() ~ DeleteContainerAndItems!(_);

	public this() {}

	/// Adds `spec`, its name kept here.
	public void Add(AnimationSpec spec, StringView name)
	{
		let owned = new String(name);
		mNames.Add(owned);
		var added = spec;
		added.Name = owned;
		Specs.Add(added);
	}
}
