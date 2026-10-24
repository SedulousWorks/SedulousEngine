using System;
using System.Collections;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The accessibility tree's model, AccessKit's owned here: an AccessNode for each widget a screen
// reader sees (a stable id, a role, a name, a description and a value, a number with its range,
// bounds in its root's space, states, children, the nodes that label, describe and are controlled
// by it, and the actions it takes), an AccessTreeUpdate with the nodes that changed (all of them,
// the first time) and the focus, and an AccessActionRequest a platform sends back.
// IAccessibilityBridge is the host's: it says whether anything listens and takes the updates and
// announcements; the GUI builds the tree only while it listens. The platform adapters (UI
// Automation, NSAccessibility, AT-SPI) are host work.
//
// A node, an update and a request own their text and lists, so each is a class with a deep Set.

/// What a node is to a screen reader. None: no node of its own (what it holds belongs to the
/// nearest ancestor that has one).
enum AccessRole : uint8
{
	None,
	Window,
	Dialog,
	Group,
	Label,
	Button,
	CheckBox,
	RadioButton,
	Switch,
	Slider,
	ProgressIndicator,
	SpinButton,
	TextInput,
	MultilineTextInput,
	ComboBox,
	List,
	ListItem,
	Tree,
	TreeItem,
	Table,
	/// A table's.
	Row,
	TabList,
	Tab,
	TabPanel,
	Menu,
	MenuBar,
	MenuItem,
	Separator,
	Image,
	ScrollView,
	ScrollBar,
	Count,
}

/// What a platform may ask of a node, one bit each in what it advertises.
enum AccessAction : uint8
{
	Focus,
	Activate,
	SetValue,
	Increment,
	Decrement,
	ScrollIntoView,
	Expand,
	Collapse,
}

/// How an announcement interrupts: after what is being read, or at once.
enum AnnouncePriority : uint8
{
	Polite,
	Assertive,
}

static
{
	// A node's states, one bit each (AccessState). Constants, as they are combined and kept as a
	// uint32.
	public const uint32 AccessFocusable = 1 << 0;
	public const uint32 AccessFocused = 1 << 1;
	public const uint32 AccessDisabled = 1 << 2;
	public const uint32 AccessChecked = 1 << 3;
	/// Neither checked nor not (an indeterminate check box).
	public const uint32 AccessMixed = 1 << 4;
	public const uint32 AccessSelected = 1 << 5;
	public const uint32 AccessExpanded = 1 << 6;
	public const uint32 AccessCollapsed = 1 << 7;
	/// The user edits its value.
	public const uint32 AccessEditable = 1 << 8;
	/// An item scrolled out of view, its bounds estimated (UIA's IsOffscreen).
	public const uint32 AccessOffscreen = 1 << 9;

	/// An item view's item's node id: this bit, the view's key among the GUI's item views, and the
	/// item's key in its view. A node's own id is its element handle, which never sets it.
	public const uint64 cAccessItemIdBit = (uint64)1 << 63;

	/// The role's name as a type attribute, markup's `role` and the inspector write it.
	public static StringView AccessRoleName(AccessRole role) => AccessibilityDetail.sRoleNames[(int)role];

	/// The role a name means; false for one that is none.
	public static bool AccessRoleNamed(StringView name, out AccessRole outRole)
	{
		for (int i = 0; i < (int)AccessRole.Count; i++)
		{
			if (AccessRoleName((AccessRole)i) == name)
			{
				outRole = (AccessRole)i;
				return true;
			}
		}
		outRole = .None;
		return false;
	}

	/// A role whose parts are no nodes of their own (a button's label, a slider's thumb): a screen
	/// reader reads it whole.
	public static bool IsLeafRole(AccessRole role)
	{
		switch (role)
		{
		case .Label,
			.Button,
			.CheckBox,
			.RadioButton,
			.Switch,
			.Slider,
			.ProgressIndicator,
			.SpinButton,
			.TextInput,
			.MultilineTextInput,
			.ComboBox,
			.Tab,
			.MenuItem,
			.Separator,
			.Image,
			.Row,
			.ScrollBar: return true;
		default: return false;
		}
	}

	public static uint32 AccessActionBit(AccessAction action) => (uint32)1 << (int)action;

	public static bool IsAccessItemId(uint64 id) => (id & cAccessItemIdBit) != 0;
}

internal static class AccessibilityDetail
{
	/// Each role's name, in role order.
	public static String[(int)AccessRole.Count] sRoleNames = .(
		"none", "window", "dialog", "group", "label", "button", "checkbox",
		"radio", "switch", "slider", "progress", "spinbutton", "textbox", "textarea",
		"combobox", "list", "listitem", "tree", "treeitem", "table", "row", "tablist",
		"tab", "tabpanel", "menu", "menubar", "menuitem", "separator", "image",
		"scrollview", "scrollbar");
}

