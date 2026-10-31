using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The overlay of drop chips shown while a panel is being dragged.
///
/// INPUT TRANSPARENT: the drag is tracked by the manager, and the indicator only draws. Letting
/// it take the pointer would end the drag the moment it appeared under one.
class DockZoneIndicator : View
{
	/// Handed down by the owning [[DockManager]] from its resolved accent.
	///
	/// The indicator is drawn MANUALLY and is never part of the styled tree, so it cannot
	/// resolve a sheet itself. Without this it would stay hardcoded blue whatever the theme.
	public Color Accent = .(80 / 255.0f, 150 / 255.0f, 240 / 255.0f, 1.0f);

	private List<DockTarget> mTargets = new .() ~ delete _;
	private int32 mHoveredIndex = -1;

	public this()
	{
		IsHitTestVisible = false;
	}

	public int32 TargetCount => (int32)mTargets.Count;

	public int32 HoveredIndex => mHoveredIndex;

	public void ClearTargets()
	{
		mTargets.Clear();
		mHoveredIndex = -1;
	}

	/// Adds a zone. A zero area preview means dropping here shows no outcome wash.
	public void AddTarget(DockPosition position, Rectangle rect, View relativeTo,
		Rectangle previewRect = .())
	{
		DockTarget target = .();
		target.Position = position;
		target.Rect = rect;
		target.RelativeTo = relativeTo;
		target.PreviewRect = previewRect;
		mTargets.Add(target);
	}

	/// FIRST match wins, so overlapping chips resolve in the order they were added rather than
	/// by area.
	public void UpdateHover(float x, float y)
	{
		mHoveredIndex = -1;

		for (int32 i = 0; i < mTargets.Count; i++)
		{
			let rect = mTargets[i].Rect;
			if ((x >= rect.X) && (x < rect.X + rect.Width) && (y >= rect.Y)
				&& (y < rect.Y + rect.Height))
			{
				mHoveredIndex = i;
				return;
			}
		}
	}

	public DockTarget? HoveredTarget =>
		((mHoveredIndex >= 0) && (mHoveredIndex < mTargets.Count)) ? mTargets[mHoveredIndex]
			: null;

	public override void OnDraw(UIDrawContext ctx)
	{
		let zoneFill = Color(Accent.R, Accent.G, Accent.B, 80 / 255.0f);
		let zoneBorder = Color(Accent.R, Accent.G, Accent.B, 200 / 255.0f);
		let hoverFill = Color(zoneFill.R, zoneFill.G, zoneFill.B,
			Min(1.0f, zoneFill.A + (60 / 255.0f)));

		// The OUTCOME wash goes first, UNDER the chips: it covers the region the panel would
		// take, which is usually most of the screen, and would otherwise hide them.
		DrawHoveredPreview(ctx);

		let arrowBase = ResolveStyleColor(.TextColor, Color.White);
		for (int32 i = 0; i < mTargets.Count; i++)
		{
			let target = mTargets[i];
			let isHovered = i == mHoveredIndex;

			ctx.VG.FillRoundedRect(target.Rect, 4, isHovered ? hoverFill : zoneFill);
			ctx.VG.StrokeRoundedRect(target.Rect, 4, zoneBorder, 1);

			DrawArrow(ctx, target, Color(arrowBase.R, arrowBase.G, arrowBase.B,
				(isHovered ? 220 : 150) / 255.0f));
		}
	}

	private void DrawHoveredPreview(UIDrawContext ctx)
	{
		if ((mHoveredIndex < 0) || (mHoveredIndex >= mTargets.Count))
			return;

		let preview = mTargets[mHoveredIndex].PreviewRect;
		if ((preview.Width <= 0) || (preview.Height <= 0))
			return;

		ctx.VG.FillRect(preview, .(Accent.R, Accent.G, Accent.B, 45 / 255.0f));
		ctx.VG.StrokeRect(preview, .(Accent.R, Accent.G, Accent.B, 180 / 255.0f), 2);
	}

	/// A triangle pointing the way the panel would go, or a filled square for docking into the
	/// target's own tabs, which is not a direction.
	private void DrawArrow(UIDrawContext ctx, DockTarget target, Color color)
	{
		let center = target.Rect.Center();
		let size = 6.0f;

		ctx.VG.BeginPath();
		switch (target.Position)
		{
		case .Top:
			ctx.VG.MoveTo(center.X - size, center.Y + (size * 0.3f));
			ctx.VG.LineTo(center.X + size, center.Y + (size * 0.3f));
			ctx.VG.LineTo(center.X, center.Y - (size * 0.5f));

		case .Bottom:
			ctx.VG.MoveTo(center.X - size, center.Y - (size * 0.3f));
			ctx.VG.LineTo(center.X + size, center.Y - (size * 0.3f));
			ctx.VG.LineTo(center.X, center.Y + (size * 0.5f));

		case .Left:
			ctx.VG.MoveTo(center.X + (size * 0.3f), center.Y - size);
			ctx.VG.LineTo(center.X + (size * 0.3f), center.Y + size);
			ctx.VG.LineTo(center.X - (size * 0.5f), center.Y);

		case .Right:
			ctx.VG.MoveTo(center.X - (size * 0.3f), center.Y - size);
			ctx.VG.LineTo(center.X - (size * 0.3f), center.Y + size);
			ctx.VG.LineTo(center.X + (size * 0.5f), center.Y);

		case .Center:
			ctx.VG.FillRect(.(center.X - size, center.Y - size, size * 2, size * 2), color);

		case .Float:
		}

		ctx.VG.ClosePath();
		ctx.VG.Fill(color);
	}
}
