using System;

namespace Sedulous.GUI;

/// What a root draws over its tree to show its workings (nothing by default). The layout's (each
/// node's border box, padding, margin and baseline) and the input's: the focus path, the tab
/// order, the last directional move's candidates, the node under the pointer, and a flash on the
/// nodes that asked for a redraw.
struct DebugOverlay : IEquatable<DebugOverlay>
{
	// The layout's, for working on a layout.
	/// Each node's border box (red).
	public bool Bounds = false;
	/// Its padding (green).
	public bool Padding = false;
	/// Its margin (orange).
	public bool Margin = false;
	/// A baseline of its own (magenta).
	public bool Baselines = false;
	// The input's.
	/// The focused node and each node holding it, named.
	public bool FocusPath = false;
	/// The tab stops in order, numbered and joined.
	public bool TabOrder = false;
	/// The last directional move: each candidate, its score or why not, the one chosen.
	public bool Navigation = false;
	/// The node under the pointer, named, with its size.
	public bool Pointer = false;
	/// The nodes that invalidated themselves, fading after the frame.
	public bool RedrawFlash = false;

	public static DebugOverlay Layout
	{
		get
		{
			var o = DebugOverlay();
			o.Bounds = o.Padding = o.Margin = o.Baselines = true;
			return o;
		}
	}

	public static DebugOverlay Input
	{
		get
		{
			var o = DebugOverlay();
			o.FocusPath = o.TabOrder = o.Navigation = o.Pointer = o.RedrawFlash = true;
			return o;
		}
	}

	public bool AnyLayout => Bounds || Padding || Margin || Baselines;
	public bool AnyInput => FocusPath || TabOrder || Navigation || Pointer || RedrawFlash;
	public bool Any => AnyLayout || AnyInput;

	public bool Equals(DebugOverlay other) => this == other;

	[Commutable]
	public static bool operator==(DebugOverlay a, DebugOverlay b) =>
		(a.Bounds == b.Bounds) && (a.Padding == b.Padding) && (a.Margin == b.Margin) && (a.Baselines == b.Baselines) &&
		(a.FocusPath == b.FocusPath) && (a.TabOrder == b.TabOrder) && (a.Navigation == b.Navigation) &&
		(a.Pointer == b.Pointer) && (a.RedrawFlash == b.RedrawFlash);
}
