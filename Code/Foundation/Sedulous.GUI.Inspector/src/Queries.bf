using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using internal Sedulous.GUI.Inspector;

namespace Sedulous.GUI.Inspector;

// What the inspector asks of a GUI, over the core's public API alone: the tree in order, a node
// described (its identity, states, box, reflected properties, bindings, commands and listeners),
// the nodes a selector matches, and a property set through the path markup uses. The panes draw
// these; a tool (an MCP server, once the GUI is hosted) can serve the same answers.

/// One node of a tree, as the tree pane lists it. A class: it owns its label.
class TreeEntry
{
	public Node Target = null;
	public uint32 Depth = 0;
	public String Label = new .() ~ delete _;
	/// Visible and in the layout, with its ancestors.
	public bool Shown = true;

	public void Set(TreeEntry other)
	{
		if (other === this)
			return;
		Target = other.Target;
		Depth = other.Depth;
		Label.Set(other.Label);
		Shown = other.Shown;
	}
}

/// A reflected property of a node and its value now. A class: it owns its text.
class ReflectedValue
{
	/// As the type names it.
	public String Name = new .() ~ delete _;
	/// As markup and sheets name it (empty when they cannot set it).
	public String CssName = new .() ~ delete _;
	/// As text (empty when it has none).
	public String Value = new .() ~ delete _;
	/// The key it is translated from (empty when it is not).
	public String Key = new .() ~ delete _;
	public bool ReadOnly = false;

	public void Set(ReflectedValue other)
	{
		if (other === this)
			return;
		Name.Set(other.Name);
		CssName.Set(other.CssName);
		Value.Set(other.Value);
		Key.Set(other.Key);
		ReadOnly = other.ReadOnly;
	}
}

/// What the inspector shows of one node. A class: it owns its text and lists.
class NodeDescription
{
	public String Type = new .() ~ delete _;
	public String Tag = new .() ~ delete _;
	public String Id = new .() ~ delete _;
	public List<String> Classes = new .() ~ DeleteContainerAndItems!(_);
	/// The pseudo-classes it has now ("hover", "focus"; "(forced)" when forced).
	public List<String> States = new .() ~ DeleteContainerAndItems!(_);
	/// Its border box in the GUI's world.
	public Rect Bounds = .();
	public Thickness Margin = .();
	public Thickness Padding = .();
	public bool Shown = true;
	public bool Enabled = true;
	public bool TabFocusable = false;
	public List<ReflectedValue> Properties = new .() ~ DeleteContainerAndItems!(_);
	public int Bindings = 0;
	/// Each command it handles ("menu.open (capture)").
	public List<String> Commands = new .() ~ DeleteContainerAndItems!(_);
	/// Each event it listens for ("click", "keydown (capture)").
	public List<String> Listeners = new .() ~ DeleteContainerAndItems!(_);

	public void Set(NodeDescription other)
	{
		if (other === this)
			return;
		Type.Set(other.Type);
		Tag.Set(other.Tag);
		Id.Set(other.Id);
		QueriesDetail.CopyStrings(other.Classes, Classes);
		QueriesDetail.CopyStrings(other.States, States);
		Bounds = other.Bounds;
		Margin = other.Margin;
		Padding = other.Padding;
		Shown = other.Shown;
		Enabled = other.Enabled;
		TabFocusable = other.TabFocusable;
		ClearAndDeleteItems!(Properties);
		for (let p in other.Properties)
		{
			let copy = new ReflectedValue();
			copy.Set(p);
			Properties.Add(copy);
		}
		Bindings = other.Bindings;
		QueriesDetail.CopyStrings(other.Commands, Commands);
		QueriesDetail.CopyStrings(other.Listeners, Listeners);
	}
}

