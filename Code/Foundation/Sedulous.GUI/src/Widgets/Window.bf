using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.GUI;

// Window: a movable panel with a title bar and a content area. Modeled on eepp's UIWindow (role
// only). Dragging the title bar moves the window (or, handed over, starts a drag source's drag);
// with `resizable`, dragging the bottom-right grip resizes it (clamped to a minimum); either
// reported once the press lets go; with `closable`, a close button in the title bar closes it.
// Pressing anywhere on the title raises the window to the front. It arranges its parts itself
// (title bar, content, grip), its look the theme's (window::title, ::grip, `window titlebar >
// close`). Movement uses incremental world-space cursor deltas via an internal DragHandle that
// follows the Slider/ScrollBar capture discipline (its own dragging flag, so a drag that leaves
// the handle keeps tracking). Nested parent transforms are not accounted for (deltas are treated
// as parent-local) - fine for top-level windows under an untransformed root.

/// A widget that reports incremental world-space cursor deltas while dragged. Internal to Window
/// (title bar + resize grip), but generally reusable.
class DragHandle : UIWidget
{
	private delegate void(Float2 delta) mOnDrag ~ delete _;
	private delegate void() mOnPressed ~ delete _;
	private delegate void() mOnReleased ~ delete _;
	private bool mDragging = false;
	private bool mMoved = false;
	private bool mDragsItself = true;
	private Float2 mLast = .(0.0f, 0.0f);

	/// Each incremental cursor delta. OWNERSHIP of `callback` transfers.
	public void SetOnDrag(delegate void(Float2 delta) callback)
	{
		delete mOnDrag;
		mOnDrag = callback;
	}

	/// A press of any button on it. OWNERSHIP of `callback` transfers.
	public void SetOnPressed(delegate void() callback)
	{
		delete mOnPressed;
		mOnPressed = callback;
	}

	/// The press that dragged it let go (after OnDrag moved something). OWNERSHIP of `callback`
	/// transfers.
	public void SetOnReleased(delegate void() callback)
	{
		delete mOnReleased;
		mOnReleased = callback;
	}

	/// Whether its press drags it (the default); off, its press is a drag source's (its own,
	/// SetDragSource, or an ancestor's): what a floating dock window's title bar does.
	public bool DragsItself
	{
		get => mDragsItself;
		set => mDragsItself = value;
	}

	// A press moves or resizes the window: a drag from what holds it is not offered.
	public override bool OwnsPressDrag(Float2 local) => mDragsItself;

	protected override void OnMouseDown(MouseEvent e)
	{
		e.Handled = true;
		if (mOnPressed != null)
			mOnPressed(); // raise on any button
		if ((e.Button != .Left) || !mDragsItself)
			return; // but only the left button drags
		mDragging = true;
		mMoved = false;
		mLast = e.Position;
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		if (!mDragging)
			return;
		let delta = Float2(e.Position.X - mLast.X, e.Position.Y - mLast.Y);
		mLast = e.Position;
		mMoved = mMoved || (delta.X != 0.0f) || (delta.Y != 0.0f);
		if (mOnDrag != null)
			mOnDrag(delta);
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		LetGo();
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		LetGo();
	}

	private void LetGo()
	{
		let moved = mDragging && mMoved;
		mDragging = false;
		mMoved = false;
		if (moved && (mOnReleased != null))
			mOnReleased();
	}
}

/// A window's close button (`window titlebar > close`): a cross in its text colour.
class WindowCloseButton : ButtonBase
{
	public this()
	{
		Tag = "close";
		TabFocusable = false; // Escape closes from the keys
	}

