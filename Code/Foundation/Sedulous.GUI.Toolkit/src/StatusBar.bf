using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The status bar: items registered by id in a start zone and an end zone (zed and Zero register
// theirs; the start zone takes what is left, so the end zone's items keep their place), ordered
// within their zone, and a message at the start of the start zone, held until replaced or for so
// many seconds on the GUI's clock. An item with a title can be hidden: the bar's context menu lists
// them as checked rows, and an application hears each change (to keep it with its settings).

/// Where on the bar an item goes.
enum StatusZone : uint8
{
	/// After the message, taking what is left.
	Start,
	/// At the bar's end.
	End,
}

/// One item of a status bar: what it shows is its children.
[GuiReflect(true)]
class StatusItem : UIWidget
{
	private StatusZone mZone = .Start;
	private String mTitle = new .() ~ delete _;
	// The bar it was added to, which holds it.
	private Sedulous.GUI.StatusBar mBar = null;

	public this()
	{
		Tag = "statusitem";
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Row;
					s.AlignItems = .Center;
					s.ColumnGap = 4.0f;
					s.Shrink = 0.0f;
				});
		}
	}

	/// Its zone (`zone`: start or end).
	public StatusZone Zone
	{
		get => mZone;
		set
		{
			mZone = value;
			Rehome();
		}
	}

	[GuiProperty("zone")]
	public StringView ZoneName
	{
		get => (mZone == .End) ? "end" : "start";
		set => Zone = (ParseUtil.Trim(value) == "end") ? .End : .Start;
	}

	/// Its place in its zone: lower first, ties in the order they came (the layout's `order`).
	public int32 Order
	{
		get => LayoutStyle.Order;
		set
		{
			let order = value;
			EditLayoutStyle(scope (s) => { s.Order = order; });
		}
	}

	/// What the bar's menu calls it (`title`); with none it cannot be hidden from there.
	[GuiProperty("title", .Translatable)]
	public StringView Title
	{
		get => mTitle;
		set => mTitle.Set(value);
	}

	private void Rehome()
	{
		if ((mBar != null) && (Parent != null))
			mBar.[Friend]Place(this);
	}
}

[GuiReflect(true)]
class StatusBar : UIWidget
{
	private Panel mStart ~ _.ReleaseRef();
	private Panel mEnd ~ _.ReleaseRef();
	private Label mMessage ~ _.ReleaseRef();
	private Sedulous.GUI.Menu mMenu ~ _?.ReleaseRef();
	private MarkupChildHost mMarkupHost ~ _?.ReleaseRef();
	private delegate void(StringView id, bool shown) mOnShownChanged ~ delete _;
	private uint32 mMessageId = 0;
	// What is left of the timed message's seconds.
	private float mMessageLeft = 0.0f;

