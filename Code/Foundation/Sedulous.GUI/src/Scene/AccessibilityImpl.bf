using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The accessibility tree, built from the widgets, which Accessibility.bf only names. A widget's
// role is its AccessRoleName (its type's, set as it is made, or markup's `role`); its name, value,
// range, description and expanded state are the reflected properties its type marks `access`; its
// other states are the ones its selectors read; whether a screen reader may press it is its type's
// (UIWidget.AccessActivates). A node with no role is no node of its own (what it holds belongs to
// the nearest ancestor that has one), and a leaf role's parts are none either. An item view's
// items are nodes with no widget of their own: the items it says have nodes, in item order, each
// saying where it stands among them all, under ids that follow the item.

extension GUIContext
{
	/// `root`'s whole tree as it is now, listening or not (the inspector's, a test's). The caller
	/// owns what comes back.
	public AccessTreeUpdate BuildAccessTree(SceneRoot root)
	{
		let update = new AccessTreeUpdate();
		update.Root = AccessibilityImplDetail.AccessIdOf(root);
		update.Full = true;
		let builder = scope AccessibilityImplDetail.Builder(root);
		builder.All(root, update.Nodes);
		update.Focus = AccessibilityImplDetail.FocusOf(root);
		return update;
	}

	/// `node`'s accessibility node as it is now, into `outNode` (reset first); false when it has
	/// none of its own (no role, hidden, or a part of a leaf: what a screen reader reads it as is
	/// an ancestor's).
	public bool DescribeAccess(Node node, AccessNode outNode)
	{
		let root = node.SceneRoot;
		if (root == null)
			return false;
		for (var n = node; n != null; n = n.Parent)
		{
			if (AccessibilityImplDetail.Excluded(n) && !(n is SceneRoot))
				return false;
			if ((n != node) && IsLeafRole(AccessibilityImplDetail.RoleOf(n)))
				return false; // a leaf's part
		}
		let role = AccessibilityImplDetail.RoleOf(node);
		if (role == .None)
			return false;
		let builder = scope AccessibilityImplDetail.Builder(root);
		outNode.Set(scope AccessNode());
		builder.Describe(node, role, outNode);
		return true;
	}

	/// An item view's key among this GUI's, given the first time it is asked (0 for a node that is
	/// no item view).
	public uint32 AccessViewKey(Node view)
	{
		let items = view as ItemView;
		if (items == null)
			return 0;
		if (items.AccessViewKey != 0)
			return items.AccessViewKey;
		let key = mNextAccessView++;
		mAccessViews[key] = view.TakeElementRef();
		items.AccessViewKey = key;
		return key;
	}

	/// Runs an action now; false when its node is gone or does not take it.
	public bool RunAccessAction(AccessActionRequest request)
	{
		let node = ResolveAccessId(request.Target);
		if (node == null)
			return false;
		if (IsAccessItemId(request.Target))
		{
			// An item's, run through its view, by its key: the item may have moved since.
			let view = node as ItemView;
			let root = node.SceneRoot;
			if ((view == null) || (root == null) || AccessibilityImplDetail.Excluded(view))
				return false;
			let item = view.GetItemOfAccessKey((uint32)(request.Target & 0xFFFFFFFF));
			if (item < 0)
				return false; // gone from the model
			let builder = scope AccessibilityImplDetail.Builder(root);
			let described = scope AccessNode();
			builder.DescribeItem(view, item, described);
			if (!described.Takes(request.Action))
				return false;
			switch (request.Action)
			{
			case .Focus:
				view.FocusItemFromAccess(item);
				return true;
			case .Activate:
				view.ActivateItemFromAccess(item);
				return true;
			case .ScrollIntoView:
				view.ScrollToItem(item);
				return true;
			case .Expand, .Collapse:
				if (let tree = view as TreeView)
				{
					if (request.Action == .Expand)
						tree.ExpandItem(item);
					else
						tree.CollapseItem(item);
					return true;
				}
				return false;
			default:
				return false;
			}
		}
		let root = node.SceneRoot;
		if ((root == null) || AccessibilityImplDetail.Excluded(node))
			return false;
		// Only what it advertises: the same description a screen reader was sent.
		let builder = scope AccessibilityImplDetail.Builder(root);
		let described = scope AccessNode();
		builder.Describe(node, AccessibilityImplDetail.RoleOf(node), described);
		if (!described.Takes(request.Action))
			return false;
		switch (request.Action)
		{
		case .Focus:
			node.RequestFocus();
			return node.IsFocused;
		case .Activate:
			return node.HandleActivate();
		case .SetValue:
			let value = AccessibilityImplDetail.AccessProperty(node, "value");
			var given = request.HasNumber ? System.Variant.Create(request.Number) : TextVariant(request.Text);
			defer given.Dispose();
			return value.Set(node, given);
		case .Increment, .Decrement:
			let number = AccessibilityImplDetail.AccessProperty(node, "value");
			let step = (described.Step > 0.0) ? described.Step : (described.Max - described.Min) / 100.0;
			let to = described.Number + ((request.Action == .Increment) ? step : -step);
			return number.Set(node, System.Variant.Create(to));
		case .ScrollIntoView:
			for (var up = node.Parent; up != null; up = up.Parent)
			{
				if (up.IsScrollContainer)
					up.ScrollIntoView(node);
			}
			return true;
		case .Expand, .Collapse:
			let expanded = AccessibilityImplDetail.AccessProperty(node, "expanded");
			return expanded.Set(node, System.Variant.Create(request.Action == .Expand));
		}
	}

