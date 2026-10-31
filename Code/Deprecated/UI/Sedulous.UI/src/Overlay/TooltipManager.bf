using Sedulous.Core;

namespace Sedulous.UI;

/// Decides WHEN a tooltip appears and where, and owns the one reusable view it appears in.
///
/// Ticked by the context each frame. The delays are the substance: a tooltip that appeared
/// instantly would flicker across a toolbar, and one that never left would sit over the work.
class TooltipManager
{
	/// BORROWED: the context owns this.
	private UIContext mContext;
	/// OWNED, and reused for every tooltip.
	private TooltipView mTooltipView ~ _?.ReleaseRef();

	private ViewId mHoverTarget = .();
	private float mHoverTime = 0.0f;
	private float mShowTime = 0.0f;
	private bool mShowing = false;
	private bool mInteractive = false;

	/// How long the pointer must rest before the tooltip appears.
	public float ShowDelay = 0.5f;
	/// How long it stays before hiding itself.
	public float AutoHideDelay = 5.0f;

	public this(UIContext context)
	{
		mContext = context;
		mTooltipView = new TooltipView();
	}

	public ~this()
	{
		// The popup layer may already be gone. The view was shown with ownsView false, so
		// nothing else will free it; clearing the back pointers keeps the release below from
		// touching freed objects.
		if (mTooltipView != null)
		{
			mTooltipView.Parent = null;
			mTooltipView.Context = null;
		}
	}

	public bool IsShowing => mShowing;

	// ---- Input hooks ----------------------------------------------------------------------------

	/// The hover moved. Restarts the timer unless it is the SAME owner.
	public void OnHoverChanged(View newTarget)
	{
		// Hovering the tooltip itself never dismisses it, checked on the RAW view: the
		// tooltip's own content carries no tooltip text of its own.
		if (mShowing && (newTarget != null) && IsTooltipOrDescendant(newTarget))
			return;

		let owner = ResolveTooltipOwner(newTarget);
		let newId = (owner != null) ? owner.Id : ViewId.Invalid;
		if (newId == mHoverTarget)
			return;

		Hide();
		mHoverTarget = newId;
		mHoverTime = 0;
	}

	/// A click hides the tooltip, unless it is an INTERACTIVE one being clicked.
	public void OnMouseDown()
	{
		if (mShowing && mInteractive)
		{
			let hovered = mContext.GetViewById(mContext.GetInputManager().HoveredId);
			if ((hovered != null) && IsTooltipOrDescendant(hovered))
				return;
		}

		Hide();
	}

	public void OnViewDeleted(View view)
	{
		if (mHoverTarget == view.Id)
			mHoverTarget = ViewId.Invalid;
	}

	/// Runs the two clocks: the one before showing, and the one before hiding again.
	public void Update(float deltaTime)
	{
		if (!mHoverTarget.IsValid)
			return;

		if (!mShowing)
		{
			mHoverTime += deltaTime;
			if (mHoverTime < ShowDelay)
				return;

			let target = mContext.GetViewById(mHoverTarget);
			if (target != null)
				Show(target);
			else
				mHoverTarget = ViewId.Invalid; // it went away while we were waiting
			return;
		}

		mShowTime += deltaTime;
		if (mShowTime >= AutoHideDelay)
			Hide();
	}

	// ---- Showing --------------------------------------------------------------------------------