	public this()
	{
		Tag = "statusbar";
		AccessRoleName = "group"; // the core has no status role yet
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Row;
					s.AlignItems = .Center;
					s.ColumnGap = 12.0f;
				});
			Padding = Thickness(8.0f, 2.0f, 8.0f, 2.0f);
		}
		mStart = MakeZone("start");
		mStart.EditLayoutStyle(scope (s) =>
			{
				s.Grow = 1.0f;
				s.Shrink = 1.0f;
				s.MinWidth = LayoutLength.Px(0.0f);
				s.OverflowX = .Hidden; // a long message gives way to the end zone
			});
		mEnd = MakeZone("end");
		mMessage = new Label();
		mMessage.AddClass("message");
		mMessage.Displayed = false;
		mMessage.EditLayoutStyle(scope (s) =>
			{
				s.Shrink = 1.0f;
				s.MinWidth = LayoutLength.Px(0.0f);
				s.Order = -1000000; // before every item
			});
		mStart.AddChild(mMessage);
	}

	/// Adds `item` to its zone, in its order. Its id (Id) is what the bar knows it by. The bar takes
	/// a reference of its own: the caller keeps its.
	public void AddItem(StatusItem item)
	{
		item.[Friend]mBar = this;
		Place(item);
	}

	/// Takes the item `id` off the bar; false when there is none.
	public bool RemoveItem(StringView id)
	{
		let item = FindItem(id);
		if (item == null)
			return false;
		item.[Friend]mBar = null;
		item.RemoveFromParent();
		return true;
	}

	/// The item `id`, or null.
	public StatusItem FindItem(StringView id)
	{
		Node[2] zones = .(mStart, mEnd);
		for (let zone in zones)
		{
			for (int i = 0; i < zone.ChildCount; ++i)
			{
				if (let item = zone.GetChildAt(i) as StatusItem)
				{
					if (item.Id == id)
						return item;
				}
			}
		}
		return null;
	}

	/// The items of `zone`, in order, appended to `outItems`.
	public void GetItems(StatusZone zone, List<StatusItem> outItems)
	{
		let first = outItems.Count;
		Node host = (zone == .End) ? mEnd : mStart;
		for (int i = 0; i < host.ChildCount; ++i)
		{
			if (let item = host.GetChildAt(i) as StatusItem)
			{
				var at = outItems.Count;
				while ((at > first) && (outItems[at - 1].Order > item.Order))
					--at;
				outItems.Insert(at, item);
			}
		}
	}

	/// Shows or hides the item `id` (what the bar's menu does); false when there is none.
	public bool SetItemShown(StringView id, bool shown)
	{
		let item = FindItem(id);
		if (item == null)
			return false;
		if (item.Displayed == shown)
			return true;
		item.Displayed = shown;
		if (mOnShownChanged != null)
			mOnShownChanged(id, shown);
		return true;
	}

	public bool IsItemShown(StringView id)
	{
		let item = FindItem(id);
		return (item != null) && item.Displayed;
	}

	/// Told when the user (or SetItemShown) shows or hides an item, to keep it with the settings.
	/// OWNERSHIP of `changed` transfers.
	public void SetOnItemShownChanged(delegate void(StringView id, bool shown) changed)
	{
		delete mOnShownChanged;
		mOnShownChanged = changed;
	}

	/// Shows `text` at the start: until another replaces it or it is cleared (`seconds` 0), or for
	/// `seconds` on the GUI's clock.
	public void ShowMessage(StringView text, float seconds = 0.0f)
	{
		++mMessageId;
		mMessage.Text = text;
		mMessage.Displayed = text.Length != 0;
		if ((seconds <= 0.0f) || (text.Length == 0))
			return;
		let shown = mMessageId;
		mMessageLeft = seconds;
		let tick = new TickAction(new (elapsed) =>
			{
				if (mMessageId != shown)
					return false; // replaced: its own time counts now
				mMessageLeft -= (float)elapsed.TotalSeconds;
				if (mMessageLeft > 0.0f)
					return true;
				ClearMessage();
				return false;
			});
		RunAction(tick);
		tick.ReleaseRef();
	}

	public void ClearMessage() => ShowMessage(default);

	/// The message shown now (empty: none).
	public StringView Message => mMessage.Displayed ? mMessage.Text : default;
	public Label MessagePart => mMessage;

	/// The menu of the items that can be hidden, while it is open.
	public Sedulous.GUI.Menu ItemsMenu => ((mMenu != null) && mMenu.IsOpen) ? mMenu : null;

	/// Lists the items with a title, checked while they show; picking one shows or hides it. Opens
	/// at `position` (in this GUI's root); false when no item can be hidden.
	public bool OpenItemsMenu(Float2 position)
	{
		if (mMenu != null)
			mMenu.ReleaseRef();
		mMenu = new Sedulous.GUI.Menu();
		ShareTextStyle(mMenu, false);
		mMenu.SetAutoWidth(true);
		bool any = false;
		StatusZone[2] zones = .(.Start, .End);
		let items = scope List<StatusItem>();
		for (let zone in zones)
		{
			items.Clear();
			GetItems(zone, items);
			for (let item in items)
			{
				if (item.Title.Length == 0)
					continue;
				let id = new String(item.Id);
				mMenu.AddCheckItem(item.Title, item.Displayed, new [=this, =id] (shown) => { SetItemShown(id, shown); } ~ delete id);
				any = true;
			}
		}
		if (!any)
			return false;
		mMenu.Open(this, position);
		return true;
	}

	/// Markup's children are its items (StatusItem), each placed as it arrives.
	public override Node ChildHost
	{
		get
		{
			if (mMarkupHost == null)
			{
				mMarkupHost = new MarkupChildHost(new (host) =>
					{
						while (host.ChildCount != 0)
						{
							let child = host.GetChildAt(0);
							child.AddRef(); // held across its move
							host.RemoveChild(child);
							if (let item = child as StatusItem)
								AddItem(item);
							child.ReleaseRef();
						}
					});
				AddChild(mMarkupHost);
			}
			return mMarkupHost;
		}
	}

	protected override void OnContextMenu(MouseEvent e)
	{
		let top = RootNode;
		if ((top != null) && OpenItemsMenu(top.ConvertToNodeSpace(e.Position)))
			e.Handled = true;
	}

	private Panel MakeZone(StringView name)
	{
		let zone = new Panel();
		zone.AddClass(name);
		zone.EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Row;
				s.AlignItems = .Center;
				s.ColumnGap = 12.0f;
				s.Shrink = 0.0f;
			});
		AddChild(zone);
		return zone;
	}

	// Into its zone, last (its order places it among the others there).
	private void Place(StatusItem item)
	{
		item.AddRef(); // held across its move
		item.RemoveFromParent();
		((item.Zone == .End) ? mEnd : mStart).AddChild(item);
		item.ReleaseRef();
	}
}