	// The requests queued, each run.
	private void RunAccessRequests()
	{
		let requests = scope List<AccessActionRequest>();
		using (mAccessLock.Enter())
		{
			requests.AddRange(mAccessRequests);
			mAccessRequests.Clear();
		}
		for (let request in requests)
			RunAccessAction(request);
		ClearAndDeleteItems!(requests);
	}

	// Each root's changes to the bridge.
	private void FlushAccessibility()
	{
		if ((mAccessBridge == null) || !mAccessBridge.IsListening)
		{
			mAccessListening = false;
			return;
		}
		let starting = !mAccessListening;
		mAccessListening = true;
		for (let root in mRoots)
		{
			if (starting)
				root.[Friend]mAccessTreeSent = false;
			AccessTreeUpdate update;
			let focusWas = root.[Friend]mAccessFocus;
			if (!root.[Friend]mAccessTreeSent)
			{
				update = BuildAccessTree(root);
				AccessibilityImplDetail.ClearMarks(root);
				root.[Friend]mAccessTreeSent = true;
				for (let n in update.Nodes) // what each said, so a mark alone sends nothing
				{
					if (IsAccessItemId(n.Id))
					{
						if (let view = ResolveAccessId(n.Id) as ItemView)
							view.AccessItemsSent[n.Id] = AccessibilityImplDetail.HashOf(n);
					}
					else if (let node = ResolveAccessId(n.Id))
						node.AccessSent = AccessibilityImplDetail.HashOf(n);
				}
			}
			else
			{
				update = new AccessTreeUpdate();
				update.Root = AccessibilityImplDetail.AccessIdOf(root);
				let builder = scope AccessibilityImplDetail.Builder(root);
				let changes = scope AccessibilityImplDetail.Changes(builder, update.Nodes);
				changes.Walk(root, null);
				update.Focus = AccessibilityImplDetail.FocusOf(root);
			}
			root.[Friend]mAccessFocus = update.Focus;
			if (update.Full || !update.Nodes.IsEmpty || (update.Focus != focusWas))
				mAccessBridge.Update(update);
			delete update;
		}
	}
}

/// What AccessibilityImpl.bf keeps out of the public surface.
internal static class AccessibilityImplDetail
{
	public static uint64 AccessIdOf(Node node)
	{
		let r = node.TakeElementRef();
		return (r.Table != null) ? (((uint64)r.Generation << 32) | (uint64)r.Slot) : 0;
	}

	// The property of the node's type (or a base's) that its type marks `access` as `what`.
	public static GuiPropertyInfo AccessProperty(Node node, StringView what)
	{
		for (var type = node.GuiType; type != null; type = type.Base)
		{
			for (let property in type.OwnProperties)
			{
				if (property.Access == what)
					return property;
			}
		}
		return null;
	}

	// The property's value as text, appended.
	public static void ReadText(Node node, GuiPropertyInfo property, String outText)
	{
		var value = property.Get(node);
		AsText(value, outText);
		value.Dispose();
	}

	// The property's value as a number, or null when it holds none.
	public static double? ReadNumber(Node node, GuiPropertyInfo property)
	{
		var value = property.Get(node);
		let number = AsNumber(value);
		value.Dispose();
		return number;
	}

	public static void AsText(System.Variant value, String outText)
	{
		var text = ConvertVariant(value, typeof(String));
		outText.Append(TextOf(text));
		text.Dispose();
	}

