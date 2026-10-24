using System;

namespace Sedulous.GUI;

/// Why a root asked for a frame (each true when it did, as NeedsFrame last found).
struct FrameReasons
{
	/// Something shown was invalidated.
	public bool Redraw = false;
	/// A layout waits.
	public bool Layout = false;
	/// A binding or a queued mutation waits.
	public bool Pending = false;
	/// A held direction repeats.
	public bool HeldDirection = false;
	/// An action runs on a node it shows (FrameStats.AnimatedNode names the first).
	public bool Animation = false;
	/// The debug overlay's redraw flashes are fading.
	public bool Overlay = false;

	public bool Any => Redraw || Layout || Pending || HeldDirection || Animation || Overlay;
}

/// What a root's last frame cost and why it was needed. The phases write it as they run: the
/// style pass its time and the widgets it restyled, the layout pass its time and the containers
/// it laid out, the draw its time, the nodes it drew and culled and the VG geometry they made.
/// NeedsFrame writes the reasons it found, so an idle GUI that is not idle says what keeps it
/// awake. Read by a host's frame stats, the inspector's frames tab and tests.
class FrameStats
{
	public FrameReasons Reasons;
	/// The first shown node an action runs on, when Reasons.Animation.
	public String AnimatedNode = new .() ~ delete _;
	public double StyleMs = 0.0;
	/// Widgets the style pass restyled.
	public uint32 Restyled = 0;
	public double LayoutMs = 0.0;
	/// Containers the layout pass laid out.
	public uint32 LaidOut = 0;
	public double DrawMs = 0.0;
	public uint32 NodesDrawn = 0;
	/// Skipped as outside the clip.
	public uint32 NodesCulled = 0;
	/// The VG geometry the draw made.
	public uint32 Vertices = 0;
	public uint32 Commands = 0;
	/// How many frames this root has drawn through DrawFrame.
	public uint64 FramesDrawn = 0;

	/// Becomes a copy of `other`.
	public void Set(FrameStats other)
	{
		Reasons = other.Reasons;
		AnimatedNode.Set(other.AnimatedNode);
		StyleMs = other.StyleMs;
		Restyled = other.Restyled;
		LayoutMs = other.LayoutMs;
		LaidOut = other.LaidOut;
		DrawMs = other.DrawMs;
		NodesDrawn = other.NodesDrawn;
		NodesCulled = other.NodesCulled;
		Vertices = other.Vertices;
		Commands = other.Commands;
		FramesDrawn = other.FramesDrawn;
	}

	/// Back to a frame that has cost nothing yet.
	public void Reset()
	{
		Reasons = .();
		AnimatedNode.Clear();
		StyleMs = 0.0;
		Restyled = 0;
		LayoutMs = 0.0;
		LaidOut = 0;
		DrawMs = 0.0;
		NodesDrawn = 0;
		NodesCulled = 0;
		Vertices = 0;
		Commands = 0;
		FramesDrawn = 0;
	}

	/// One line: the phases' times and counts, then the reasons. In microseconds, which read
	/// better than milliseconds here.
	public void Describe(String outText)
	{
		outText.AppendF("style {} us ({} restyled), layout {} us ({} laid out), draw {} us ({} drawn, {} culled, {} vertices, {} commands)",
			Micros(StyleMs), Restyled, Micros(LayoutMs), LaidOut, Micros(DrawMs), NodesDrawn, NodesCulled, Vertices, Commands);
		outText.Append("; asked by:");
		if (!Reasons.Any)
			outText.Append(" nothing");
		if (Reasons.Redraw)
			outText.Append(" redraw");
		if (Reasons.Layout)
			outText.Append(" layout");
		if (Reasons.Pending)
			outText.Append(" pending");
		if (Reasons.HeldDirection)
			outText.Append(" held-direction");
		if (Reasons.Animation)
			outText.AppendF(" animation ({})", AnimatedNode);
		if (Reasons.Overlay)
			outText.Append(" overlay");
	}

	private static uint64 Micros(double ms) => (uint64)(ms * 1000.0 + 0.5);
}
