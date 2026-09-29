using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App.Tests;

/// The one list widget and the one asset row, headless: a drop on a slot assigns it, a drop on
/// the list appends, a wrong type is refused and reported, the add icon appends or defers to its
/// menu, a section list is its header alone with element icons for the sections, and a
/// ResourceRefEditor's pick, drop and clear are one assignment.
static class ContainerListEditorTests
{
	private static readonly Guid cMaterial = Guid(0x1111, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
	private static readonly Guid cTexture = Guid(0x2222, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);

	private static AssetDragData Drag(Guid id, StringView typeName) => new AssetDragData(id, typeName, "dragged");

	/// The slot of element `index`: the column's rows follow the header.
	private static AssetPickerSlot SlotAt(View column, int index) =>
		((column as ViewGroup).GetChildAt(1 + index) as ViewGroup).GetChildAt(0) as AssetPickerSlot;

	private static IconButton AddIcon(View column) =>
		((column as ViewGroup).GetChildAt(0) as ViewGroup).GetChildAt(1) as IconButton;

	[Test]
	public static void ADropOnASlotAssignsItAndADropOnTheListAppends()
	{
		let list = scope ContainerListEditor("Materials", "Mesh");
		list.SlotNames.Add(new .("Red"));
		list.SlotNames.Add(new .("(none)"));
		list.SetAcceptedTypes(scope StringView[]("MaterialAsset"));
		int assignedIndex = -1;
		Guid assigned = .();
		Guid appended = .();
		String rejected = scope .();
		list.OnAssignSlot = new [&](i, id) => { assignedIndex = i; assigned = id; };
		list.OnAppendDropped = new [&](id) => { appended = id; };
		list.OnRejectedDrop = new [&](name, typeName) => { rejected.Set(typeName); };
		let column = list.EditorView;

		// On slot 1: that element.
		let slot = SlotAt(column, 1);
		Test.Assert(slot.AsDropTarget() != null, "a typed list's slots are drop targets");
		let material = Drag(cMaterial, "MaterialAsset");
		defer material.ReleaseRef();
		Test.Assert(slot.OnDrop(material, 0, 0) == .Link);
		Test.Assert((assignedIndex == 1) && (assigned == cMaterial));

		// On the list itself (the header, a gap, an empty list): appended.
		let zone = column.AsDropTarget();
		Test.Assert(zone != null);
		Test.Assert(zone.OnDrop(material, 0, 0) == .Link);
		Test.Assert(appended == cMaterial);

		// A texture is refused on both, and reported.
		let texture = Drag(cTexture, "TextureAsset");
		defer texture.ReleaseRef();
		assignedIndex = -1;
		Test.Assert(slot.OnDrop(texture, 0, 0) == .None);
		Test.Assert(assignedIndex == -1);
		Test.Assert(rejected == "TextureAsset");
		rejected.Clear();
		appended = .();
		Test.Assert(zone.OnDrop(texture, 0, 0) == .None);
		Test.Assert(appended.IsNil && (rejected == "TextureAsset"));
	}

	[Test]
	public static void AnUntypedListTakesNoDropAndTheWildcardTakesAny()
	{
		let untyped = scope ContainerListEditor("Things", "Cat");
		untyped.SlotNames.Add(new .("a"));
		untyped.OnAppendDropped = new (id) => {};
		Test.Assert(SlotAt(untyped.EditorView, 0).AsDropTarget() == null);
		Test.Assert(untyped.EditorView.AsDropTarget() == null);

		let any = scope ContainerListEditor("Anything", "Cat");
		any.SlotNames.Add(new .("a"));
		any.SetAcceptedTypes(scope StringView[](AssetPickerSlot.cAnyAsset));
		Guid assigned = .();
		any.OnAssignSlot = new [&](i, id) => { assigned = id; };
		let texture = Drag(cTexture, "TextureAsset");
		defer texture.ReleaseRef();
		Test.Assert(SlotAt(any.EditorView, 0).OnDrop(texture, 0, 0) == .Link);
		Test.Assert(assigned == cTexture);
	}

	[Test]
	public static void TheAddIconAppendsOrDefersToItsMenu()
	{
		let list = scope ContainerListEditor("Things", "Cat");
		int adds = 0;
		list.OnAdd = new [&]() => { adds++; };
		AddIcon(list.EditorView).FireClick();
		Test.Assert(adds == 1);

		// With a menu, the icon opens it (headless: no context to open in) and does not append.
		let menued = scope ContainerListEditor("Behaviors", "Cat");
		int menuAdds = 0;
		menued.OnAdd = new [&]() => { menuAdds++; };
		menued.OnAddMenu = new (menu) => { menu.AddItem("Kind", new () => {}); };
		AddIcon(menued.EditorView).FireClick();
		Test.Assert(menuAdds == 0);
	}

	[Test]
	public static void ASectionListIsItsHeaderAndItsElementsCarryTheirOwnIcons()
	{
		let list = scope ContainerListEditor("Behaviors", "Script");
		list.ElementsAsSections = true;
		list.SlotNames.Add(new .("Mover"));
		list.SlotNames.Add(new .("Spinner"));
		let column = list.EditorView as ViewGroup;
		Test.Assert(column.ChildCount == 1, "the header alone: the elements are sections");
		let count = (column.GetChildAt(0) as ViewGroup).GetChildAt(0) as Label;
		Test.Assert(count.Text.Value == "2 items");

		// A section's header icons: up, down, remove, each reporting its element.
		int moved = -1;
		bool movedUp = false;
		int removed = -1;
		let first = ContainerListEditor.ElementActions(0, 2, new [&](i, up) => { moved = i; movedUp = up; }, new [&](i) => { removed = i; }) as ViewGroup;
		defer first.ReleaseRef();
		Test.Assert(!(first.GetChildAt(0) as IconButton).IsEnabled, "the first element cannot move up");
		Test.Assert((first.GetChildAt(1) as IconButton).IsEnabled);
		(first.GetChildAt(1) as IconButton).FireClick();
		Test.Assert((moved == 0) && !movedUp);
		(first.GetChildAt(2) as IconButton).FireClick();
		Test.Assert(removed == 0);
		let last = ContainerListEditor.ElementActions(1, 2, new (i, up) => {}, new (i) => {}) as ViewGroup;
		defer last.ReleaseRef();
		Test.Assert(!(last.GetChildAt(1) as IconButton).IsEnabled, "the last element cannot move down");
	}

	[Test]
	public static void AResourceRowsPickDropAndClearAreOneAssignment()
	{
		let context = scope EditorContext();
		Guid current = .();
		let writes = scope List<Guid>();
		let row = scope ResourceRefEditor("Material", "(none)", "Mesh", scope StringView[]("MaterialAsset"));
		row.BindAsset(context, new [&]() => current, new [&](id) => { current = id; writes.Add(id); });
		let slot = row.EditorView as AssetPickerSlot;
		Test.Assert(slot.AsDropTarget() != null, "a typed row is a drop target from construction");

		// A drop assigns through the bound write; a wrong type does not.
		let material = Drag(cMaterial, "MaterialAsset");
		defer material.ReleaseRef();
		Test.Assert(slot.OnDrop(material, 0, 0) == .Link);
		Test.Assert((writes.Count == 1) && (current == cMaterial));
		let texture = Drag(cTexture, "TextureAsset");
		defer texture.ReleaseRef();
		Test.Assert(slot.OnDrop(texture, 0, 0) == .None);
		Test.Assert(writes.Count == 1);

		// Clear is the same write, with the nil id; the row names what it now holds.
		slot.ClearButton.FireClick();
		Test.Assert((writes.Count == 2) && current.IsNil);
		Test.Assert(row.ValueText == "(none)");

		// A dangling id reads "(missing)" and stays clearable.
		current = cTexture;
		row.Refresh();
		Test.Assert(row.ValueText == "(missing)");
		Test.Assert(slot.ClearButton.IsEnabled);

		// A bound row's empty text is what the slot shows for nil, not a fixed "(none)".
		let preview = scope ResourceRefEditor("Material", "(none)", "Mesh", scope StringView[]("MaterialAsset"));
		preview.EmptyText.Set("Default");
		preview.BindAsset(context, new () => Guid(), new (id) => {});
		Test.Assert((preview.EditorView as AssetPickerSlot).BodyButton.Text.Value == "Default");

		// A row that is no asset (an entity reference) takes no asset drop.
		let entityRow = scope ResourceRefEditor("Target", "(none)", "Joint", .());
		Test.Assert((entityRow.EditorView as AssetPickerSlot).AsDropTarget() == null);
	}

	[Test]
	public static void AnEntitySlotTakesAHierarchyRowAndNoAsset()
	{
		Guid current = .();
		let row = scope ResourceRefEditor("Target", "(none)", "Follow", scope StringView[](AssetPickerSlot.cEntity));
		row.BindEntity(new [&]() => current, new [&](id) => { current = id; },
			new (id, outName) => { outName.Set("Cart"); }, new () => {});
		let slot = row.EditorView as AssetPickerSlot;
		Test.Assert(slot.AsDropTarget() != null, "an entity row is a drop target");

		// A hierarchy row that names its entity is assigned.
		let entity = new TreeDragData(0);
		defer entity.ReleaseRef();
		entity.ItemKind.Set("entity");
		entity.ItemId = cMaterial;
		entity.ItemName.Set("Cart");
		Test.Assert(slot.OnDrop(entity, 0, 0) == .Link);
		Test.Assert((current == cMaterial) && (row.ValueText == "Cart"));

		// An asset is refused, and so is a tree row that names nothing.
		let material = Drag(cTexture, "MaterialAsset");
		defer material.ReleaseRef();
		Test.Assert(slot.OnDrop(material, 0, 0) == .None);
		let bare = new TreeDragData(0);
		defer bare.ReleaseRef();
		Test.Assert(slot.CanAcceptDrop(bare, 0, 0) == .None);
		Test.Assert(current == cMaterial);

		// Clear is the same write, with the nil id.
		slot.ClearButton.FireClick();
		Test.Assert(current.IsNil && (row.ValueText == "(none)"));

		// An asset slot, even the any asset one, refuses an entity.
		let any = scope ResourceRefEditor("Thing", "(none)", "Cat", scope StringView[](AssetPickerSlot.cAnyAsset));
		Test.Assert((any.EditorView as AssetPickerSlot).OnDrop(entity, 0, 0) == .None);

		// An entity list takes one on a slot and appends one.
		let list = scope ContainerListEditor("Targets", "Follow");
		list.SlotNames.Add(new .("(none)"));
		list.SetAcceptedTypes(scope StringView[](AssetPickerSlot.cEntity));
		Guid assigned = .();
		Guid appended = .();
		list.OnAssignSlot = new [&](i, id) => { assigned = id; };
		list.OnAppendDropped = new [&](id) => { appended = id; };
		Test.Assert(SlotAt(list.EditorView, 0).OnDrop(entity, 0, 0) == .Link);
		Test.Assert(list.EditorView.AsDropTarget().OnDrop(entity, 0, 0) == .Link);
		Test.Assert((assigned == cMaterial) && (appended == cMaterial));
		Test.Assert(list.EditorView.AsDropTarget().OnDrop(material, 0, 0) == .None);
	}

	/// A ResourceRefEditor's view placed in a plain layout, outside a grid, holds a reference
	/// of its own: the layout and the editor each release theirs, and tearing both down is
	/// balanced (it double released before, and the settings dialog asserted on close).
	[Test]
	public static void AnAssetRowOutsideAGridTearsDownBalanced()
	{
		let context = scope EditorContext();
		Guid current = .();
		let slot = new CompactAssetSlot("Mesh", scope StringView[]("StaticMeshAsset"));
		slot.Editor.BindAsset(context, new [&]() => current, new [&](id) => { current = id; });
		slot.Build();
		slot.ReleaseRef();

		let dialog = new ProjectSettingsDialog(context);
		dialog.ReleaseRef();
	}
}