	public static double? AsNumber(System.Variant value)
	{
		var number = ConvertVariant(value, typeof(double));
		defer number.Dispose();
		if (number.VariantType == typeof(double))
			return number.Get<double>();
		return null;
	}

	public static bool Writable(GuiPropertyInfo property) => property.CanWrite;

	// A property's number, when it holds one (a slider's value, not a text field's).
	public static bool IsNumeric(GuiPropertyInfo property)
	{
		let type = property.ValueType;
		return (type == typeof(double)) || (type == typeof(float)) || (type == typeof(int32)) ||
			(type == typeof(uint32)) || (type == typeof(int64));
	}

	public static AccessRole RoleOf(Node node)
	{
		if (node is SceneRoot)
			return .Window;
		let widget = node as UIWidget;
		if (widget == null)
			return .None;
		let named = widget.AccessRoleName;
		if ((named.Length != 0) && AccessRoleNamed(named, let role))
			return role;
		return .None;
	}

	// Not read at all, with what it holds: not displayed, hidden, or aria-hidden.
	public static bool Excluded(Node node)
	{
		if (!node.Displayed || !node.Visible)
			return true;
		let widget = node as UIWidget;
		return (widget != null) && widget.AccessHidden;
	}

	// The ids in a space-separated list.
	public static void EachId(StringView list, delegate void(StringView id) each)
	{
		int i = 0;
		while (i < list.Length)
		{
			while ((i < list.Length) && (list[i] == ' '))
				++i;
			let start = i;
			while ((i < list.Length) && (list[i] != ' '))
				++i;
			if (i > start)
				each(list.Substring(start, i - start));
		}
	}

	public static UIWidget FindById(Node under, StringView id)
	{
		if (let widget = under as UIWidget)
		{
			if (widget.Id == id)
				return widget;
		}
		for (int i = 0; i < under.ChildCount; ++i)
		{
			let child = under.GetChildAt(i);
			if (child == null)
				continue;
			let found = FindById(child, id);
			if (found != null)
				return found;
		}
		return null;
	}

	// An item's node id: the view's key among the GUI's item views, and the item's in its view.
	public static uint64 ItemAccessId(Node top, ItemView view, int32 item)
	{
		let gui = top.GUIContext;
		let viewKey = (gui != null) ? gui.AccessViewKey(view) : 0;
		return cAccessItemIdBit | ((uint64)viewKey << 32) | (uint64)view.GetAccessKeyOfItem(item);
	}

	public static AccessRole ItemRoleOf(ItemView view)
	{
		if (view is TreeView)
			return .TreeItem;
		if (view is TableView)
			return .Row;
		return .ListItem;
	}

	public class Builder
	{
		private Node mTop; // the root the ids in aria lists resolve under

		public this(Node top)
		{
			mTop = top;
		}

		// An item view's item, a node with no widget of its own: where it stands among all the
		// items (a tree item among its siblings, at its level), its bounds (estimated, off screen,
		// while it has no row), and what a screen reader may do with it.
		public void DescribeItem(ItemView view, int32 item, AccessNode outNode)
		{
			outNode.Id = ItemAccessId(mTop, view, item);
			outNode.Role = ItemRoleOf(view);
			view.GetItemText(item, outNode.Name);
			let enabled = view.IsTreeEnabled;
			outNode.States |= AccessFocusable;
			if (!enabled)
				outNode.States |= AccessDisabled;
			if (view.IsItemSelected(item))
				outNode.States |= AccessSelected;
			if (view.IsFocused && (view.CurrentItem == item))
				outNode.States |= AccessFocused;
			outNode.Actions |= AccessActionBit(.Focus) | AccessActionBit(.ScrollIntoView);
			if (enabled)
				outNode.Actions |= AccessActionBit(.Activate);
			let row = view.RowForItem(item);
			if (row != null)
				outNode.Bounds = row.ScreenBounds;
			else
			{
				outNode.States |= AccessOffscreen;
				let b = view.ItemBounds(item);
				let scrolled = view.ScrollOffset;
				let at = view.ConvertToWorldSpace(.(b.X - scrolled.X, b.Y - scrolled.Y));
				outNode.Bounds = .(at.X, at.Y, b.Width, b.Height);
			}
			let model = view.Model;
			if (let tree = view as TreeView)
			{
				let index = view.GetItemIndex(item);
				outNode.Level = tree.ItemDepth(item) + 1;
				outNode.PositionInSet = index.Row + 1;
				outNode.SetSize = (model != null) ? (int32)model.RowCount(model.ParentIndex(index)) : 0;
				if ((model != null) && model.HasChildren(index))
				{
					let open = tree.IsItemExpanded(item);
					outNode.States |= open ? AccessExpanded : AccessCollapsed;
					if (enabled)
						outNode.Actions |= AccessActionBit(open ? AccessAction.Collapse : AccessAction.Expand);
				}
				return;
			}
			outNode.PositionInSet = item + 1;
			outNode.SetSize = (int32)view.GetItemCount();
			if (view is TableView)
				outNode.RowIndex = item + 1;
		}

