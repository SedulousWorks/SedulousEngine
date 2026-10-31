using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// A sheet's `@keyframes name { ... }`: its frames by offset (0 to 1, ascending), each the
/// declarations written under it held as a rule. Several offsets sharing a block share its
/// rule.
class KeyframesRule : RefCounted
{
	public struct Frame
	{
		public float Offset;
		/// A reference the rule holds.
		public StyleRule Declarations;
	}

	public String Name = new .() ~ delete _;
	public List<Frame> Frames = new .() ~ ReleaseFrames(_);

	public this() {}

	private static void ReleaseFrames(List<Frame> frames)
	{
		for (let frame in frames)
			frame.Declarations.ReleaseRef();
		delete frames;
	}

	/// Adds a frame at `offset`, in order, a later frame at the same offset after the earlier.
	/// Takes a reference of its own to `declarations`.
	public void AddFrame(float offset, StyleRule declarations)
	{
		var at = Frames.Count;
		while ((at > 0) && (Frames[at - 1].Offset > offset))
			at--;
		declarations.AddRef();
		Frame frame = .() { Offset = offset, Declarations = declarations };
		Frames.Insert(at, frame);
	}

	/// Whether any frame declares `property`.
	public bool Animates(StyleProperty property)
	{
		for (let frame in Frames)
		{
			if (frame.Declarations.GetValue(property) != null)
				return true;
		}
		return false;
	}
}
