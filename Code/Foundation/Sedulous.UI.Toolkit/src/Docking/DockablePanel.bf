namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Content panel with title bar, close button, and drag support for docking.
/// Implements IDragSource so it can be dragged to dock/float positions.
public class DockablePanel : ViewGroup, IDragSource
{
	private String mTitle = new .("Panel") ~ delete _;
	private String mPersistenceId = new .() ~ delete _;
	private View mContent; // in mChildren via AddView
	private bool mClosable = true;
	private bool mShowHeader = true;
	private bool mHeaderDrag; // true if mouse-down was on header (enables drag)

	// Last dock position for re-dock after floating.
	public DockPosition mLastDockPosition = .Center;
	public ViewId mLastRelativeToId = .Invalid;

	public float HeaderHeight = 24;
	public IDockHost DockHost;

	public Event<delegate void(DockablePanel)> OnCloseRequested ~ _.Dispose();

	/// Stable identifier for layout persistence.
	/// Set once when creating the panel (e.g., "Assets", "Console", "Inspector").
	/// Must be unique within the DockManager.
	public StringView PersistenceId
	{
		get => mPersistenceId;
	}

	public void SetPersistenceId(StringView id)
	{
		mPersistenceId.Set(id);
	}

	public StringView Title
	{
		get => mTitle;
	}

	public void SetTitle(StringView title)
	{
		mTitle.Set(title);
		Invalidate();
	}

	public bool Closable
	{
		get => mClosable;
		set => mClosable = value;
	}

	/// Whether to show the panel's own header bar. Set to false when the panel
	/// is inside a DockTabGroup (the tab strip replaces the header).
	public bool ShowHeader
	{
		get => mShowHeader;
		set { mShowHeader = value; Invalidate(); }
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
		Invalidate();
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

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let headerH = mShowHeader ? HeaderHeight : 0;
		if (mContent != null && mContent.Visibility != .Gone)
		{
			// A docked panel fills its dock-allocated region; its size is
			// dictated by the dock layout, NOT its content. Measure content
			// within the incoming constraints (minus the header), never
			// unbounded - an unbounded measure makes Grow/Match content
			// report a content-driven, region-ignoring size that leaks into
			// dock sizing and overflows sibling panels.
			mContent.Measure(BoxConstraints(
				constraints.MinWidth, constraints.MaxWidth,
				Math.Max(0, constraints.MinHeight - headerH),
				Math.Max(0, constraints.MaxHeight - headerH)));
		}
		MeasuredSize = .(constraints.ConstrainWidth(0), constraints.ConstrainHeight(0));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let headerH = mShowHeader ? HeaderHeight : 0;
		if (mContent != null && mContent.Visibility != .Gone)
		{
			let contentH = height - headerH;
			mContent.Measure(BoxConstraints.Tight(width, contentH));
			mContent.Layout(0, headerH, width, contentH);
		}
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let w = Width;
		let headerH = mShowHeader ? HeaderHeight : 0;

		if (mShowHeader)
		{
			// Header background.
			let headerDrawable = ResolvePartDrawable("header", .Background, .Normal);
			if (headerDrawable != null)
				headerDrawable.Draw(ctx, .(0, 0, w, HeaderHeight));
			else
				ctx.VG.FillRect(.(0, 0, w, HeaderHeight), .(40, 44, 55, 255));

			// Header text.
			if (ctx.FontService != null)
			{
				let font = ctx.FontService.GetFont(12);
				if (font != null)
				{
					let textColor = ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
					ctx.VG.DrawText(mTitle, font, .(8, 0, w - 30, HeaderHeight), .Left, .Middle, textColor);
				}
			}

			// Close button (X).
			if (mClosable)
			{
				let cx = w - 14;
				let cy = HeaderHeight * 0.5f;
				let sz = 4.0f;

				let closeColor = ResolvePartColor("close-button", .TextColor, .Normal, .(180, 185, 200, 150));
				ctx.VG.DrawLine(.(cx - sz, cy - sz), .(cx + sz, cy + sz), closeColor, 1.5f);
				ctx.VG.DrawLine(.(cx + sz, cy - sz), .(cx - sz, cy + sz), closeColor, 1.5f);
			}
		}

		// Content background.
		let contentDrawable = ResolvePartDrawable("content", .Background, .Normal);
		if (contentDrawable != null)
			contentDrawable.Draw(ctx, .(0, headerH, w, Height - headerH));
		else
			ctx.VG.FillRect(.(0, headerH, w, Height - headerH), .(42, 44, 54, 255));

		DrawChildren(ctx);
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;

		if (mShowHeader)
		{
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
		// If dragging from a dockable window, suppress the adorner -
		// we'll move the actual DockableWindow instead.
		if (Parent is DockableWindow)
			return null;

		let preview = new DockDragPreview();
		preview.SetTitle(mTitle);
		return preview;
	}

	public void OnDragStarted(DragData data)
	{
		if (let panelData = data as DockPanelDragData)
		{
			if (let fw = Parent as DockableWindow)
			{
				// Floating panel: move the actual window during drag.
				// Dim + disable interaction so DockManager underneath receives drop events.
				panelData.SourceWindow = fw;
				fw.Opacity = 0.5f;
				fw.IsInteractionEnabled = false;

				// Capture drag offset so the window follows the cursor at the grab point.
				if (Context?.DragDropManager != null)
				{
					if (fw.IsOSWindow)
					{
						// OS windows: use absolute screen position (host moves with global coords).
						panelData.DragOffsetX = Context.DragDropManager.LastScreenX;
						panelData.DragOffsetY = Context.DragDropManager.LastScreenY;
					}
					else
					{
						// Virtual windows: offset relative to window's top-left.
						let windowPos = fw.LocalToScreen(.(0, 0));
						panelData.DragOffsetX = Context.DragDropManager.LastScreenX - windowPos.X;
						panelData.DragOffsetY = Context.DragDropManager.LastScreenY - windowPos.Y;
					}
					Context.DragDropManager.AdornerOffsetX = 0;
					Context.DragDropManager.AdornerOffsetY = 0;
				}
				return;
			}
		}

		// Docked panel: dim while dragging.
		Opacity = 0.4f;
		if (Context?.DragDropManager != null)
		{
			Context.DragDropManager.AdornerOffsetX = -30;
			Context.DragDropManager.AdornerOffsetY = -12;
		}
	}

	public void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled)
	{
		Opacity = 1.0f;

		// Restore floating window state only when cancelled.
		// On successful drop (.Move), the DockableWindow was already destroyed
		// by DestroyDockableWindow -> ClosePopup (ownsView=true).
		if (cancelled)
		{
			if (let panelData = data as DockPanelDragData)
			{
				if (panelData.SourceWindow != null)
				{
					panelData.SourceWindow.Opacity = 1.0f;
					panelData.SourceWindow.IsInteractionEnabled = true;
				}
			}
		}
	}
}