		// The included nodes under `node`: each child with a role, or what a child without one
		// holds, in order.
		public void Children(Node node, List<uint64> outIds)
		{
			for (int i = 0; i < node.ChildCount; ++i)
			{
				let child = node.GetChildAt(i);
				if ((child == null) || Excluded(child))
					continue;
				if (RoleOf(child) != .None)
					outIds.Add(AccessIdOf(child));
				else
					Children(child, outIds);
			}
		}

		// Its name, appended: the widgets that label it, else its aria-label, else what its type
		// names it by, else its tooltip.
		public void NameOf(UIWidget widget, String outText, uint32 depth = 0)
		{
			if ((depth < 2) && (widget.AccessLabelledBy.Length != 0))
			{
				let joined = scope String();
				EachId(widget.AccessLabelledBy, scope [&] (id) =>
					{
						let by = FindById(mTop, id);
						if (by != null)
						{
							if (joined.Length != 0)
								joined.Append(' ');
							NameOf(by, joined, depth + 1);
						}
					});
				if (joined.Length != 0)
				{
					outText.Append(joined);
					return;
				}
			}
			if (widget.AccessLabel.Length != 0)
			{
				outText.Append(widget.AccessLabel);
				return;
			}
			let name = AccessProperty(widget, "name");
			if (name != null)
			{
				let text = scope String();
				ReadText(widget, name, text);
				if (text.Length != 0)
				{
					outText.Append(text);
					return;
				}
			}
			outText.Append(widget.TooltipText);
		}

		public void Ids(StringView list, List<uint64> outIds)
		{
			EachId(list, scope [&] (id) =>
				{
					let found = FindById(mTop, id);
					if (found != null)
						outIds.Add(AccessIdOf(found));
				});
		}

		public void Describe(Node node, AccessRole role, AccessNode outNode)
		{
			outNode.Id = AccessIdOf(node);
			outNode.Role = role;
			outNode.Bounds = node.ScreenBounds;
			if (node.TabFocusable)
			{
				outNode.States |= AccessFocusable;
				outNode.Actions |= AccessActionBit(.Focus);
			}
			if (node.IsFocused)
				outNode.States |= AccessFocused;
			let enabled = node.IsTreeEnabled;
			if (!enabled)
				outNode.States |= AccessDisabled;
			outNode.Actions |= AccessActionBit(.ScrollIntoView);
			let widget = node as UIWidget;
			if (widget != null)
			{
				NameOf(widget, outNode.Name);
				let states = widget.WidgetStates;
				if ((states & WidgetStateIndeterminate) != 0)
					outNode.States |= AccessMixed;
				else if ((states & WidgetStateChecked) != 0)
					outNode.States |= AccessChecked;
				if ((states & WidgetStateSelected) != 0)
					outNode.States |= AccessSelected;
				let editable = (states & WidgetStateEditable) != 0;
				if (editable)
					outNode.States |= AccessEditable;
				Ids(widget.AccessLabelledBy, outNode.LabelledBy);
				Ids(widget.AccessDescribedBy, outNode.DescribedBy);
				Ids(widget.AccessControls, outNode.Controls);
				// Its description: the names of the widgets that describe it, else its type's.
				EachId(widget.AccessDescribedBy, scope [&] (id) =>
					{
						let by = FindById(mTop, id);
						if (by != null)
						{
							if (outNode.Description.Length != 0)
								outNode.Description.Append(' ');
							NameOf(by, outNode.Description);
						}
					});
				if (outNode.Description.Length == 0)
				{
					let description = AccessProperty(node, "description");
					if (description != null)
						ReadText(node, description, outNode.Description);
				}
			}
			if ((widget != null) && widget.AccessActivates && enabled)
				outNode.Actions |= AccessActionBit(.Activate);
			let value = AccessProperty(node, "value");
			if (value != null)
			{
				var v = value.Get(node);
				defer v.Dispose();
				let secret = AccessProperty(node, "secret");
				let hidden = (secret != null) && ((ReadNumber(node, secret) ?? 0.0) != 0.0);
				if (!hidden) // a password's is not read out
					AsText(v, outNode.Value);
				if (IsNumeric(value))
				{
					outNode.HasNumber = true;
					outNode.Number = AsNumber(v) ?? 0.0;
					let min = AccessProperty(node, "min");
					if (min != null)
						outNode.Min = ReadNumber(node, min) ?? 0.0;
					let max = AccessProperty(node, "max");
					if (max != null)
						outNode.Max = ReadNumber(node, max) ?? 0.0;
					let step = AccessProperty(node, "step");
					if (step != null)
						outNode.Step = ReadNumber(node, step) ?? 0.0;
				}
				let takesValue = enabled && Writable(value) && (outNode.HasNumber || ((outNode.States & AccessEditable) != 0));
				if (takesValue)
				{
					outNode.Actions |= AccessActionBit(.SetValue);
					if (outNode.HasNumber)
						outNode.Actions |= AccessActionBit(.Increment) | AccessActionBit(.Decrement);
				}
			}
			let expanded = AccessProperty(node, "expanded");
			if (expanded != null)
			{
				let open = (ReadNumber(node, expanded) ?? 0.0) != 0.0;
				outNode.States |= open ? AccessExpanded : AccessCollapsed;
				if (enabled && Writable(expanded))
					outNode.Actions |= AccessActionBit(open ? AccessAction.Collapse : AccessAction.Expand);
			}
			if (let view = node as ItemView)
			{
				// Its items, not the rows it happens to have made (which recycle).
				let items = scope List<int32>();
				view.GetAccessItems(items);
				for (let item in items)
					outNode.Children.Add(ItemAccessId(mTop, view, item));
				if (view is TableView)
				{
					outNode.RowCount = (int32)view.GetItemCount();
					outNode.ColumnCount = (view.Model != null) ? (int32)view.Model.ColumnCount() : 0;
				}
				return;
			}
			if (!IsLeafRole(role))
				Children(node, outNode.Children);
		}

