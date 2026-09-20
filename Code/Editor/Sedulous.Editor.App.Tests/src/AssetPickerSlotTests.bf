using System;
using Sedulous.UI;

namespace Sedulous.Editor.App.Tests;

/// The composite slot is pure widget logic and exercises headlessly: affordances render only
/// when their callback is wired, Edit, Clear and preview disable while the slot is empty, each
/// affordance fires its callback once per click, and drops filter on type.
static class AssetPickerSlotTests
{
	[Test]
	public static void AffordancesRenderOnlyWhenWired()
	{
		// Nothing wired: a plain name button, the entity-ref degradation.
		let bare = new AssetPickerSlot("Thing");
		defer bare.ReleaseRef();
		bare.SetValue("Thing", true);
		Test.Assert(bare.EditButton.Visibility == .Gone);
		Test.Assert(bare.ClearButton.Visibility == .Gone);
		Test.Assert(bare.PreviewButton.Visibility == .Gone);
		Test.Assert(bare.BodyButton.Visibility == .Visible);

		// Fully wired: everything visible.
		let slot = new AssetPickerSlot();
		defer slot.ReleaseRef();
		slot.OnPick = new () => {};
		slot.OnEdit = new () => {};
		slot.OnClear = new () => {};
		slot.OnReveal = new () => {};
		slot.SetValue("MyClip", true);
		Test.Assert(slot.EditButton.Visibility == .Visible);
		Test.Assert(slot.ClearButton.Visibility == .Visible);
		Test.Assert(slot.PreviewButton.Visibility == .Visible);
	}

	[Test]
	public static void EditClearPreviewInertWhileEmptyBodyAlwaysLive()
	{
		let slot = new AssetPickerSlot();
		defer slot.ReleaseRef();
		slot.OnPick = new () => {};
		slot.OnEdit = new () => {};
		slot.OnClear = new () => {};
		slot.OnReveal = new () => {};

		slot.SetValue("", false);
		Test.Assert(slot.BodyButton.IsEnabled, "picking an empty slot is the point");
		Test.Assert(!slot.EditButton.IsEnabled);
		Test.Assert(!slot.ClearButton.IsEnabled);
		Test.Assert(!slot.PreviewButton.IsEnabled);

		slot.SetValue("MyClip", true);
		Test.Assert(slot.EditButton.IsEnabled);
		Test.Assert(slot.ClearButton.IsEnabled);
		Test.Assert(slot.PreviewButton.IsEnabled);
	}

	[Test]
	public static void EachAffordanceFiresExactlyOncePerClick()
	{
		let slot = new AssetPickerSlot();
		defer slot.ReleaseRef();
		int picks = 0;
		int edits = 0;
		int clears = 0;
		int reveals = 0;
		slot.OnPick = new [&]() => { picks++; };
		slot.OnEdit = new [&]() => { edits++; };
		slot.OnClear = new [&]() => { clears++; };
		slot.OnReveal = new [&]() => { reveals++; };
		slot.SetValue("MyClip", true);

		slot.BodyButton.FireClick();
		slot.EditButton.FireClick();
		slot.ClearButton.FireClick();
		slot.PreviewButton.FireClick();
		Test.Assert(picks == 1, "the name body is the pick affordance");
		Test.Assert(edits == 1);
		Test.Assert(clears == 1);
		Test.Assert(reveals == 1);
	}

	[Test]
	public static void EmptyTextRendersTheNonePlaceholder()
	{
		let slot = new AssetPickerSlot();
		defer slot.ReleaseRef();
		slot.SetValue("", false);
		Test.Assert(slot.BodyButton.Text.Value == "(none)");
		slot.SetValue("Grass", true);
		Test.Assert(slot.BodyButton.Text.Value == "Grass");
	}

	[Test]
	public static void DropAcceptsMatchingTypesAndRejectsMismatches()
	{
		let slot = new AssetPickerSlot();
		defer slot.ReleaseRef();
		slot.SetAcceptedTypes(scope StringView[]("TextureAsset"));

		Guid assigned = .Empty;
		int assigns = 0;
		int rejects = 0;
		let rejectedType = scope String();
		slot.OnAssignDropped = new [&](id) => { assigned = id; assigns++; };
		slot.OnRejectedDrop = new [&](name, typeName) => { rejects++; rejectedType.Set(typeName); };

		// A drop target with accepted types.
		Test.Assert(slot.AsDropTarget() === slot);

		// A matching type: hover accepts, drop assigns exactly once.
		let id = Guid.Create();
		let match = new AssetDragData(id, "TextureAsset", "Grass");
		defer match.ReleaseRef();
		Test.Assert(slot.CanAcceptDrop(match, 0, 0) == .Link);
		Test.Assert(slot.OnDrop(match, 0, 0) == .Link);
		Test.Assert(assigns == 1);
		Test.Assert(assigned == id);
		Test.Assert(rejects == 0);

		// The wrong type: hover still engages so OnDrop can warn, the drop rejects, no assign.
		let wrong = new AssetDragData(Guid.Create(), "AudioClipAsset", "Boom");
		defer wrong.ReleaseRef();
		Test.Assert(slot.CanAcceptDrop(wrong, 0, 0) == .Link);
		Test.Assert(slot.OnDrop(wrong, 0, 0) == .None);
		Test.Assert(assigns == 1);
		Test.Assert(rejects == 1);
		Test.Assert(rejectedType == "AudioClipAsset");

		// A non-asset payload never engages.
		let foreign = new DragData("view/reorder");
		defer foreign.ReleaseRef();
		Test.Assert(slot.CanAcceptDrop(foreign, 0, 0) == .None);
	}

	[Test]
	public static void NoAcceptedTypesMeansNotADropTarget()
	{
		let slot = new AssetPickerSlot();
		defer slot.ReleaseRef();
		Test.Assert(slot.AsDropTarget() == null);
	}
}
