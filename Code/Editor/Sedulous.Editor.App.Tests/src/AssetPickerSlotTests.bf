using System;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// Types to ask for a glyph: one with an icon of its own and a category, one taking the generic.
/// AlwaysInclude, so their type data (the attribute) is there to be asked.
[Category("Rendering"), AlwaysInclude]
class SlotGlyphAsset
{
}

[AlwaysInclude]
class SlotPlainAsset
{
}

/// The asset slot: a verb shows once wired (open, reveal and clear only with something referenced), an
/// empty slot says None, each verb runs once per click, a click on the slot picks, and a dragged
/// asset of a type it takes is dropped on it while one it does not take, or several, is refused,
/// saying why. Then what Sedulous adds so each behaviour has a test: open, reveal and clear unwired over a value, the
/// empty look coming back, a slot with no drop callback no target, another payload not refused,
/// the any-asset wildcard, the glyph following the type, and the kept helpers (Accepts and
/// RejectionText) for an owner's own checks and toasts.
class AssetPickerSlotTests
{
	private static readonly Guid sWood = Guid(0x1234, 0x5678, 0, 0, 0, 0, 0, 0, 0, 0, 0);

	/// A slot in a GUI of its own, 400 by 200, its row 200 by 24, with a panel the drags start
	/// from. The root holds both; the bed releases the root.
	private class SlotBed
	{
		public SceneRoot Root;
		public AssetPickerSlot Slot;
		public Panel Source;

