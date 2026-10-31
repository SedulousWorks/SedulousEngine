using System;
using Sedulous.Core;

namespace Sedulous.Engine.GUI;

/// Where a screen tier draws on its target: not fitted, the plain
/// draw at the target's own size over all of it; fitted, the root lays out at DrawSize over its
/// display scale DpiScale and draws into Rect of the target through Transform, which turns the
/// root's pixels onto the rectangle's (identity unless the orientation turns it).
struct GuiScreenPlacement
{
	public bool Fitted = false;
	public ContentRotation Turn = .None;
	public Rectangle Rect = .(0, 0, 0, 0);
	public Float2 DrawSize = .Zero;
	public float DpiScale = 1.0f;
	public Float4x4 Transform = .Identity();

	public this() {}
}
