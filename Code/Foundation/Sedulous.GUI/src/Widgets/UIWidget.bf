using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// UIWidget: a UINode with the CSS identity + layout inputs the styling engine matches on. Ported
// from eepp's UI::UIWidget: element tag, id and style classes (what selectors match), its tooltip,
// context menu, drag and drop in markup, and its accessibility overrides.

static
{
	// The states a widget's own pseudo-classes read (WidgetState): :checked, :indeterminate,
	// :read-only and :read-write, :placeholder-shown. Constants, as they are combined and kept as
	// a uint32.
	public const uint32 WidgetStateNone = 0;
	public const uint32 WidgetStateChecked = 1 << 0;
	public const uint32 WidgetStateIndeterminate = 1 << 1;
	/// The user edits its value (:read-write; else :read-only).
	public const uint32 WidgetStateEditable = 1 << 2;
	public const uint32 WidgetStatePlaceholderShown = 1 << 3;
	/// An item view's row in its selection (:selected).
	public const uint32 WidgetStateSelected = 1 << 4;
}

[GuiReflect]
class UIWidget : UINode
{
	private String mTag = new .() ~ delete _;
	private String mId = new .() ~ delete _;
	private List<String> mClasses = new .() ~ DeleteContainerAndItems!(_);
	// PositionAmongWidgets's, numbered under this arrangement of that parent's children. The
	// parent is compared, never followed.
	private Node mPositionParent = null;
	private uint32 mPositionGeneration = 0;
	private int32 mWidgetPosition = 1;
	private int32 mPositionCount = 1;
	private String mTooltip = new .() ~ delete _;
	// Its tooltip takes the pointer.
	private bool mTooltipInteractive = false;
	private String mAccessRole = new .() ~ delete _;
	private String mAccessLabel = new .() ~ delete _;
	private String mAccessLabelledBy = new .() ~ delete _;
	private String mAccessDescribedBy = new .() ~ delete _;
	private String mAccessControls = new .() ~ delete _;
	private bool mAccessHidden = false;
	private String mContextMenuId = new .() ~ delete _;
	private String mDragType = new .() ~ delete _;
	private String mDragValue = new .() ~ delete _;
	private String mDragLabel = new .() ~ delete _;
	private String mDropReason = new .() ~ delete _;
	// auto, none, block
	private uint8 mDragMode = 0;
	// The menu it opens, once found (a reference held).
	private Node mContextMenu = null ~ _?.ReleaseRef();

	public this()
	{
	}

	// === CSS identity (selector surface) ===

	public StringView Tag
	{
		get => mTag;
		set
		{
			mTag.Set(value);
			MarkStyleDirty(true); // the selectors it matches change
			Invalidate();
		}
	}

	[GuiProperty]
	public StringView Id
	{
		get => mId;
		set
		{
			mId.Set(value);
			MarkStyleDirty(true);
			Invalidate();
		}
	}

	/// Its type and, when it has one, its id ("Button #ok").
	public override void DebugName(String outText)
	{
		base.DebugName(outText);
		if (!mId.IsEmpty)
		{
			outText.Append(" #");
			outText.Append(mId);
		}
	}

	public void AddClass(StringView cls)
	{
		if ((cls.Length != 0) && !HasClass(cls))
		{
			mClasses.Add(new String(cls));
			MarkStyleDirty(true);
			Invalidate();
		}
	}

	public void RemoveClass(StringView cls)
	{
		for (int i = 0; i < mClasses.Count; i++)
		{
			if (mClasses[i] == cls)
			{
				delete mClasses[i];
				mClasses.RemoveAt(i);
				MarkStyleDirty(true);
				Invalidate();
				return;
			}
		}
	}

	public bool HasClass(StringView cls)
	{
		for (let c in mClasses)
		{
			if (c == cls)
				return true;
		}
		return false;
	}

	public void ToggleClass(StringView cls)
	{
		if (HasClass(cls))
			RemoveClass(cls);
		else
			AddClass(cls);
	}

