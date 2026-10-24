using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.VG.Renderer;

namespace Sedulous.GUI;

// IHostedContent: what a node shows that is drawn outside the GUI's batch (a 3D scene into a target
// of its own, GUI.Viewport's Viewport).
//
// The host drives it each frame, so an application wires none of it: it binds the content to the
// renderer of the window its node is in (again when the node moves to another window, a panel
// floated or docked back), places its input surface over the node in that window's pixels, and on
// that window's frame records its drawing before the GUI's pass samples it. Its input surfaces go
// through a router of their own, so the GUI still sees the pointer (the node's hover and focus)
// while the content reads its own, gated to the node.

interface IHostedContent
{
	/// The node it shows in: its root says which window it is in.
	Node HostedNode { get; }
	/// Bound to the window it is in: `renderer` draws that window's GUI (null: in no window, its
	/// last let go), `input` and `windowId` its input surface's. All borrowed.
	void Bind(IDevice device, VGRenderer renderer, Sedulous.Shell.IInputManager input, uint32 windowId);
	/// Where its node lies in its window, in the window's pixels, and the window's size.
	void Place(Rectangle windowPixels, Float2 windowSize);
	/// Its drawing, on its window's frame, before that window's GUI is drawn.
	void Record(ICommandEncoder encoder, int32 frameIndex);
	/// The input surface the host's content router gates (null until bound). The content's own.
	Sedulous.Shell.InputSurface HostedSurface { get; }
}
