namespace Sedulous.GUI.Toolkit;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

/// A dockable window that wraps a DockablePanel.
/// Virtual mode: shown via PopupLayer as a draggable overlay.
/// Double-click title bar to re-dock.
public class DockableWindow : ViewGroup, IDockableWindow
{
	private DockablePanel mPanel;
	private float mTitleBarHeight = 24;
	public bool IsOSWindow;

	public Event<delegate void(DockableWindow)> OnDockRequested ~ _.Dispose();
	public Event<delegate void(DockableWindow)> OnCloseRequested ~ _.Dispose();

	/// The panel contained in this floating window.
	public DockablePanel Panel => mPanel;

	public this(DockablePanel panel)
	{
		mPanel = panel;
		if (panel != null)
			AddView(panel);
	}

	// === Measure / Layout ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let w = constraints.ConstrainWidth(250);
		let h = constraints.ConstrainHeight(200);

		if (mPanel != null)
			mPanel.Measure(BoxConstraints.Tight(w, h));

		MeasuredSize = .(w, h);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mPanel != null)
			mPanel.Layout(0, 0, width, height);
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		if (!IsOSWindow)
		{
			// Virtual mode: draw background and border.
			let bgDrawable = ResolveStyleDrawable(.Background);
			if (bgDrawable != null)
				bgDrawable.Draw(ctx, .(0, 0, Width, Height));
			else
				ctx.VG.FillRect(.(0, 0, Width, Height), .(42, 44, 54, 255));

			let borderColor = ResolveStyleColor(.BorderColor, .(65, 70, 85, 255));
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
			RemoveView(panel);
			mPanel = null;
		}
		return panel;
	}
}
