namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// A floating window that wraps a DockablePanel.
/// Virtual mode: shown via PopupLayer as a draggable overlay.
/// Double-click title bar to re-dock.
public class FloatingWindow : ViewGroup, IDockableWindow
{
	private DockablePanel mPanel;
	private float mTitleBarHeight = 24;
	public bool IsOSWindow;

	public Event<delegate void(FloatingWindow)> OnDockRequested ~ _.Dispose();
	public Event<delegate void(FloatingWindow)> OnCloseRequested ~ _.Dispose();

	/// The panel contained in this floating window.
	public DockablePanel Panel => mPanel;

	public this(DockablePanel panel)
	{
		mPanel = panel;
		if (panel != null)
			AddView(panel);
	}

	// === Measure / Layout ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		let w = wSpec.Resolve(250);
		let h = hSpec.Resolve(200);

		if (mPanel != null)
			mPanel.Measure(.Exactly(w), .Exactly(h));

		MeasuredSize = .(w, h);
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		if (mPanel != null)
			mPanel.Layout(0, 0, right - left, bottom - top);
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		if (!IsOSWindow)
		{
			// Virtual mode: draw background and border.
			if (!ctx.TryDrawDrawable("FloatingWindow.Background", .(0, 0, Width, Height), .Normal))
			{
				let bgColor = ctx.Theme?.Palette.Surface ?? .(42, 44, 54, 255);
				ctx.VG.FillRoundedRect(.(0, 0, Width, Height), 4, bgColor);
			}
			let borderColor = ctx.Theme?.Palette.Border ?? .(65, 70, 85, 255);
			ctx.VG.StrokeRect(.(0, 0, Width, Height), borderColor, 2);
		}

		DrawChildren(ctx);
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;

		// Title bar area: double-click to re-dock.
		if (e.Y < mTitleBarHeight && e.ClickCount >= 2)
		{
			OnDockRequested(this);
			e.Handled = true;
		}
	}

	// === IDockableWindow ===

	/// Detach and return the panel. Caller takes ownership.
	public DockablePanel DetachPanel()
	{
		let panel = mPanel;
		if (panel != null)
		{
			DetachView(panel);
			mPanel = null;
		}
		return panel;
	}
}
