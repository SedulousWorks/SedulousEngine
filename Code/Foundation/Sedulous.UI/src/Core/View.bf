using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// The base of the retained mode view hierarchy.
///
/// PARTIAL PORT. This carries View's identity, geometry, flags, tree links and coordinate
/// conversion. The style cascade, measure and arrange, invalidation, transitions and
/// everything reaching a manager through the context are still in the ledger's View.cppm and
/// UIClusterImpl.cpp, and land with the subsystems they need.
///
/// Ref counted: a parent owns its children by reference, and the back pointers here are
/// borrowed.
class View : RefCounted
{
	// ---- Identity ------------------------------------------------------------------------------

	public readonly ViewId Id = ViewId.Create();
	/// Optional, for debugging and lookup. Empty means none. Also what an `#id` selector
	/// matches.
	public String Name = new .() ~ delete _;
	public List<String> StyleClasses = new .() ~ DeleteContainerAndItems!(_);

	// ---- Layout state --------------------------------------------------------------------------

	public Float2 MeasuredSize = .Zero;
	public Rectangle Bounds = .();

	public float Width => Bounds.Width;
	public float Height => Bounds.Height;

	// ---- Visibility and interaction --------------------------------------------------------

	public Visibility Visibility = .Visible;
	public bool IsEnabled = true;
	public bool IsInteractionEnabled = true;
	public bool IsHitTestVisible = true;
	public bool IsFocusable = false;
	public bool IsTabStop = false;
	public int32 TabIndex = 0;
	public bool ClipsContent = false;
	public bool WantsArrowKeys = false;
	/// Tab normally drives focus traversal BEFORE dispatch and never reaches a view. A view
	/// that edits tab characters, such as a code editor, sets this to see Tab in OnKeyDown
	/// first; traversal stays the fallback when the view leaves the event unhandled.
	public bool WantsTabKey = false;
	public bool IsPendingDeletion = false;

	// ---- Tooltip -------------------------------------------------------------------------------

	/// Empty means no tooltip, unless the view provides its own content.
	public String TooltipText = new .() ~ delete _;
	public TooltipPlacement TooltipPlacement = .Bottom;
	/// Keeps the tooltip hit testable, so it can be hovered and clicked.
	public bool IsTooltipInteractive = false;

	// ---- Directional focus overrides. Null uses the spatial picker. ----------------------------

	public ViewId? NextFocusUp = null;
	public ViewId? NextFocusDown = null;
	public ViewId? NextFocusLeft = null;
	public ViewId? NextFocusRight = null;

	// ---- Visual --------------------------------------------------------------------------------

	public float Opacity = 1.0f;
	public ViewTransform Transform = .();
	public CursorType Cursor = .Default;

	// ---- Tree ----------------------------------------------------------------------------------

	/// BORROWED: the parent owns this view, not the other way about.
	public View Parent = null;

	protected bool mNeedsRedraw = true;

	public this() {}

	// ---- Cursor --------------------------------------------------------------------------------

	/// The cursor at a point inside this view, defaulting to the whole view's Cursor.
	///
	/// A view with internal regions wanting different pointers, such as a code editor's gutter
	/// against its text area, overrides THIS rather than writing to Cursor from hover events.
	public virtual CursorType CursorAt(Float2 localPoint) => Cursor;

	/// Walks the parent chain from this view, answering the first cursor that is not Default,
	/// each view judged at the SAME screen point.
	public CursorType EffectiveCursor(Float2 screenPoint)
	{
		var view = this;
		while (view != null)
		{
			let cursor = view.CursorAt(view.ScreenToLocal(screenPoint));
			if (cursor != .Default)
				return cursor;
			view = view.Parent;
		}
		return .Default;
	}

	// ---- Coordinates ---------------------------------------------------------------------------

	public Float2 LocalToScreen(Float2 local)
	{
		var result = local;
		var view = this;
		while (view != null)
		{
			result.X += view.Bounds.X;
			result.Y += view.Bounds.Y;
			view = view.Parent;
		}
		return result;
	}

	public Float2 ScreenToLocal(Float2 screen)
	{
		var result = screen;
		var view = this;
		while (view != null)
		{
			result.X -= view.Bounds.X;
			result.Y -= view.Bounds.Y;
			view = view.Parent;
		}
		return result;
	}

	// ---- Style classes -------------------------------------------------------------------------

	public bool HasClass(StringView name)
	{
		for (let styleClass in StyleClasses)
		{
			if (styleClass == name)
				return true;
		}
		return false;
	}

	// ---- Effective state -----------------------------------------------------------------------

	/// Enabled only if this view AND every ancestor is: disabling a panel disables everything
	/// inside it without touching the children.
	public bool IsEffectivelyEnabled()
	{
		var view = this;
		while (view != null)
		{
			if (!view.IsEnabled)
				return false;
			view = view.Parent;
		}
		return true;
	}

	// ---- Draw ----------------------------------------------------------------------------------

	public bool NeedsRedraw => mNeedsRedraw;
	public void ClearRedrawFlag() => mNeedsRedraw = false;

	public virtual float GetBaseline() => -1.0f;
	public virtual void OnDraw(UIDrawContext ctx) {}

	// ---- Gamepad and directional activation ----------------------------------------------------

	/// Activated, by a gamepad's confirm button or Return on the focused view.
	public virtual void OnActivate() {}

	/// Cancelled, by a gamepad's back button or Escape. BUBBLES by default, so a dialog can
	/// answer for a control inside it that does not care.
	public virtual void OnCancel()
	{
		if (Parent != null)
			Parent.OnCancel();
	}

	// ---- Capability queries --------------------------------------------------------------------
	// A view says what it can do by overriding these to answer itself, which is how the tree is
	// searched without a downcast at every level.

	public virtual IAcceleratorHandler AsAcceleratorHandler() => null;
	public virtual ITooltipProvider AsTooltipProvider() => null;
	public virtual IDragSource AsDragSource() => null;
	public virtual IDropTarget AsDropTarget() => null;

	/// Whether this view wants platform text input while it holds focus. A text editing
	/// control overrides this to true, and the shell bridge starts and stops the window's
	/// text input accordingly.
	public virtual bool WantsTextInput() => false;
}