	private void Show(View target)
	{
		if (!BuildContent(target))
			return;

		mInteractive = target.IsTooltipInteractive;
		// Hit test visibility is SELF only, which the tool float layers rely on, so on its own
		// it still left the tooltip's CONTENT standing between the pointer and the thing being
		// described. Interaction takes out the whole subtree: an ordinary tooltip is
		// pass-through, an interactive one is a real target.
		mTooltipView.IsHitTestVisible = mInteractive;
		mTooltipView.IsInteractionEnabled = mInteractive;

		let root = mContext.ActiveInputRoot;
		if (root == null)
			return;

		let popupLayer = root.GetPopupLayer();

		// Shown at the origin FIRST so it attaches to the context, which it must be to measure.
		// Not dismissable, not modal, not owned, and taking NO focus: a tooltip appearing mid
		// typing must never disturb the focused view or its completion popup.
		mTooltipView.AddRef(); // ShowPopup consumes one; the manager keeps its own
		popupLayer.ShowPopup(mTooltipView, null, 0, 0, false, false, false, false);
		mShowing = true;
		mShowTime = 0;

		let logical = root.LogicalSize;
		mTooltipView.Measure(BoxConstraints.Loose(logical.X, logical.Y));
		let size = mTooltipView.MeasuredSize;
		let screen = Rectangle(0, 0, logical.X, logical.Y);

		var targetScreen = target.LocalToScreen(.(0, 0));
		var targetWidth = target.Width;
		var targetHeight = target.Height;
		var placement = target.TooltipPlacement;

		// Pointer placement anchors a one by one target at the MOUSE instead, which is what a
		// large view showing a different tooltip per region needs.
		if (placement == .Pointer)
		{
			let input = mContext.GetInputManager();
			targetScreen = .(input.MouseX + 12.0f, input.MouseY + 6.0f);
			targetWidth = 1.0f;
			targetHeight = 1.0f;
			placement = .Bottom; // below and right of the pointer, then clamped
		}

		let position = PositionTooltip(placement, targetScreen.X, targetScreen.Y, targetWidth,
			targetHeight, size, screen);
		popupLayer.UpdatePopupPosition(mTooltipView, position.X, position.Y);
	}

	/// Fills the tooltip with its content. False when there is nothing to show, which is how a
	/// provider says "not here, not now".
	///
	/// A PROVIDER is asked first, so a view that builds its own content is never reduced to its
	/// plain text; a view with only TooltipText gets a label.
	private bool BuildContent(View target)
	{
		if (let provider = target.AsTooltipProvider())
		{
			let content = provider.CreateTooltipContent();
			if (content == null)
				return false;

			mTooltipView.SetContent(content);
			return true;
		}

		if (target.TooltipText.IsEmpty)
			return false;

		mTooltipView.SetContent(new Label(target.TooltipText));
		return true;
	}

	private void Hide()
	{
		if (mShowing)
		{
			let root = mContext.ActiveInputRoot;
			if (root != null)
				root.GetPopupLayer().ClosePopup(mTooltipView);
			mShowing = false;
		}

		mHoverTime = 0;
	}

	// ---- Helpers --------------------------------------------------------------------------------

	/// The tooltip OWNER for a hovered view: itself, or the nearest ancestor with tooltip
	/// content.
	///
	/// Hit testing answers the LEAF under the cursor, so a container carrying one tooltip for
	/// all its children would otherwise never show it. Resolving to the owner also keeps the
	/// timer alive while the pointer moves between children of the same owner.
	private static View ResolveTooltipOwner(View view)
	{
		var current = view;
		while (current != null)
		{
			if ((current.AsTooltipProvider() != null) || !current.TooltipText.IsEmpty)
				return current;
			current = current.Parent;
		}
		return null;
	}

	private bool IsTooltipOrDescendant(View view)
	{
		var current = view;
		while (current != null)
		{
			if (current == mTooltipView)
				return true;
			current = current.Parent;
		}
		return false;
	}

	/// Places the tooltip beside its target, FLIPPING to the other side when it would not fit,
	/// and clamping to the screen as a last resort.
	private static Float2 PositionTooltip(TooltipPlacement placement, float targetX, float targetY,
		float targetWidth, float targetHeight, Float2 size, Rectangle screen)
	{
		var x = 0.0f;
		var y = 0.0f;

		switch (placement)
		{
		case .Pointer, .Bottom:
			x = targetX;
			y = targetY + targetHeight;
			if ((y + size.Y) > screen.Height)
				y = targetY - size.Y;
		case .Top:
			x = targetX;
			y = targetY - size.Y;
			if (y < screen.Y)
				y = targetY + targetHeight;
		case .Right:
			x = targetX + targetWidth;
			y = targetY;
			if ((x + size.X) > screen.Width)
				x = targetX - size.X;
		case .Left:
			x = targetX - size.X;
			y = targetY;
			if (x < screen.X)
				x = targetX + targetWidth;
		}

		x = Clamp(x, screen.X, Max(screen.X, screen.X + screen.Width - size.X));
		y = Clamp(y, screen.Y, Max(screen.Y, screen.Y + screen.Height - size.Y));
		return .(x, y);
	}
}