/// What a screen reader is told of a node. A class: it owns its text and lists.
class AccessDescription
{
	/// It has a node of its own (else it reads as part of an ancestor).
	public bool Own = false;
	/// When not: the ancestor it reads as part of (its tree label).
	public String ReadAs = new .() ~ delete _;
	public String Role = new .() ~ delete _;
	public String Name = new .() ~ delete _;
	public String Value = new .() ~ delete _;
	public String Description = new .() ~ delete _;
	public List<String> States = new .() ~ DeleteContainerAndItems!(_);
	public List<String> Actions = new .() ~ DeleteContainerAndItems!(_);

	public void Set(AccessDescription other)
	{
		if (other === this)
			return;
		Own = other.Own;
		ReadAs.Set(other.ReadAs);
		Role.Set(other.Role);
		Name.Set(other.Name);
		Value.Set(other.Value);
		Description.Set(other.Description);
		QueriesDetail.CopyStrings(other.States, States);
		QueriesDetail.CopyStrings(other.Actions, Actions);
	}
}

/// One thing a screen reader would trip on. A class: it owns its message.
class AccessIssue
{
	public Node Target = null;
	public String Message = new .() ~ delete _;

	public void Set(AccessIssue other)
	{
		if (other === this)
			return;
		Target = other.Target;
		Message.Set(other.Message);
	}
}