	public int ClassCount => mClasses.Count;

	/// Its WidgetState flags; a widget with such a state reports it, and marks itself for a
	/// restyle when it changes.
	public virtual uint32 WidgetStates => WidgetStateNone;
	public Span<String> Classes => mClasses;

	/// Its 1-based place among its parent's widgets and how many there are (:nth-child and its
	/// kin). The first ask after the children change numbers every widget there at once.
	public void PositionAmongWidgets(out int32 position, out int32 count)
	{
		let parent = Parent;
		if (parent == null)
		{
			position = 1;
			count = 1;
			return;
		}
		if ((mPositionParent != parent) || (mPositionGeneration != parent.ChildrenGeneration))
		{
			int32 total = 0;
			for (int i = 0; i < parent.ChildCount; i++)
			{
				if (parent.GetChildAt(i) is UIWidget)
					++total;
			}
			int32 at = 0;
			for (int i = 0; i < parent.ChildCount; i++)
			{
				if (let w = parent.GetChildAt(i) as UIWidget)
				{
					w.mWidgetPosition = ++at;
					w.mPositionCount = total;
					w.mPositionParent = parent;
					w.mPositionGeneration = parent.ChildrenGeneration;
				}
			}
		}
		position = mWidgetPosition;
		count = mPositionCount;
	}

	// === Hover tooltip ===

	[GuiProperty("tooltip", .Translatable)]
	public StringView Tooltip
	{
		get => mTooltip;
		set => mTooltip.Set(value);
	}

	public override StringView TooltipText => mTooltip;

	[GuiProperty("tooltip-interactive")]
	public bool TooltipInteractive
	{
		get => mTooltipInteractive;
		set => mTooltipInteractive = value;
	}

	public override bool IsTooltipInteractive => mTooltipInteractive;

	// === Accessibility in markup ===
	// Over what its type and its properties say.

	/// What a screen reader takes it for, over its type's (markup's `role`; empty: its type's).
	[GuiProperty("role")]
	public StringView AccessRoleName
	{
		get => mAccessRole;
		set
		{
			mAccessRole.Set(value);
			MarkAccessDirty();
		}
	}

	/// Its name over what it shows (`aria-label`).
	[GuiProperty("aria-label", .Translatable)]
	public StringView AccessLabel
	{
		get => mAccessLabel;
		set
		{
			mAccessLabel.Set(value);
			MarkAccessDirty();
		}
	}

	/// The ids of the widgets that name it and describe it (`aria-labelledby`, `aria-describedby`;
	/// space-separated), and of those it controls (`aria-controls`).
	[GuiProperty("aria-labelledby")]
	public StringView AccessLabelledBy
	{
		get => mAccessLabelledBy;
		set
		{
			mAccessLabelledBy.Set(value);
			MarkAccessDirty();
		}
	}

	[GuiProperty("aria-describedby")]
	public StringView AccessDescribedBy
	{
		get => mAccessDescribedBy;
		set
		{
			mAccessDescribedBy.Set(value);
			MarkAccessDirty();
		}
	}

	[GuiProperty("aria-controls")]
	public StringView AccessControls
	{
		get => mAccessControls;
		set
		{
			mAccessControls.Set(value);
			MarkAccessDirty();
		}
	}

	/// Hidden from screen readers, with what it holds (`aria-hidden`): a decoration.
	[GuiProperty("aria-hidden")]
	public bool AccessHidden
	{
		get => mAccessHidden;
		set
		{
			mAccessHidden = value;
			MarkAccessDirty();
		}
	}

	// === Drag and drop in markup ===

	/// Drags as this payload type (markup's `drag-type`; empty: it does not drag).
	[GuiProperty("drag-type")]
	public StringView DragType
	{
		get => mDragType;
		set => mDragType.Set(value);
	}

	/// The payload's value and label (`drag-value`, which may be a `{{name}}`; `drag-label`, else
	/// the value).
	[GuiProperty("drag-value")]
	public StringView DragValue
	{
		get => mDragValue;
		set => mDragValue.Set(value);
	}