		// An item view's items' nodes, added to `outNodes` (which owns them).
		public void Items(ItemView view, List<AccessNode> outNodes)
		{
			let items = scope List<int32>();
			view.GetAccessItems(items);
			for (let item in items)
			{
				let described = new AccessNode();
				DescribeItem(view, item, described);
				outNodes.Add(described);
			}
		}

		// Every included node from `node` down (`node` itself when it has a role), added to
		// `outNodes` (which owns them).
		public void All(Node node, List<AccessNode> outNodes)
		{
			if (Excluded(node) && !(node is SceneRoot))
				return;
			let role = RoleOf(node);
			if (role != .None)
			{
				let described = new AccessNode();
				Describe(node, role, described);
				outNodes.Add(described);
				if (IsLeafRole(role))
					return;
			}
			let view = node as ItemView;
			if ((view != null) && (role != .None))
			{
				Items(view, outNodes);
				return;
			}
			for (int i = 0; i < node.ChildCount; ++i)
			{
				let child = node.GetChildAt(i);
				if (child != null)
					All(child, outNodes);
			}
		}
	}

	private static uint64 Mix<T>(uint64 h, T value) where T : struct
	{
		var copy = value;
		return HashBytes(&copy, sizeof(T), h);
	}

	private static uint64 MixText(uint64 h, String s) => HashBytes(s.Ptr, s.Length, h ^ 0x9E3779B97F4A7C15UL);

	private static uint64 MixIds(uint64 h, List<uint64> list) => HashBytes(list.Ptr, list.Count * sizeof(uint64), h ^ (uint64)list.Count);

	// What a node says, as one number: sent again only when it changes.
	public static uint64 HashOf(AccessNode n)
	{
		var role = n.Role;
		var h = HashBytes(&role, sizeof(AccessRole));
		h = MixText(h, n.Name);
		h = MixText(h, n.Description);
		h = MixText(h, n.Value);
		h = Mix(h, n.HasNumber);
		h = Mix(h, n.Number);
		h = Mix(h, n.Min);
		h = Mix(h, n.Max);
		h = Mix(h, n.Step);
		h = Mix(h, n.Bounds.X);
		h = Mix(h, n.Bounds.Y);
		h = Mix(h, n.Bounds.Width);
		h = Mix(h, n.Bounds.Height);
		h = Mix(h, n.States);
		h = Mix(h, n.Actions);
		h = Mix(h, n.PositionInSet);
		h = Mix(h, n.SetSize);
		h = Mix(h, n.Level);
		h = Mix(h, n.RowCount);
		h = Mix(h, n.ColumnCount);
		h = Mix(h, n.RowIndex);
		h = MixIds(h, n.Children);
		h = MixIds(h, n.LabelledBy);
		h = MixIds(h, n.DescribedBy);
		h = MixIds(h, n.Controls);
		return (h == 0) ? 1 : h;
	}