	public override Float2 MeasureContent(Float2 available) => .(10.0f, 10.0f);

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		let area = ContentBounds;
		let r = Math.Min(area.Width, area.Height) * 0.5f;
		let cx = area.X + area.Width * 0.5f;
		let cy = area.Y + area.Height * 0.5f;
		let cross = scope PathBuilder();
		cross.MoveTo(cx - r, cy - r);
		cross.LineTo(cx + r, cy + r);
		cross.MoveTo(cx + r, cy - r);
		cross.LineTo(cx - r, cy + r);
		let path = cross.ToPath();
		ctx.VG.StrokePath(path, TextColor, StrokeStyle(1.5f, .Round, .Round));
		delete path;
	}

	// Its press is its own: the title bar under it does not start a move.
	protected override void OnMouseDown(MouseEvent e)
	{
		if (e.Button == .Left)
			e.Handled = true;
	}
}

/// A window's resize grip: diagonal lines in the corner, in window::grip's colour.
class WindowGrip : DragHandle
{
	private Color mColor = .(0.55f, 0.59f, 0.66f, 1.0f);

	public this()
	{
		Tag = "grip";
	}

	public Color LineColor
	{
		get => mColor;
		set
		{
			mColor = value;
			Invalidate();
		}
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		// Its lines in the corner it sits in: bottom right, bottom left in right to left.
		let b = LocalBounds;
		let rtl = IsRightToLeft;
		let lines = scope PathBuilder();
		for (float k = 4.0f; k <= 12.0f; k += 4.0f)
		{
			lines.MoveTo(Rect.MirroredX(b.X + b.Width - 3.0f, b, rtl), b.Y + b.Height - 3.0f - k);
			lines.LineTo(Rect.MirroredX(b.X + b.Width - 3.0f - k, b, rtl), b.Y + b.Height - 3.0f);
		}
		let path = lines.ToPath();
		ctx.VG.StrokePath(path, mColor, StrokeStyle(1.2f, .Round, .Round));
		delete path;
	}
}

[GuiReflect(true)]
class Window : UIWidget
{
	private DragHandle mTitleBar ~ _.ReleaseRef();
	private Label mTitle ~ _.ReleaseRef();
	private WindowCloseButton mCloseButton ~ _.ReleaseRef();
	private bool mClosable = true;
	private bool mResizable = true;
	private UIWidget mContentHost ~ _.ReleaseRef();
	private WindowGrip mResizeGrip ~ _.ReleaseRef();
	private delegate void() mOnClose ~ delete _;
	private delegate void() mOnUserArranged ~ delete _;
	private bool mOpen = false;
	private bool mModal = false;
	// Its `back` handler while open modal.
	private uint32 mBackHandler = 0;
	private Float2 mMinSize = .(120.0f, 60.0f);
	/// The height follows the content (FitsHeightToContent).
	private bool mFitsHeight = false;
	private float mTitleBarHeight = 28.0f;
	private float mGripSize = 14.0f;
	private Color mBodyColor = .(0.16f, 0.17f, 0.21f, 1.0f);
	private Color mTitleColor = .(0.24f, 0.28f, 0.36f, 1.0f);
	private Color mGripColor = .(0.40f, 0.44f, 0.52f, 1.0f);

	public this()
	{
		Tag = "window";
		AccessRoleName = "window"; // what a screen reader takes it for
		ClipChildren = true;
		SetBox(FilledBox(mBodyColor, scope NodeBox())); // its own box, which a sheet's (rounded, bordered, shadowed) replaces

		mTitleBar = new DragHandle();
		mTitleBar.Tag = "titlebar";
		using (StyleWriteScope(mTitleBar))
		{
			mTitleBar.EditLayoutStyle(scope (st) =>
				{
					st.Direction = .Row;
					st.AlignItems = .Center;
					st.ColumnGap = 6.0f;
				});
			// The same at both ends: right to left, the bar is the mirror of left to right.
			mTitleBar.Padding = .(8.0f, 0.0f, 8.0f, 0.0f);
		}
		mTitleBar.SetOnDrag(new (delta) => { Position = .(Position.X + delta.X, Position.Y + delta.Y); });
		mTitleBar.SetOnPressed(new () => { ToFront(); });
		mTitleBar.SetOnReleased(new () => { UserArranged(); });
		AddChild(mTitleBar);

		mTitle = new Label();
		using (StyleWriteScope(mTitle)) // its own values, which a sheet returns to
		{
			mTitle.SetTextAlignment(.Start, .Middle);
			mTitle.HitTestVisible = false; // clicks fall through to the draggable title bar
			mTitle.EditLayoutStyle(scope (st) => { st.Grow = 1.0f; });
		}
		mTitleBar.AddChild(mTitle);
		mCloseButton = new WindowCloseButton();
		mCloseButton.SetOnClick(new () => { RequestClose(); });
		mTitleBar.AddChild(mCloseButton);

		mContentHost = new UIWidget();
		mContentHost.ClipChildren = true;
		AddChild(mContentHost);

		mResizeGrip = new WindowGrip();
		mResizeGrip.SetOnDrag(new (delta) => { ResizeBy(delta); });
		mResizeGrip.SetOnPressed(new () => { ToFront(); });
		mResizeGrip.SetOnReleased(new () => { UserArranged(); });
		mResizeGrip.Cursor = .NwseResize;
		AddChild(mResizeGrip);
		RefreshPartNodes();
	}

