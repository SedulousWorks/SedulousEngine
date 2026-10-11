using System;
using Sedulous.Core;

namespace Sedulous.Engine.UI;

/// Where a screen tier draws on its target, and how. Fitted false is the plain draw: laid out at
/// the target's own size over all of it. Fitted, the root lays out at DrawSize over its DpiScale
/// and draws into Rect of the target, through Transform, which turns the root's pixels (a
/// DrawSize frame, Rect turned back) onto Rect's own: identity unless the game's orientation
/// turns it.
struct UIScreenPlacement
{
	public bool Fitted = false;
	public ContentRotation Turn = .None;
	public Rectangle Rect = .(0, 0, 0, 0);
	public Float2 DrawSize = .Zero;
	public float DpiScale = 1.0f;
	public Float4x4 Transform = .Identity();

	public this() {}
}