	[GuiProperty("drag-label")]
	public StringView DragLabel
	{
		get => mDragLabel;
		set => mDragLabel.Set(value);
	}

	/// `drag`: "auto" (it drags when it has a type, else passes the press up), "none" (it never
	/// drags; the press passes up), "block" (the walk ends here: nothing above drags from a press
	/// on it; RmlUi's property).
	[GuiProperty("drag")]
	public StringView DragModeName
	{
		get => (mDragMode == 1) ? "none" : (mDragMode == 2) ? "block" : "auto";
		set
		{
			let m = ParseUtil.Trim(value);
			mDragMode = (m == "none") ? 1 : (m == "block") ? 2 : 0;
		}
	}

	/// What a drop here says it would do (`drop-reason`), shown by the pointer while it would take
	/// one.
	[GuiProperty("drop-reason")]
	public StringView DropReason
	{
		get => mDropReason;
		set => mDropReason.Set(value);
	}

	public override bool OwnsPressDrag(Float2 local) => (mDragMode == 2) || base.OwnsPressDrag(local);

	// === Context menu ===

	/// The id of a Menu in its GUI (markup's `<Menu id="...">`) that a context menu asked for over
	/// it opens, at the pointer (markup's `context-menu`).
	[GuiProperty("context-menu")]
	public StringView ContextMenuId
	{
		get => mContextMenuId;
		set
		{
			// The style pass writes it again at every restyle: the same id keeps the menu found
			// (closed, it is out of the tree, where it could not be found again).
			if (value == mContextMenuId)
				return;
			mContextMenuId.Set(value);
			if (mContextMenu != null)
			{
				mContextMenu.ReleaseRef();
				mContextMenu = null;
			}
		}
	}

	protected override void OnContextMenu(MouseEvent e)
	{
		if (!mContextMenuId.IsEmpty && OpenContextMenu(e))
			e.Handled = true;
	}

	// Finds the menu (kept once found: open, it leaves the page for the top layer, and closed,
	// the tree) and opens it at the event's position.
	private bool OpenContextMenu(MouseEvent e)
	{
		var menu = mContextMenu as Menu;
		let root = RootNode;
		if (menu == null)
		{
			menu = NavigationDetail.FindWidgetById(root, mContextMenuId) as Menu;
			if (menu == null)
				return false;
			menu.AddRef(); // open, it leaves the page; kept here
			if (mContextMenu != null)
				mContextMenu.ReleaseRef();
			mContextMenu = menu;
		}
		menu.Open(this, root.ConvertToNodeSpace(e.Position));
		return true;
	}

	protected override bool OnDragRequested(DragRequest request)
	{
		if ((mDragMode != 0) || mDragType.IsEmpty)
			return false;
		request.Payload.Type.Set(mDragType);
		request.Payload.Value.Dispose();
		request.Payload.Value = TextVariant(mDragValue);
		request.Payload.Label.Set(mDragLabel.IsEmpty ? mDragValue : mDragLabel);
		return true;
	}

	protected override void OnDragQuery(DropQuery query)
	{
		base.OnDragQuery(query);
		if ((query.Effect == .None) && !query.Refused && TakesDropType(query.Payload.Type) && !mDropReason.IsEmpty)
		{
			query.Accept();
			query.Reason.Set(mDropReason);
		}
	}
}

/// Where markup's children land for a widget that takes them in its own way (a menu's items, a
/// tree's items): unseen and out of the tree, each handed to `adopt` as it arrives, which takes it
/// out.
[GuiReflect]
class MarkupChildHost : UIWidget
{
	private delegate void(Node node) mAdopt ~ delete _;

	/// OWNERSHIP of `adopt` transfers.
	public this(delegate void(Node node) adopt)
	{
		mAdopt = adopt;
		Displayed = false;
	}

	public override void OnChildrenChanged()
	{
		if ((mAdopt != null) && (ChildCount != 0))
			mAdopt(this);
	}
}