	/// The area for window content (add your widgets here).
	public Node Content => mContentHost;
	// Markup's children are its content.
	public override Node ChildHost => mContentHost;

	[GuiProperty("title", .None, "name")]
	public StringView Title
	{
		get => mTitle.Text;
		set => mTitle.Text = value;
	}

	public void SetMinSize(Float2 size)
	{
		mMinSize = size;
	}

	/// Whether its height follows its content: at each layout the height becomes what the content
	/// asks for at the window's width, under the title bar, the window's middle kept where it was.
	/// For a dialog whose content changes while it is open (a stage shown, a line that wraps); the
	/// resize grip then changes only the width.
	public bool FitsHeightToContent
	{
		get => mFitsHeight;
		set
		{
			mFitsHeight = value;
			RequestLayout();
		}
	}

	/// Its close button shows (a click on it, like Escape on a dialog, closes it).
	[GuiProperty("closable")]
	public bool Closable
	{
		get => mClosable;
		set
		{
			mClosable = value;
			mCloseButton.Displayed = value;
		}
	}

	/// Its grip shows and resizes it.
	[GuiProperty("resizable")]
	public bool Resizable
	{
		get => mResizable;
		set
		{
			mResizable = value;
			mResizeGrip.Displayed = value;
		}
	}

	/// Asked to close (its close button, or `back` while it is open modal): a window closes; a
	/// dialog answers as its cancel does.
	public virtual void RequestClose()
	{
		Close();
	}

	/// Whether `back` (Escape, the pad's East) asks it to close while it is open modal: when it
	/// may be closed.
	public virtual bool AnswersBack => mClosable;

	public float TitleBarHeight
	{
		get => mTitleBarHeight;
		set
		{
			mTitleBarHeight = Math.Max(1.0f, value);
			Relayout();
		}
	}

	public void SetBodyColor(Color color)
	{
		mBodyColor = color;
		if (!IsBoxFromStyle)
			SetBox(FilledBox(color, scope NodeBox()));
	}

	public void SetTitleColor(Color color)
	{
		mTitleColor = color;
		RefreshPartNodes();
	}

	/// Called when the window is closed via Close(). OWNERSHIP of `callback` transfers.
	public void SetOnClose(delegate void() callback)
	{
		delete mOnClose;
		mOnClose = callback;
	}

	/// The user moved it by its title bar or resized it by its grip: called once the press lets
	/// go (not each move), with its place and size as they are then. OWNERSHIP of `callback`
	/// transfers.
	public void SetOnUserArranged(delegate void() callback)
	{
		delete mOnUserArranged;
		mOnUserArranged = callback;
	}

	/// Its title bar (what dragging it moves the window; DragHandle.DragsItself hands the press to
	/// a drag source instead).
	public DragHandle TitleBar => mTitleBar;

