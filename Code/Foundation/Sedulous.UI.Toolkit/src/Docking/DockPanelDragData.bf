namespace Sedulous.UI.Toolkit;

using Sedulous.UI;
using Sedulous.Core.Mathematics;
using System;

/// Drag data carrying a reference to a DockablePanel being dragged.
public class DockPanelDragData : DragData
{
	public DockablePanel Panel;
	/// If dragging from an existing DockableWindow, this is set so
	/// DockManager can move it in PopupLayer during drag.
	public DockableWindow SourceWindow;
	/// Mouse offset within the dockable window at drag start (for smooth repositioning).
	public float DragOffsetX;
	public float DragOffsetY;

	public this(DockablePanel panel) : base("dock/panel")
	{
		Panel = panel;
	}
}

/// Drag visual that looks like a mini dockable window (title bar + content area + border).
/// Used as the adorner visual during dock panel drags.
class DockDragPreview : View
{
	private String mTitle = new .() ~ delete _;
	private float mPreviewWidth = 200;
	private float mPreviewHeight = 120;

	public void SetTitle(StringView title) { mTitle.Set(title); }

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(mPreviewWidth), constraints.ConstrainHeight(mPreviewHeight));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let headerH = 24.0f;

		// Border + background
		let borderColor = Color(65, 70, 85, 255);
		let contentBg = Color(42, 44, 54, 255);
		ctx.VG.FillRoundedRect(.(0, 0, Width, Height), 4, contentBg);

		// Header
		let headerBg = Color(40, 44, 55, 255);
		ctx.VG.FillRoundedRect(.(0, 0, Width, headerH), 4, headerBg);
		// Square off header bottom corners
		ctx.VG.FillRect(.(0, headerH - 4, Width, 4), headerBg);

		// Title text
		if (ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(11);
			if (font != null)
			{
				let textColor = Color(220, 225, 235, 255);
				ctx.VG.DrawText(mTitle, font, .(8, 0, Width - 16, headerH), .Left, .Middle, textColor);
			}
		}

		// Border outline
		ctx.VG.StrokeRoundedRect(.(0, 0, Width, Height), 4, borderColor, 1);
	}
}