static
{
	/// A node as a line of the tree, appended to `outText`: its type, then #id and .classes for a
	/// widget ("Button #ok .primary").
	public static void Label(Node node, String outText)
	{
		node.GetType().GetName(outText);
		if (let widget = node as UIWidget)
		{
			if (widget.Id.Length != 0)
			{
				outText.Append(" #");
				outText.Append(widget.Id);
			}
			for (let cls in widget.Classes)
			{
				outText.Append(" .");
				outText.Append(cls);
			}
		}
	}

	/// The tree under `root` (itself included) in document order, each node at its depth below it,
	/// added to `outEntries` (the caller owns what is added).
	public static void Tree(Node root, List<TreeEntry> outEntries)
	{
		QueriesDetail.Walk(root, 0, true, outEntries);
	}

	/// `node` described for the inspector, into `outDescription` (a new one).
	public static void Describe(Node node, NodeDescription outDescription)
	{
		let d = outDescription;
		node.GetType().GetName(d.Type);
		d.Bounds = node.ScreenBounds;
		d.Margin = node.Margin;
		d.Padding = node.Padding;
		d.Shown = node.IsTreeVisible;
		d.Enabled = node.IsTreeEnabled;
		d.TabFocusable = node.TabFocusable;
		d.Bindings = node.BindingCount;
		let forced = node.ForcedStyleStates;
		void State(bool on, uint32 bit, StringView name)
		{
			let isForced = (forced & bit) != 0;
			if (!on && !isForced)
				return;
			let s = new String(name);
			if (isForced && !on)
				s.Append(" (forced)");
			d.States.Add(s);
		}
		if (let widget = node as UIWidget)
		{
			d.Tag.Set(widget.Tag);
			d.Id.Set(widget.Id);
			for (let cls in widget.Classes)
				d.Classes.Add(new String(cls));
			let widgetStates = widget.WidgetStates;
			State(widget.Hovered, Node.StateHover, "hover");
			State(widget.Pressed, Node.StateActive, "active");
			State(widget.IsFocused, Node.StateFocus, "focus");
			State(widget.FocusVisible, Node.StateFocusVisible, "focus-visible");
			State(widget.IsFocusWithin, Node.StateFocusWithin, "focus-within");
			State((widgetStates & WidgetStateChecked) != 0, Node.StateChecked, "checked");
			State(!widget.Enabled, Node.StateDisabled, "disabled");
			State((widgetStates & WidgetStateSelected) != 0, Node.StateSelected, "selected");
		}
		// Its reflected properties, its own type's first.
		for (var t = node.GuiType; t != null; t = t.Base)
		{
			for (let property in t.OwnProperties)
			{
				let value = new ReflectedValue();
				value.Name.Set(property.Name);
				value.CssName.Set(property.Css);
				value.ReadOnly = !property.CanWrite;
				if (let key = node.TranslationKey(value.Name))
					value.Key.Set(key);
				var now = property.Get(node);
				var text = ConvertVariant(now, typeof(String));
				if (IsText(text))
					value.Value.Set(TextOf(text));
				text.Dispose();
				now.Dispose();
				d.Properties.Add(value);
			}
		}
		node.ForEachCommandHandler(scope (id, phase) =>
			{
				let s = new String(id);
				if (phase == .Capture)
					s.Append(" (capture)");
				d.Commands.Add(s);
			});
		node.ForEachListener(scope (type, capture) =>
			{
				let name = EventTypeName(type);
				let s = new String((name.Length != 0) ? name : "(an event)");
				if (capture)
					s.Append(" (capture)");
				d.Listeners.Add(s);
			});
	}

	/// What a screen reader is told of `node`, into `outDescription` (a new one).
	public static void DescribeAccess(Node node, AccessDescription outDescription)
	{
		let d = outDescription;
		let root = node.SceneRoot;
		if (root == null)
			return;
		let a = scope AccessNode();
		if (!root.Context.DescribeAccess(node, a))
		{
			for (var up = node.Parent; up != null; up = up.Parent)
			{
				if (root.Context.DescribeAccess(up, a))
				{
					Sedulous.GUI.Inspector.Label(up, d.ReadAs);
					break;
				}
			}
			return;
		}
		d.Own = true;
		d.Role.Set(AccessRoleName(a.Role));
		d.Name.Set(a.Name);
		if (a.HasNumber)
			d.Value.AppendF("{} (from {} to {}, by {})", a.Number, a.Min, a.Max, a.Step);
		else
			d.Value.Set(a.Value);
		d.Description.Set(a.Description);
		for (let s in QueriesDetail.sAccessStates)
		{
			if ((a.States & s.Bit) != 0)
				d.States.Add(new String(s.Name));
		}
		for (let s in QueriesDetail.sAccessActions)
		{
			if ((a.Actions & AccessActionBit(s.Action)) != 0)
				d.Actions.Add(new String(s.Name));
		}
	}

	/// What under `root` a screen reader would trip on, added to `outIssues` (the caller owns what
	/// is added): a control the keyboard reaches with no name, and an aria relation naming no
	/// widget.
	public static void AuditAccess(SceneRoot root, List<AccessIssue> outIssues)
	{
		QueriesDetail.Audit(root, root, outIssues);
	}

	/// The widgets under `root` (itself included) a CSS selector matches, in document order, added
	/// to `outNodes`.
	public static void Query(Node root, StringView selector, List<Node> outNodes)
	{
		let parsed = scope StyleSelector(selector);
		if (parsed.IsEmpty)
			return;
		QueriesDetail.Select(root, parsed, outNodes);
	}

	/// Sets property `name` (its CSS name, or its type's name in any case) to `text` as markup
	/// does: an attribute the widget claims, else inline CSS the next restyle applies (which a
	/// sheet's rules do not outrank). False when the node is no widget, or has no such property or
	/// attribute.
	public static bool SetProperty(Node node, StringView name, StringView text)
	{
		let uinode = node as UINode;
		if (uinode == null)
			return false;
		if (uinode.SetMarkupAttribute(name, text)) // one the widget claims (a label's text)
			return true;
		StringView attribute = name;
		bool known = FindStyleProperty(name) != null;
		for (var t = node.GuiType; (t != null) && !known; t = t.Base)
		{
			for (let property in t.OwnProperties)
			{
				// A property's own name is PascalCase and markup's camelCase: compared in any case,
				// as the GUI's reflection finds a property by it.
				if (!property.Css.IsEmpty && ((property.Css == name) || property.Name.Equals(name, true)))
				{
					attribute = property.Css;
					known = true;
					break;
				}
			}
		}
		if (!known)
			return false;
		uinode.SetInlineStyle(attribute, text);
		return true;
	}
}

/// What Queries.bf keeps out of the public surface.
internal static class QueriesDetail
{
	public static (uint32 Bit, String Name)[9] sAccessStates = .(
		(AccessFocusable, "focusable"), (AccessFocused, "focused"), (AccessDisabled, "disabled"),
		(AccessChecked, "checked"), (AccessMixed, "mixed"), (AccessSelected, "selected"),
		(AccessExpanded, "expanded"), (AccessCollapsed, "collapsed"), (AccessEditable, "editable"));

