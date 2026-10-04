using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Gamekit;

namespace Sedulous.Engine.UI;

/// A screen tier: the scene less root, the screens pushed on it, and the game resolution it lays
/// out at. The shared tier also holds the global overlay layer; with run screens on, each run (the
/// editor's Game tabs) has a tier of its own.
class UIScreenTier
{
	/// The run this tier belongs to; null for the shared tier. A key only, never called.
	public Object Run = null;
	/// Owned by reference: released, and taken off the context, by whoever drops the tier.
	public RootView Root = null;
	/// Push, pop and replace of screens over Root.
	public ScreenStack Stack = new .() ~ delete _;
	/// The shared tier only: the global overlays, ABOVE every run's screens. Owned by Root.
	public ViewGroup Overlay = null;
	/// The game's render resolution and how it fits its target, when it has one: the tier lays
	/// out at that size and draws fitted where the game's image is.
	public Float2 Resolution = .Zero;
	public FitMode FitMode = .Letterbox;
	/// The target the tier last drew into, which the pointer maps against.
	public Float2 TargetSize = .Zero;

	public bool HasResolution => (Resolution.X > 0.0f) && (Resolution.Y > 0.0f);

	/// The resolution fitted into the last target drawn.
	public ContentFit Fit => ContentFit(.(0, 0, TargetSize.X, TargetSize.Y), Resolution, FitMode);

	/// A render space point in the tier's layout units: offset by the part of the resolution a
	/// crop leaves out, and nothing else.
	public Float2 LayoutPoint(Float2 point)
	{
		if (!HasResolution)
			return point;
		let source = Fit.SrcRect();
		return .(point.X - source.X, point.Y - source.Y);
	}

	/// The same point in the pixels the tier's input takes (layout units times its scale).
	public Float2 PointerPoint(Float2 point)
	{
		if (!HasResolution)
			return point;
		let layout = LayoutPoint(point);
		let dpi = Dpi(Fit);
		return .(layout.X * dpi, layout.Y * dpi);
	}

	/// Target pixels per layout unit, down the height: the one scale a layout can take.
	public static float Dpi(ContentFit fit)
	{
		let scale = fit.Scale().Y;
		return (scale > 0.0f) ? (1.0f / scale) : 1.0f;
	}

	public void ApplyResolution(uint32 width, uint32 height, FitMode fit)
	{
		Resolution = ((width > 0) && (height > 0)) ? Float2(width, height) : .Zero;
		FitMode = fit;
		if (!HasResolution && (Root != null))
			Root.DpiScale = 1.0f;
	}
}
