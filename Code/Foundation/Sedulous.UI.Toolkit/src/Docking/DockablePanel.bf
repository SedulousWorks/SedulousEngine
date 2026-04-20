namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

using internal Sedulous.UI;

/// Content panel with title bar, close button, and drag support for docking.
/// Implements IDragSource so it can be dragged to dock/float positions.
public class DockablePanel : ViewGroup, IDragSource
{
	private String mTitle = new .("Panel") ~ delete _;
	private View mContent; // in mChildren via AddView
	private bool mClosable = true;
	private bool mHeaderDrag; // true if mouse-down was on header (enables drag)

	// Last dock position for re-dock after floating.
	public DockPosition mLastDockPosition = .Center;
	public ViewId mLastRelativeToId = .Invalid;

	public float HeaderHeight = 24;
	public IDockHost DockHost;

	public Event<delegate void(DockablePanel)> OnCloseRequested ~ _.Dispose();

	public StringView Title
	{
		get => mTitle;
	}

	public void SetTitle(StringView title)
	{
		mTitle.Set(title);
		InvalidateVisual();
	}

	public bool Closable
	{
		get => mClosable;
		set => mClosable = value;
	}

	public View ContentView => mContent;

	/// Set the content view (replaces existing).
	public void SetContent(View content, LayoutParams lp = null)
	{
		if (mContent != null)
			RemoveView(mContent, true);
		mContent = content;
		if (content != null)
			AddView(content, lp);
		InvalidateLayout();
	}

	/// Save the current dock position for re-docking after floating.
	public void SaveDockPosition(DockPosition position, View relativeTo)
	{
		mLastDockPosition = position;
		mLastRelativeToId = (relativeTo != null) ? relativeTo.Id : .Invalid;
	}

	public this() { }

	public this(StringView title)
	{
		mTitle.Set(title);
	}

	public this(StringView title, View content)
	{
		mTitle.Set(title);
		SetContent(content);
	}

	// === Layout ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float contentH = 0;
		if (mContent != null && mContent.Visibility != .Gone)
		{
			mContent.Measure(wSpec, .Unspecified());
			contentH = mContent.MeasuredSize.Y;
		}
		MeasuredSize = .(wSpec.Resolve(0), hSpec.Resolve(HeaderHeight + contentH));
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		let w = right - left;
		let h = bottom - top;

		if (mContent != null && mContent.Visibility != .Gone)
		{
			let contentH = h - HeaderHeight;
			mContent.Measure(.Exactly(w), .Exactly(contentH));
			mContent.Layout(0, HeaderHeight, w, contentH);
		}
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let w = Width;

		// Header background.
		if (!ctx.TryDrawDrawable("DockablePanel.Header", .(0, 0, w, HeaderHeight), .Normal))
		{
			let headerBg = ctx.Theme?.GetColor("DockablePanel.HeaderBackground", .(40, 44, 55, 255)) ?? .(40, 44, 55, 255);
			ctx.VG.FillRect(.(0, 0, w, HeaderHeight), headerBg);
		}

		// Header text.
		if (ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(12);
			if (font != null)
			{
				let textColor = ctx.Theme?.GetColor("DockablePanel.HeaderText") ?? ctx.Theme?.Palette.Text ?? .(220, 225, 235, 255);
				ctx.VG.DrawText(mTitle, font, .(8, 0, w - 30, HeaderHeight), .Left, .Middle, textColor);
			}
		}

		// Close button (X).
		if (mClosable)
		{
			let cx = w - 14;
			let cy = HeaderHeight * 0.5f;
			let sz = 4.0f;
			let closeRect = RectangleF(cx - sz - 2, cy - sz - 2, sz * 2 + 4, sz * 2 + 4);

			if (!ctx.TryDrawDrawable("DockablePanel.CloseIcon", closeRect, .Normal))
			{
				let closeColor = ctx.Theme?.GetColor("DockablePanel.CloseButton", .(180, 185, 200, 150)) ?? .(180, 185, 200, 150);
				ctx.VG.DrawLine(.(cx - sz, cy - sz), .(cx + sz, cy + sz), closeColor, 1.5f);
				ctx.VG.DrawLine(.(cx + sz, cy - sz), .(cx - sz, cy + sz), closeColor, 1.5f);
			}
		}

		// Content background.
		if (!ctx.TryDrawDrawable("DockablePanel.ContentBackground", .(0, HeaderHeight, w, Height - HeaderHeight), .Normal))
		{
			let contentBg = ctx.Theme?.GetColor("DockablePanel.ContentBackground") ?? ctx.Theme?.Palette.Surface ?? .(42, 44, 54, 255);
			ctx.VG.FillRect(.(0, HeaderHeight, w, Height - HeaderHeight), contentBg);
		}

		DrawChildren(ctx);
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;

		// Close button hit-test.
		if (mClosable && e.X >= Width - 22 && e.Y <= HeaderHeight)
		{
			OnCloseRequested(this);
			e.Handled = true;
			return;
		}

		// Track header click for drag.
		mHeaderDrag = (e.Y <= HeaderHeight);
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		mHeaderDrag = false;
	}

	// === IDragSource ===

	public DragData CreateDragData()
	{
		if (!mHeaderDrag) return null;
		return new DockPanelDragData(this);
	}

	public View CreateDragVisual(DragData data)
	{
		// If dragging from a floating window, suppress the adorner -
		// we'll move the actual FloatingWindow instead.
		if (Parent is FloatingWindow)
			return null;

		let preview = new DockDragPreview();
		preview.SetTitle(mTitle);
		return preview;
	}

	public void OnDragStarted(DragData data)
	{
		if (let panelData = data as DockPanelDragData)
		{
			if (let fw = Parent as FloatingWindow)
			{
				// Floating panel: move the actual window during drag.
				// Dim + disable interaction so DockManager underneath receives drop events.
				panelData.SourceWindow = fw;
				fw.Alpha = 0.5f;
				fw.IsInteractionEnabled = false;

				// Capture where the user clicked relative to the window's origin.
				// DragDropManager.LastScreenX/Y hold the start position (window-relative).
				if (Context?.DragDropManager != null)
				{
					panelData.DragOffsetX = Context.DragDropManager.LastScreenX;
					panelData.DragOffsetY = Context.DragDropManager.LastScreenY;
					Context.DragDropManager.AdornerOffsetX = 0;
					Context.DragDropManager.AdornerOffsetY = 0;
				}
				return;
			}
		}

		// Docked panel: dim while dragging.
		Alpha = 0.4f;
		if (Context?.DragDropManager != null)
		{
			Context.DragDropManager.AdornerOffsetX = -30;
			Context.DragDropManager.AdornerOffsetY = -12;
		}
	}

	public void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled)
	{
		Alpha = 1.0f;

		// Restore floating window state only when cancelled.
		// On successful drop (.Move), the FloatingWindow was already destroyed
		// by DestroyFloatingWindow -> ClosePopup (ownsView=true).
		if (cancelled)
		{
			if (let panelData = data as DockPanelDragData)
			{
				if (panelData.SourceWindow != null)
				{
					panelData.SourceWindow.Alpha = 1.0f;
					panelData.SourceWindow.IsInteractionEnabled = true;
				}
			}
		}
	}
}