/// One node of the tree, as the bridge sees it.
class AccessNode
{
	/// Stable while the node lives (its GUI's element handle; an item's, cAccessItemIdBit).
	public uint64 Id = 0;
	public AccessRole Role = .None;
	public String Name = new .() ~ delete _;
	public String Description = new .() ~ delete _;
	/// A text's, or a number's as it shows.
	public String Value = new .() ~ delete _;
	public bool HasNumber = false;
	public double Number = 0.0;
	public double Min = 0.0;
	public double Max = 0.0;
	public double Step = 0.0;
	/// In its window's pixels (its root's world space).
	public Rect Bounds = .();
	// Where it stands among its own (ARIA's and AccessKit's): an item's position, from 1, of how
	// many there are (a list's every item, though only some have nodes); a tree item's level, from
	// 1; a table's rows and columns, and a row's index, from 1. 0: not said.
	public int32 PositionInSet = 0;
	public int32 SetSize = 0;
	public int32 Level = 0;
	public int32 RowCount = 0;
	public int32 ColumnCount = 0;
	public int32 RowIndex = 0;
	public uint32 States = 0;
	/// AccessActionBit of each it takes.
	public uint32 Actions = 0;
	public List<uint64> Children = new .() ~ delete _;
	public List<uint64> LabelledBy = new .() ~ delete _;
	public List<uint64> DescribedBy = new .() ~ delete _;
	public List<uint64> Controls = new .() ~ delete _;

	/// Whether it has `state` (an Access* state bit).
	public bool Has(uint32 state) => (States & state) != 0;
	public bool Takes(AccessAction action) => (Actions & AccessActionBit(action)) != 0;

	/// Makes this a copy of `other`, its text and lists included.
	public void Set(AccessNode other)
	{
		if (other === this)
			return;
		Id = other.Id;
		Role = other.Role;
		Name.Set(other.Name);
		Description.Set(other.Description);
		Value.Set(other.Value);
		HasNumber = other.HasNumber;
		Number = other.Number;
		Min = other.Min;
		Max = other.Max;
		Step = other.Step;
		Bounds = other.Bounds;
		PositionInSet = other.PositionInSet;
		SetSize = other.SetSize;
		Level = other.Level;
		RowCount = other.RowCount;
		ColumnCount = other.ColumnCount;
		RowIndex = other.RowIndex;
		States = other.States;
		Actions = other.Actions;
		Children.Clear();
		Children.AddRange(other.Children);
		LabelledBy.Clear();
		LabelledBy.AddRange(other.LabelledBy);
		DescribedBy.Clear();
		DescribedBy.AddRange(other.DescribedBy);
		Controls.Clear();
		Controls.AddRange(other.Controls);
	}
}

/// What changed in one root's tree since the last update.
class AccessTreeUpdate
{
	/// The root's node (its window).
	public uint64 Root = 0;
	/// Every node of the tree: the first update, or one asked for.
	public bool Full = false;
	public List<AccessNode> Nodes = new .() ~ DeleteContainerAndItems!(_);
	/// The focused node, or the root.
	public uint64 Focus = 0;

	public AccessNode Find(uint64 id)
	{
		for (let n in Nodes)
		{
			if (n.Id == id)
				return n;
		}
		return null;
	}

	/// Makes this a copy of `other`, its nodes included.
	public void Set(AccessTreeUpdate other)
	{
		if (other === this)
			return;
		Root = other.Root;
		Full = other.Full;
		ClearAndDeleteItems(Nodes);
		for (let n in other.Nodes)
		{
			let copy = new AccessNode();
			copy.Set(n);
			Nodes.Add(copy);
		}
		Focus = other.Focus;
	}
}

/// An action a platform asks of a node (a screen reader's "press", a value typed into it).
class AccessActionRequest
{
	public uint64 Target = 0;
	public AccessAction Action = .Focus;
	/// SetValue's text.
	public String Text = new .() ~ delete _;
	public bool HasNumber = false;
	/// SetValue's number.
	public double Number = 0.0;

	public void Set(AccessActionRequest other)
	{
		if (other === this)
			return;
		Target = other.Target;
		Action = other.Action;
		Text.Set(other.Text);
		HasNumber = other.HasNumber;
		Number = other.Number;
	}
}

/// The host's side: a platform adapter, or a stand-in (GUISandbox's --narrate).
interface IAccessibilityBridge
{
	/// Whether anything listens (a screen reader running): the tree is built only then.
	bool IsListening { get; }
	/// A root's nodes that changed, once a frame (the whole tree the first time). The bridge keeps
	/// a copy of what it needs.
	void Update(AccessTreeUpdate update);
	/// Text to speak that no node holds (a score, a level loaded).
	void Announce(StringView text, AnnouncePriority priority);
}
