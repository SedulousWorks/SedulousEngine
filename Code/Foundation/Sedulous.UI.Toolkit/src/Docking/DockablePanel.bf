using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// One dockable page: a title bar you can drag it by, a close button, and whatever content it
/// was given.
///
/// The HEADER is both the title and the drag handle, so a panel inside a tab group hides it,
/// the group's tab taking over both jobs. That is what ShowHeader is for.
///
/// Closing goes through RequestClose rather than straight to the event, so a host can VETO it,
/// which is how an editor prompts before discarding an unsaved page. A programmatic closer that
/// must not be stopped raises the event directly.
class DockablePanel : ViewGroup, IDragSource
{
	/// Where this panel last sat, so floating it and re-docking puts it back rather than
	/// wherever the pointer happens to be.
	public DockPosition LastDockPosition = .Center;
	/// By ID rather than by pointer: the view it was relative to may be gone by then.
	public ViewId LastRelativeToId = ViewId.Invalid;

	public float HeaderHeight = 24.0f;
	/// BORROWED: the manager owns itself.
	public IDockHost DockHost = null;

	public Event<delegate void(DockablePanel)> OnCloseRequested ~ _.Dispose();

	/// OWNED. Answer false to SWALLOW a close request, which is how a dirty page prompts first.
	/// A handler that later decides to close raises OnCloseRequested itself, bypassing this.
	public delegate bool(DockablePanel) OnCloseInterceptor ~ delete _;

	private String mTitle = new .("Panel") ~ delete _;
	private String mPersistenceId = new .() ~ delete _;
	/// BORROWED: it is in the child list.
	private View mContent = null;
	private bool mClosable = true;
	private bool mShowHeader = true;
	/// Whether the press that might become a drag landed on the header.
	private bool mHeaderDrag = false;

	public this() {}

	public this(StringView title)
	{
		mTitle.Set(title);
	}

	/// CONSUMES the content's reference.
	public this(StringView title, View content)
	{
		mTitle.Set(title);
		SetContent(content);
	}

	/// The stable name a saved layout refers to this panel by.
	public StringView PersistenceId => mPersistenceId;

	public void SetPersistenceId(StringView id) => mPersistenceId.Set(id);

	public StringView Title => mTitle;

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

	/// Whether to draw the panel's own header, which a panel inside a tab group does not.
	public bool ShowHeader
	{
		get => mShowHeader;
		set
		{
			mShowHeader = value;
			Invalidate();
		}
	}

	/// BORROWED.
	public View ContentView => mContent;

	/// Replaces the content. CONSUMES the caller's reference.
	public void SetContent(View content)
	{
		if (mContent != null)
			RemoveView(mContent);

		mContent = content;
		if (content != null)
			AddView(content);

		Invalidate();
	}

	/// The overload that also places the child; the other keeps whatever placement it carries.
	public void SetContent(View content, LayoutStyle layout)
	{
		if (content != null)
			content.SetLayout(layout);

		SetContent(content);
	}

	/// Remembers where this panel was, for a later re-dock.
	public void SaveDockPosition(DockPosition position, View relativeTo)
	{
		LastDockPosition = position;
		LastRelativeToId = (relativeTo != null) ? relativeTo.Id : ViewId.Invalid;
	}

	/// The USER's close path: the interceptor first, then the event.
	public void RequestClose()
	{
		if ((OnCloseInterceptor != null) && !OnCloseInterceptor(this))
			return;

		OnCloseRequested(this);
	}

	/// True when this panel sits in a window the system draws the chrome for, which is what
	/// suppresses its own close cross. The header itself STAYS, because it is still the handle
	/// a re-dock drag starts from.
	public bool InChromedOSWindow()
	{
		let window = OwningWindow;
		return (window != null) && window.IsOSWindow && window.HasOSChrome;
	}

	/// The floating window this panel is in, or null when it is docked. The DIRECT parent: a
	/// floating window holds exactly one panel and nothing between.
	private DockableWindow OwningWindow => Parent as DockableWindow;

	// ---- Input ----------------------------------------------------------------------------------

	/// ANY press anywhere in this panel's subtree makes it the active one.
	///
	/// On the CAPTURE phase, which runs before the target handles the press and never consumes
	/// it. It has to be here: with two tab groups side by side, a panel can already be its own
	/// group's selected tab while a different panel is the application's active one, so a tab
	/// click alone can never re-announce it.
	public override void OnMouseDownCapture(MouseEventArgs e)
	{
		if (let manager = FindManager())
			manager.OnPanelActivated(this);
	}

	private DockManager FindManager()
	{
		var current = Parent;
		while (current != null)
		{
			if (let manager = current as DockManager)
				return manager;

			current = current.Parent;
		}

		return null;
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled() || (e.Button != .Left) || !mShowHeader)
			return;

		if (mClosable && !InChromedOSWindow() && (e.X >= Width - 22) && (e.Y <= HeaderHeight))
		{
			RequestClose();
			e.Handled = true;
			return;
		}

