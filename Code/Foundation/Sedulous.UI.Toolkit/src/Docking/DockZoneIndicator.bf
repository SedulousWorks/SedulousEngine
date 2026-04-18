namespace Sedulous.UI.Toolkit;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// A dock target zone with position and bounds.
public struct DockTarget
{
	public DockPosition Position;
	public RectangleF Rect;
	public View RelativeTo; // the view this zone docks relative to
}

/// Overlay that shows dock drop zones during drag operations.
/// Hit-test transparent — shown via PopupLayer.
public class DockZoneIndicator : View
{
	private List<DockTarget> mTargets = new .() ~ delete _;
	private int mHoveredIndex = -1;

	public int TargetCount => mTargets.Count;
	public int HoveredIndex => mHoveredIndex;

	public this()
	{
		IsHitTestVisible = false;
	}

	/// Clear all targets.
	public void ClearTargets()
	{
		mTargets.Clear();
		mHoveredIndex = -1;
	}

	/// Add a dock zone target.
	public void AddTarget(DockPosition position, RectangleF rect, View relativeTo)
	{
		DockTarget t;
		t.Position = position;
		t.Rect = rect;
		t.RelativeTo = relativeTo;
		mTargets.Add(t);
	}

	/// Update hover state from screen coordinates.
	public void UpdateHover(float x, float y)
	{
		mHoveredIndex = -1;
		for (int i = 0; i < mTargets.Count; i++)
		{
			let r = mTargets[i].Rect;
			if (x >= r.X && x < r.X + r.Width && y >= r.Y && y < r.Y + r.Height)
			{
				mHoveredIndex = i;
				return;
			}
		}
	}

	/// Get the hovered target, or null.
	public DockTarget? HoveredTarget =>
		(mHoveredIndex >= 0 && mHoveredIndex < mTargets.Count) ? mTargets[mHoveredIndex] : null;

	public override void OnDraw(UIDrawContext ctx)
	{
		let zoneColor = ctx.Theme?.GetColor("DockZone.Indicator", .(80, 150, 240, 80)) ?? .(80, 150, 240, 80);
		let zoneBorder = ctx.Theme?.GetColor("DockZone.Border", .(80, 150, 240, 200)) ?? .(80, 150, 240, 200);
		let hoverColor = Color(zoneColor.R, zoneColor.G, zoneColor.B, (uint8)Math.Min(255, zoneColor.A + 60));

		for (int i = 0; i < mTargets.Count; i++)
		{
			let target = mTargets[i];
			let isHovered = (i == mHoveredIndex);
			let fill = isHovered ? hoverColor : zoneColor;

			ctx.VG.FillRoundedRect(target.Rect, 4, fill);
			ctx.VG.StrokeRoundedRect(target.Rect, 4, zoneBorder, 1);

			// Draw directional arrow.
			let cx = target.Rect.X + target.Rect.Width * 0.5f;
			let cy = target.Rect.Y + target.Rect.Height * 0.5f;
			let arrowColor = Color(255, 255, 255, isHovered ? 220 : 150);
			let sz = 6.0f;

			ctx.VG.BeginPath();
			switch (target.Position)
			{
			case .Top:
				ctx.VG.MoveTo(cx - sz, cy + sz * 0.3f);
				ctx.VG.LineTo(cx + sz, cy + sz * 0.3f);
				ctx.VG.LineTo(cx, cy - sz * 0.5f);
			case .Bottom:
				ctx.VG.MoveTo(cx - sz, cy - sz * 0.3f);
				ctx.VG.LineTo(cx + sz, cy - sz * 0.3f);
				ctx.VG.LineTo(cx, cy + sz * 0.5f);
			case .Left:
				ctx.VG.MoveTo(cx + sz * 0.3f, cy - sz);
				ctx.VG.LineTo(cx + sz * 0.3f, cy + sz);
				ctx.VG.LineTo(cx - sz * 0.5f, cy);
			case .Right:
				ctx.VG.MoveTo(cx - sz * 0.3f, cy - sz);
				ctx.VG.LineTo(cx - sz * 0.3f, cy + sz);
				ctx.VG.LineTo(cx + sz * 0.5f, cy);
			case .Center:
				ctx.VG.FillRect(.(cx - sz, cy - sz, sz * 2, sz * 2), arrowColor);
			case .Float:
			}
			ctx.VG.ClosePath();
			ctx.VG.Fill(arrowColor);
		}
	}
}