	/// Shows it centred in `owner` as a MODAL window: a manual, modal popup of `owner`, so
	/// everything below it is inert (pointer, keys, bindings) until Close(), its `::backdrop`
	/// part dims the root behind it, Tab stays within, focus moves to its first focusable child
	/// and comes back when it closes. Popups opened inside it (a combo box's list) stack above it.
	public void OpenModal(Node owner)
	{
		OpenInternal(owner, true);
	}

	/// Shows it centred in `root` as a normal (non-blocking) top-level window.
	public void Open(Node root)
	{
		OpenInternal(root, false);
	}

	/// Removes the window (a modal one through the popup stack, which gives focus back), and calls
	/// the close callback. A window placed in a tree as a child, never opened, closes the same
	/// way: its close button works however it came to be shown.
	public new void Close()
	{
		if (!mOpen && (Parent == null))
			return;
		let dispatcher = EventDispatcher;
		if (mModal && (dispatcher != null) && dispatcher.IsPopupOpen(this))
		{
			dispatcher.ClosePopup(this); // its OnClosed finishes
			return;
		}
		AddRef(); // the tree may hold its only reference (a script's window)
		RemoveFromParent();
		Closed();
		OnWindowGone();
		ReleaseRef();
	}

	public bool IsOpen => mOpen;

	/// Opens it where it is, over what holds it (a window game code added to a page); false in none.
	public bool OpenInPlace()
	{
		let parent = Parent;
		if (parent == null)
			return false;
		Displayed = true; // one kept out of the layout until opened
		Open(parent);
		return true;
	}

	/// Opens it as a modal window over the GUI it is in; false in none.
	public bool OpenModalOver()
	{
		let root = RootNode;
		if ((root == null) || (root == this))
			return false;
		OpenModal(root);
		return true;
	}

	public bool IsModal => mModal;