	public static void ClearMarks(Node node)
	{
		if (!node.IsAccessDirty && !node.HasAccessDirtyDescendant)
			return;
		node.ClearAccessDirty();
		for (int i = 0; i < node.ChildCount; ++i)
		{
			let child = node.GetChildAt(i);
			if (child != null)
				ClearMarks(child);
		}
	}

	// The nodes marked since the last update: each one marked, and the included node above it (its
	// children may have changed), each once.
	public class Changes
	{
		private Builder mBuilder;
		private List<AccessNode> mOut; // borrowed: it owns what is added
		private List<uint64> mSent = new .() ~ delete _;

		public this(Builder builder, List<AccessNode> outNodes)
		{
			mBuilder = builder;
			mOut = outNodes;
		}

		public void Send(Node node)
		{
			let id = AccessIdOf(node);
			if (mSent.Contains(id))
				return;
			mSent.Add(id);
			let described = new AccessNode();
			mBuilder.Describe(node, RoleOf(node), described);
			let hash = HashOf(described);
			if (hash == node.AccessSent)
			{
				delete described; // marked, yet it reads as it did (a fade's frames): nothing to send
				return;
			}
			node.AccessSent = hash;
			mOut.Add(described);
		}

		public void SendItems(ItemView view)
		{
			let items = scope List<AccessNode>();
			mBuilder.Items(view, items);
			for (let item in items)
			{
				let hash = HashOf(item);
				if (view.AccessItemsSent.TryGetValue(item.Id, let was) && (was == hash))
				{
					delete item;
					continue;
				}
				view.AccessItemsSent[item.Id] = hash;
				mOut.Add(item);
			}
		}

		public void Walk(Node node, Node owner)
		{
			if (!node.IsAccessDirty && !node.HasAccessDirtyDescendant)
				return;
			let marked = node.IsAccessDirty;
			let below = node.HasAccessDirtyDescendant;
			let root = node is SceneRoot;
			if (!root && Excluded(node))
			{
				ClearMarks(node);
				if (marked && (owner != null))
					Send(owner); // it left its owner's children
				return;
			}
			node.ClearAccessDirty();
			let role = RoleOf(node);
			if (marked && (owner != null) && (owner != node))
				Send(owner);
			let view = node as ItemView;
			if ((view != null) && (role != .None))
			{
				// Its rows' changes are its items': the view and each item whose node changed.
				Send(node);
				SendItems(view);
				for (int i = 0; i < node.ChildCount; ++i)
				{
					let child = node.GetChildAt(i);
					if (child != null)
						ClearMarks(child);
				}
				return;
			}
			let next = (role != .None) ? node : owner;
			if (IsLeafRole(role))
			{
				if (marked || below)
					Send(node); // a part's change is the leaf's (its name from its label)
				for (int i = 0; i < node.ChildCount; ++i)
				{
					let child = node.GetChildAt(i);
					if (child != null)
						ClearMarks(child);
				}
				return;
			}
			if (marked && (role != .None))
				Send(node);
			for (int i = 0; i < node.ChildCount; ++i)
			{
				let child = node.GetChildAt(i);
				if (child != null)
					Walk(child, next);
			}
		}
	}

	public static uint64 FocusOf(SceneRoot root)
	{
		let focus = root.EventDispatcher.FocusNode;
		// An item view's focus is its current item's: what the keys move is the item.
		if (let view = focus as ItemView)
		{
			if ((view.CurrentItem >= 0) && !Excluded(view) && (RoleOf(view) != .None))
				return ItemAccessId(root, view, view.CurrentItem);
		}
		// The focus as a screen reader sees it: the nearest included node holding it.
		for (var n = focus; n != null; n = n.Parent)
		{
			if ((RoleOf(n) != .None) && !Excluded(n))
			{
				// A part of a leaf (a spin button's field) reads as the leaf.
				var leaf = n;
				for (var up = n.Parent; up != null; up = up.Parent)
				{
					if (IsLeafRole(RoleOf(up)))
						leaf = up;
				}
				return AccessIdOf(leaf);
			}
		}
		return AccessIdOf(root);
	}
}