	public static (AccessAction Action, String Name)[8] sAccessActions = .(
		(.Focus, "focus"), (.Activate, "activate"), (.SetValue, "set value"), (.Increment, "increment"),
		(.Decrement, "decrement"), (.ScrollIntoView, "scroll into view"), (.Expand, "expand"), (.Collapse, "collapse"));

	/// `to` made a copy of `from`'s strings.
	public static void CopyStrings(List<String> from, List<String> to)
	{
		ClearAndDeleteItems!(to);
		for (let s in from)
			to.Add(new String(s));
	}

	/// `node` and what it holds into `outEntries`, `node` at `depth`; `shown`: its ancestors show.
	public static void Walk(Node node, uint32 depth, bool shown, List<TreeEntry> outEntries)
	{
		let here = shown && node.Visible && node.Displayed;
		let entry = new TreeEntry();
		entry.Target = node;
		entry.Depth = depth;
		Sedulous.GUI.Inspector.Label(node, entry.Label);
		entry.Shown = here;
		outEntries.Add(entry);
		for (int i = 0; i < node.ChildCount; i++)
		{
			if (let child = node.GetChildAt(i))
				Walk(child, depth + 1, here, outEntries);
		}
	}

	/// Whether a widget under `node` (itself included) has the id `id`.
	public static bool HasId(Node node, StringView id)
	{
		if (let w = node as UIWidget)
		{
			if (w.Id == id)
				return true;
		}
		for (int i = 0; i < node.ChildCount; i++)
		{
			let child = node.GetChildAt(i);
			if ((child != null) && HasId(child, id))
				return true;
		}
		return false;
	}

	/// An issue for each id in the space-separated `ids` no widget under `root` has.
	public static void Relation(SceneRoot root, Node node, StringView attribute, StringView ids, List<AccessIssue> outIssues)
	{
		int i = 0;
		while (i < ids.Length)
		{
			while ((i < ids.Length) && (ids[i] == ' '))
				i++;
			let start = i;
			while ((i < ids.Length) && (ids[i] != ' '))
				i++;
			if ((i > start) && !HasId(root, ids.Substring(start, i - start)))
			{
				let issue = new AccessIssue();
				issue.Target = node;
				issue.Message.AppendF("{} names no widget: #{}", attribute, ids.Substring(start, i - start));
				outIssues.Add(issue);
			}
		}
	}

	/// AuditAccess's walk: `node` and what it holds, in `root`.
	public static void Audit(SceneRoot root, Node node, List<AccessIssue> outIssues)
	{
		if (let widget = node as UIWidget)
		{
			let a = scope AccessNode();
			if (node.TabFocusable && root.Context.DescribeAccess(node, a) && (a.Name.Length == 0))
			{
				let issue = new AccessIssue();
				issue.Target = node;
				issue.Message.AppendF("a focusable {} with no name", AccessRoleName(a.Role));
				outIssues.Add(issue);
			}
			Relation(root, node, "aria-labelledby", widget.AccessLabelledBy, outIssues);
			Relation(root, node, "aria-describedby", widget.AccessDescribedBy, outIssues);
			Relation(root, node, "aria-controls", widget.AccessControls, outIssues);
		}
		for (int i = 0; i < node.ChildCount; i++)
		{
			if (let child = node.GetChildAt(i))
				Audit(root, child, outIssues);
		}
	}

	/// Query's walk: the widgets under `node` (itself included) `selector` matches.
	public static void Select(Node node, StyleSelector selector, List<Node> outNodes)
	{
		if (let widget = node as UIWidget)
		{
			if (selector.Select(widget))
				outNodes.Add(node);
		}
		for (int i = 0; i < node.ChildCount; i++)
		{
			if (let child = node.GetChildAt(i))
				Select(child, selector, outNodes);
		}
	}
}