	// Theming parts: window::title (header bar) / ::grip (resize handle).
	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("title");
		outParts.Add("grip");
	}

	// Its title bar and grip are nodes of their own: window::title and ::grip give them their
	// boxes, over their own colours.
	protected override void OnPartStyleChange(StringView part)
	{
		if ((part == "title") || (part == "grip"))
			RefreshPartNodes();
	}

	/// It closed: IsOpen is false, though a modal one may still be playing its exit.
	protected virtual void OnWindowClosed()
	{
	}

	/// It was to open modal and its dispatcher refused it (SetModalInterceptor): it answers as
	/// closing it would, without having shown. A dialog answers as its cancel.
	protected virtual void OnModalRefused()
	{
		if (mOnClose != null)
			mOnClose();
		SendEvent(scope Event(.Close, this));
	}

	/// It has gone: out of the top layer, after its exit (a dialog written in a page goes back
	/// there now). Not when it opens again before its exit ends.
	protected virtual void OnWindowGone()
	{
	}

	public override void OnSizeChange()
	{
		Relayout();
	}

	// Its parts at their places: the title bar across the top, the content under it, the grip in
	// the corner. In the layout pass, where the content's sheet has applied, as MessageBox fits its
	// message.
	public override void OnLayout()
	{
		if (mFitsHeight)
			FitHeight();
		Relayout();
	}

	// The height the content asks for at this width, under the title bar, about the same middle.
	private void FitHeight()
	{
		let size = Size;
		let across = LayoutConstraints(.(size.X, 0.0f), .(size.X, cUnbounded), .(size.X, -1.0f), true, false);
		let height = mTitleBarHeight + mContentHost.Measure(across).Y;
		if (Math.Abs(height - size.Y) <= 0.5f)
			return;
		using (StyleWriteScope(this))
		{
			Position = .(Position.X, Position.Y + (size.Y - height) * 0.5f);
			Size = .(size.X, height);
		}
	}

	// Its title takes its font (a sheet's inheritance gives the same).
	protected override void OnTextStyleChange()
	{
		ShareTextStyle(mTitle, false);
	}

	// The title bar's and the grip's boxes: their colours with window::title's and ::grip's over
	// them.
	private void RefreshPartNodes()
	{
		let title = GetPartStyle("title");
		let grip = GetPartStyle("grip");
		let own = FilledBox(mTitleColor, scope NodeBox());
		title.Over(own);
		mTitleBar.SetBox(own, false);
		mResizeGrip.LineColor = grip.HasBackground ? grip.Box.BackgroundColor : mGripColor; // drawn as lines
		using (StyleWriteScope(mTitleBar))
		{
			mTitleBar.Alpha = title.Opacity;
		}
		using (StyleWriteScope(mResizeGrip))
		{
			mResizeGrip.Alpha = grip.Opacity;
		}
	}

	private void OpenInternal(Node owner, bool modal)
	{
		// Not inside itself or what it holds: the tree would loop.
		for (var n = owner; n != null; n = n.Parent)
		{
			if (n == this)
				return;
		}
		if (mOpen)
			return;
		let dispatcher = owner.EventDispatcher;
		if (modal && (dispatcher != null))
		{
			if (!dispatcher.AllowsModal(this))
			{
				OnModalRefused(); // never shown: answered as its cancel would answer
				return;
			}
			mModal = true;
			mOpen = true;
			CenterIn(owner.RootNode); // in the root's space
			let options = new PopupOptions();
			options.Kind = .Manual;
			options.Modal = true;
			options.TakesFocus = true;
			options.OnClosed = new (reason) => { Closed(); };
			// Closed, it plays the sheet's exit (a dialog fades out) before it goes.
			options.LeavesOnClose = true;
			options.OnGone = new () => { OnWindowGone(); };
			// Back asks it to close, while it is open (under it is inert, so nothing else would
			// hear it).
			if (AnswersBack)
				mBackHandler = OnCommand(cBackCommand, new (command) => { RequestClose(); });
			dispatcher.OpenPopup(owner, this, options);
			return;
		}
		mModal = false;
		owner.AddChild(this);
		CenterIn(owner);
		ToFront();
		mOpen = true;
	}

	private void UserArranged()
	{
		if (mOnUserArranged != null)
			mOnUserArranged();
	}

	private void Closed()
	{
		mOpen = false;
		mModal = false;
		if (mBackHandler != 0)
			RemoveCommandHandler(mBackHandler);
		mBackHandler = 0;
		OnWindowClosed();
		if (mOnClose != null)
			mOnClose();
		SendEvent(scope Event(.Close, this)); // a script's on("close")
	}

	private void CenterIn(Node root)
	{
		let r = root.Size;
		let s = Size;
		Position = .((r.X - s.X) * 0.5f, (r.Y - s.Y) * 0.5f);
	}

	// From its grip's corner: in right to left the grip is at its bottom left, so the left edge
	// follows the pointer and the right stays.
	private void ResizeBy(Float2 delta)
	{
		let s = Size;
		let rtl = IsRightToLeft;
		let width = Math.Max(mMinSize.X, s.X + (rtl ? -delta.X : delta.X));
		if (rtl && (width != s.X))
			Position = .(Position.X + s.X - width, Position.Y);
		Size = .(width, Math.Max(mMinSize.Y, s.Y + delta.Y));
	}

	private void Relayout()
	{
		let s = Size;
		mTitleBar.Arrange(.(0.0f, 0.0f, s.X, mTitleBarHeight));
		mContentHost.Arrange(.(0.0f, mTitleBarHeight, s.X, Math.Max(0.0f, s.Y - mTitleBarHeight)));
		let rtl = IsRightToLeft;
		mResizeGrip.Arrange(Rect.MirroredIn(.(s.X - mGripSize, s.Y - mGripSize, mGripSize, mGripSize), .(0.0f, 0.0f, s.X, s.Y), rtl));
		// Its cursor the way its corner resizes: bottom right, or bottom left right to left.
		mResizeGrip.Cursor = rtl ? .NeswResize : .NwseResize;
		if (GetChildIndex(mResizeGrip) + 1 != ChildCount)
			mResizeGrip.ToFront(); // over the content
	}
}