		public this()
		{
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(400.0f, 200.0f);
			Slot = new AssetPickerSlot();
			Slot.EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Row; // the sheet's `.slot`, which the test loads none of
					s.Width = LayoutLength.Px(200.0f);
					s.Height = LayoutLength.Px(24.0f);
				});
			Root.AddChild(Slot);
			Slot.ReleaseRef();
			Source = new Panel();
			Root.AddChild(Source);
			Source.ReleaseRef();
			Root.UpdateLayout();
		}

		public ~this()
		{
			Root.ReleaseRef();
		}

		public EventDispatcher D => Root.EventDispatcher;

		/// A point on the slot, left of its verbs.
		public Float2 Over
		{
			get
			{
				let at = Slot.ScreenBounds;
				return .(at.X + 20.0f, at.Y + 12.0f);
			}
		}

		/// A point on the slot past its verbs, which sit at its start in the test's row.
		public Float2 Far
		{
			get
			{
				let at = Slot.ScreenBounds;
				return .(at.X + 190.0f, at.Y + 12.0f);
			}
		}

		/// Drags the asset from the source with the pointer over the slot, and asks there.
		public void DragAsset(Guid id, StringView typeName, StringView name)
		{
			let request = scope DragRequest();
			AssetDrag.Payload(id, typeName, name, request.Payload);
			Start(request);
		}

		/// Drags `assets` (a browser's selection) from the source with the pointer over the slot, and
		/// asks there.
		public void DragAssets(Span<AssetDrag> assets)
		{
			let request = scope DragRequest();
			AssetDrag.Payload(assets, request.Payload);
			Start(request);
		}

		public void Start(DragRequest request)
		{
			D.InjectMouseMove(Over);
			D.StartDrag(Source, request);
			D.RequeryDrag();
		}

		public void Release() => D.InjectMouseUp(Over, .Left);
	}

	[Test]
	public static void TheVerbsShowOnceWiredOpenRevealAndClearOnlyWithSomethingReferencedEmptySaysNone()
	{
		let slot = new AssetPickerSlot();
		defer slot.ReleaseRef();
		Test.Assert(slot.ShownName == "Not set");
		Test.Assert(slot.HasClass("empty"));
		Test.Assert(!slot.HasValue);
		Test.Assert(!slot.PickButton.Displayed);
		int picks = 0;
		int opens = 0;
		int reveals = 0;
		int clears = 0;
		slot.SetOnPick(new [&] () => { picks++; });
		slot.SetOnOpen(new [&] () => { opens++; });
		slot.SetOnReveal(new [&] () => { reveals++; });
		slot.SetOnClear(new [&] () => { clears++; });
		Test.Assert(slot.PickButton.Displayed);
		Test.Assert(!slot.OpenButton.Displayed, "nothing to open yet");
		Test.Assert(!slot.RevealButton.Displayed);
		Test.Assert(!slot.ClearButton.Displayed);

		slot.SetValue("Wood");
		Test.Assert(!slot.HasClass("empty"));
		Test.Assert(slot.HasValue);
		Test.Assert(slot.ShownName == "Wood");
		Test.Assert(slot.OpenButton.Displayed);
		Test.Assert(slot.RevealButton.Displayed);
		Test.Assert(slot.ClearButton.Displayed);

		Test.Assert(slot.PickButton.HandleActivate());
		Test.Assert(slot.OpenButton.HandleActivate());
		Test.Assert(slot.RevealButton.HandleActivate());
		Test.Assert(slot.ClearButton.HandleActivate());
		Test.Assert(picks == 1, "the pick button's click is its own, not the slot's as well");
		Test.Assert(opens == 1);
		Test.Assert(reveals == 1, "reveal runs its own callback, not open's");
		Test.Assert(clears == 1);
	}

	/// Something referenced is not enough: open, reveal and clear wait for their owner too.
	[Test]
	public static void OpenRevealAndClearUnwiredStayHiddenOverAValue()
	{
		let slot = new AssetPickerSlot();
		defer slot.ReleaseRef();
		slot.SetValue("Wood");
		Test.Assert(!slot.PickButton.Displayed);
		Test.Assert(!slot.OpenButton.Displayed);
		Test.Assert(!slot.RevealButton.Displayed);
		Test.Assert(!slot.ClearButton.Displayed);
		slot.SetOnOpen(new () => { });
		Test.Assert(slot.OpenButton.Displayed);
		Test.Assert(!slot.RevealButton.Displayed, "each verb by its own wiring");
		Test.Assert(!slot.ClearButton.Displayed, "each verb by its own wiring");
		slot.SetOnReveal(new () => { });
		Test.Assert(slot.RevealButton.Displayed);
		Test.Assert(!slot.ClearButton.Displayed);
		slot.SetOnClear(new () => { });
		Test.Assert(slot.ClearButton.Displayed);
	}

	/// Cleared, it says None again, looks empty and hides open, reveal and clear.
	[Test]
	public static void ClearedItSaysNoneAgainAndHidesOpenRevealAndClear()
	{
		let slot = new AssetPickerSlot();
		defer slot.ReleaseRef();
		slot.SetOnPick(new () => { });
		slot.SetOnOpen(new () => { });
		slot.SetOnReveal(new () => { });
		slot.SetOnClear(new () => { });
		slot.SetValue("Wood");
		slot.SetValue("");
		Test.Assert(slot.ShownName == "Not set");
		Test.Assert(slot.HasClass("empty"));
		Test.Assert(!slot.HasValue);
		Test.Assert(slot.PickButton.Displayed, "an empty slot keeps pick");
		Test.Assert(!slot.OpenButton.Displayed);
		Test.Assert(!slot.RevealButton.Displayed);
		Test.Assert(!slot.ClearButton.Displayed);
	}

	/// A click on the slot itself (its name lets the pointer through) picks; unwired, it is not
	/// taken.
	[Test]
	public static void AClickOnTheSlotPicks()
	{
		let bed = scope SlotBed();
		int picks = 0;
		bed.Slot.SetOnPick(new [&] () => { picks++; });
		bed.Slot.SetValue("Wood");
		bed.Root.UpdateLayout();
		Test.Assert(bed.Root.OverFind(bed.Far) == bed.Slot, "the point is the slot's, not a verb's");
		bed.D.InjectMouseDown(bed.Far, .Left);
		bed.D.InjectMouseUp(bed.Far, .Left);
		Test.Assert(picks == 1);

		// A right click is not a pick.
		bed.D.InjectMouseDown(bed.Far, .Right);
		bed.D.InjectMouseUp(bed.Far, .Right);
		Test.Assert(picks == 1);
	}

	[Test]
	public static void ADraggedAssetOfATypeItTakesDropsOnItAnotherTypeIsRefusedSayingWhy()
	{
		let bed = scope SlotBed();
		bed.Slot.SetAcceptedTypes(scope StringView[]("MaterialAsset"));
		int dropped = 0;
		Guid assigned = .Empty;
		bed.Slot.SetOnDropped(new [&] (id) =>
			{
				dropped++;
				assigned = id;
			});
		bed.Root.UpdateLayout();

		bed.DragAsset(sWood, "MaterialAsset", "Wood");
		Test.Assert(bed.D.DropTarget == bed.Slot);
		Test.Assert(bed.D.DropEffect == .Link);
		Test.Assert(bed.D.DropReason == "Use Wood");
		bed.Release();
		Test.Assert(dropped == 1);
		Test.Assert(assigned == sWood);

		// Full or short, the type matches as AssetTypeNames.Matches has it.
		bed.DragAsset(sWood, "Sedulous.Materials.MaterialAsset", "Wood");
		Test.Assert(bed.D.DropTarget == bed.Slot);
		bed.Release();
		Test.Assert(dropped == 2);

		bed.DragAsset(Guid(9, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0), "TextureAsset", "Brick");
		Test.Assert(bed.D.DropTarget == null);
		Test.Assert(bed.D.DropReason == "Brick is a TextureAsset, not one this takes");
		bed.Release();
		Test.Assert(dropped == 2, "refused: nothing assigned");
	}

	/// A slot holds one asset: several are refused, saying it takes one, even of a type it takes;
	/// a run of one drops as the one.
	[Test]
	public static void SeveralDraggedAssetsAreRefusedSayingItTakesOne()
	{
		let bed = scope SlotBed();
		bed.Slot.SetAcceptedTypes(scope StringView[]("MaterialAsset"));
		int dropped = 0;
		Guid assigned = .Empty;
		bed.Slot.SetOnDropped(new [&] (id) =>
			{
				dropped++;
				assigned = id;
			});
		bed.Root.UpdateLayout();

		AssetDrag[2] two = .(scope .(sWood, "MaterialAsset", "Wood"), scope .(Guid(9, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0), "MaterialAsset", "Oak"));
		bed.DragAssets(two);
		Test.Assert(bed.D.DropTarget == null);
		Test.Assert(bed.D.DropReason == "This takes one asset");
		bed.Release();
		Test.Assert(dropped == 0, "refused: nothing assigned");

		AssetDrag[1] one = .(scope .(sWood, "MaterialAsset", "Wood"));
		bed.DragAssets(one);
		Test.Assert(bed.D.DropTarget == bed.Slot);
		bed.Release();
		Test.Assert(dropped == 1);
		Test.Assert(assigned == sWood);
	}

	/// Not a target with no one to assign a drop: an asset of any type passes it by, unrefused.
	[Test]
	public static void WithNoDropCallbackItIsNoDropTarget()
	{
		let bed = scope SlotBed();
		bed.Slot.SetAcceptedTypes(scope StringView[]("MaterialAsset"));
		bed.DragAsset(sWood, "MaterialAsset", "Wood");
		Test.Assert(bed.D.DropTarget == null);
		Test.Assert(bed.D.DropReason.IsEmpty);
		bed.D.CancelDrag();
	}

	/// What is not an asset is not the slot's to refuse: the walk goes on past it.
	[Test]
	public static void AnotherPayloadIsNotRefused()
	{
		let bed = scope SlotBed();
		int dropped = 0;
		bed.Slot.SetOnDropped(new [&] (id) => { dropped++; });
		let request = scope DragRequest();
		request.Payload.Type.Set("text");
		request.Payload.Value = TextVariant("hello");
		bed.Start(request);
		Test.Assert(bed.D.DropTarget == null);
		Test.Assert(bed.D.DropReason.IsEmpty, "no refusal: another target may take it");
		bed.Release();
		Test.Assert(dropped == 0);
	}

	/// No types, or the wildcard among them, takes any asset.
	[Test]
	public static void NoTypesOrTheWildcardTakeAnyAsset()
	{
		let bed = scope SlotBed();
		int dropped = 0;
		bed.Slot.SetOnDropped(new [&] (id) => { dropped++; });
		bed.DragAsset(sWood, "TextureAsset", "Brick");
		Test.Assert(bed.D.DropTarget == bed.Slot);
		bed.Release();
		Test.Assert(dropped == 1);

		bed.Slot.SetAcceptedTypes(scope StringView[]("MaterialAsset", AssetPickerSlot.cAnyAsset));
		bed.DragAsset(sWood, "TextureAsset", "Brick");
		Test.Assert(bed.D.DropTarget == bed.Slot);
		bed.Release();
		Test.Assert(dropped == 2);
	}

	/// The glyph is the referenced type's, as EditorIcons finds it: its icon and its category's
	/// class, the class before it taken off; shown only with something referenced.
	[Test]
	public static void TheGlyphFollowsTheType()
	{
		let icons = scope EditorIcons(new (path) => (path == "Editor/Icons/Types/SlotGlyphAsset.svg") || (path == "Editor/Icons/Types/Asset.svg"));
		let slot = new AssetPickerSlot();
		defer slot.ReleaseRef();
		slot.SetGlyph(icons.For(typeof(SlotGlyphAsset), "Asset"));
		Test.Assert(slot.GlyphImage.Source == "Editor/Icons/Types/SlotGlyphAsset.svg");
		Test.Assert(slot.GlyphImage.HasClass("cat-rendering"));
		Test.Assert(!slot.GlyphImage.Displayed, "nothing referenced: no glyph");
		slot.SetValue("Wood");
		Test.Assert(slot.GlyphImage.Displayed);

		slot.SetGlyph(icons.For(typeof(SlotPlainAsset), "Asset"));
		Test.Assert(slot.GlyphImage.Source == "Editor/Icons/Types/Asset.svg");
		Test.Assert(!slot.GlyphImage.HasClass("cat-rendering"), "the old type's tint goes");
		Test.Assert(slot.GlyphImage.HasClass("slot-glyph"));
		Test.Assert(slot.GlyphImage.Displayed);

		slot.SetGlyph("");
		Test.Assert(!slot.GlyphImage.Displayed, "no glyph to show");
	}

	/// The helpers an owner checks a type with and words a refusal's toast with: the wildcard
	/// takes any asset and reads as words; types match full or short; every type taken is named.
	[Test]
	public static void AcceptsAndRejectionTextNameTheTypesAndTheWildcard()
	{
		String[1] materials = .("MaterialAsset");
		Test.Assert(AssetPickerSlot.Accepts(materials, "MaterialAsset"));
		Test.Assert(AssetPickerSlot.Accepts(materials, "Sedulous.Materials.MaterialAsset"));
		Test.Assert(!AssetPickerSlot.Accepts(materials, "TextureAsset"));
		String[1] any = .(AssetPickerSlot.cAnyAsset);
		Test.Assert(AssetPickerSlot.Accepts(any, "TextureAsset"));
		Test.Assert(!AssetPickerSlot.Accepts(Span<String>(), "TextureAsset"));

		String[3] meshes = .("StaticMeshAsset", "SkinnedMeshAsset", AssetPickerSlot.cAnyAsset);
		let three = AssetPickerSlot.RejectionText("brick", "TextureAsset", meshes, "field", .. scope .());
		Test.Assert(three == "brick is a TextureAsset - this field takes StaticMeshAsset, SkinnedMeshAsset or any asset");
		let one = AssetPickerSlot.RejectionText("boom", "AudioClipAsset", materials, "list", .. scope .());
		Test.Assert(one == "boom is an AudioClipAsset - this list takes MaterialAsset");
		let none = AssetPickerSlot.RejectionText("boom", "AudioClipAsset", Span<String>(), "list", .. scope .());
		Test.Assert(none == "boom is an AudioClipAsset - this list takes no asset");
	}

	/// What a slot takes is asked of the reference services (the builders': what makes a Material,
	/// a Texture), so a preview's slot takes every asset that cooks to it; none when they cannot say.
	[Test]
	public static void ItTakesTheTypesTheServicesSayMakeItsTarget()
	{
		let slot = new AssetPickerSlot();
		defer slot.ReleaseRef();
		let refs = scope ResourceRefServices();
		refs.AcceptedTypes = new (target, outTypes) =>
			{
				if (target == typeof(String))
				{
					outTypes.Add(new .("TextureAsset"));
					outTypes.Add(new .("RenderTextureAsset"));
				}
			};
		slot.AcceptTypesOf(refs, typeof(String));
		Test.Assert(slot.AcceptedTypes.Length == 2);
		Test.Assert((slot.AcceptedTypes[0] == "TextureAsset") && (slot.AcceptedTypes[1] == "RenderTextureAsset"));
		slot.AcceptTypesOf(null, typeof(String));
		Test.Assert(slot.AcceptedTypes.IsEmpty);
	}
}