		mHeaderDrag = e.Y <= HeaderHeight;
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		mHeaderDrag = false;
	}

	// ---- IDragSource ----------------------------------------------------------------------------

	public override IDragSource AsDragSource() => this;

	/// Null unless the press was on the HEADER, which is what stops a drag inside the content
	/// from tearing the panel out of its dock.
	public DragData CreateDragData() => mHeaderDrag ? new DockPanelDragData(this) : null;

	/// NULL when the window itself is what follows the cursor, which is the case for a
	/// borderless window and for an overlay one. Showing a chip as well would put two things in
	/// flight for one drag.
	///
	/// Under system chrome the window stays PUT during a re-dock drag, so the chip is the only
	/// thing in flight and is needed.
	public View CreateDragVisual(DragData data)
	{
		let window = OwningWindow;
		if ((window != null) && !(window.IsOSWindow && window.HasOSChrome))
			return null;

		let preview = new DockDragPreview();
		preview.SetTitle(mTitle);
		return preview;
	}

	public void OnDragStarted(DragData data)
	{
		let panelData = data as DockPanelDragData;
		if (panelData == null)
			return;

		let window = OwningWindow;
		if (window != null)
		{
			BeginFloatingDrag(panelData, window);
			return;
		}

		// A DOCKED panel only dims; there is no window to carry.
		Opacity = 0.4f;
		OffsetAdornerFromCursor();
	}

	/// A panel dragged out of a floating window carries the window with it.
	///
	/// The window is DIMMED and made non interactive, which is what lets the manager underneath
	/// receive the drag events at all: an opaque interactive window under the cursor would
	/// swallow every one of them.
	private void BeginFloatingDrag(DockPanelDragData panelData, DockableWindow window)
	{
		panelData.SourceWindow = window;
		window.Opacity = 0.5f;
		window.IsInteractionEnabled = false;

		if (Context == null)
			return;

		let dragDrop = Context.DragDrop;

		// A real window is positioned in DESKTOP coordinates, so the cursor position IS the
		// offset the host needs; an overlay one is positioned inside the main window, so the
		// offset is measured from its own corner.
		if (window.IsOSWindow)
		{
			panelData.DragOffsetX = dragDrop.LastScreenX;
			panelData.DragOffsetY = dragDrop.LastScreenY;
		}
		else
		{
			let windowPos = window.LocalToScreen(.Zero);
			panelData.DragOffsetX = dragDrop.LastScreenX - windowPos.X;
			panelData.DragOffsetY = dragDrop.LastScreenY - windowPos.Y;
		}

		if (window.IsOSWindow && window.HasOSChrome)
			OffsetAdornerFromCursor();
		else
			ClearAdornerOffset();
	}

	/// The chip sits up and to the left of the cursor, so the pointer stays over the drop zone
	/// it is aiming at rather than under the thing it is carrying.
	private void OffsetAdornerFromCursor()
	{
		if (Context == null)
			return;

		Context.DragDrop.AdornerOffsetX = -30.0f;
		Context.DragDrop.AdornerOffsetY = -12.0f;
	}

	private void ClearAdornerOffset()
	{
		if (Context == null)
			return;

		Context.DragDrop.AdornerOffsetX = 0.0f;
		Context.DragDrop.AdornerOffsetY = 0.0f;
	}

	public void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled)
	{
		Opacity = 1.0f;

		// Only a CANCELLED drag restores the source window. A completed one has been re-docked
		// or re-placed by the manager, which now owns what the window looks like.
		if (!cancelled)
			return;

		if (let panelData = data as DockPanelDragData)
		{
			if (panelData.SourceWindow != null)
			{
				panelData.SourceWindow.Opacity = 1.0f;
				panelData.SourceWindow.IsInteractionEnabled = true;
			}
		}
	}

	// ---- Layout ---------------------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let headerHeight = mShowHeader ? HeaderHeight : 0.0f;

		// A docked panel FILLS the region it was given, so the content is measured within the
		// incoming constraints less the header and never unbounded: an unbounded measure here
		// would let a long list decide the dock's size.
		if ((mContent != null) && (mContent.Visibility != .Gone))
			mContent.Measure(.(constraints.MinWidth, constraints.MaxWidth,
				Max(0.0f, constraints.MinHeight - headerHeight),
				Max(0.0f, constraints.MaxHeight - headerHeight)));

		MeasuredSize = .(constraints.ConstrainWidth(0), constraints.ConstrainHeight(0));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if ((mContent == null) || (mContent.Visibility == .Gone))
			return;

		let headerHeight = mShowHeader ? HeaderHeight : 0.0f;
		let contentHeight = height - headerHeight;
		mContent.Measure(BoxConstraints.Tight(width, contentHeight));
		mContent.Layout(0, headerHeight, width, contentHeight);
	}
}
