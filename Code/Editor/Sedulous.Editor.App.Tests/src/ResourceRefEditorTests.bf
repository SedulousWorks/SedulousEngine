using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// What a reference row points at in these tests: the type the services are asked about.
class RefTestMesh
{
}

/// What stands for an asset type the builders' join names for RefTestMesh: its name is what is
/// asked.
class RefTestMeshAsset
{
}

/// The inspector's asset reference on the property grid: a Reference row is an asset slot taking
/// the types its services name for what the reference points at, showing the asset's name and
/// glyph (None for nothing, "(missing)" for a dangling id, Mixed over objects that differ); a pick,
/// a drop and a clear are one write each; open and reveal name the asset; a read-only one only
/// opens; and the context's table asks the builders' join and routes open and reveal. Then what
/// Sedulous adds so each behaviour has a test: a pick answered after the row was rebound to another
/// property is dropped, and a read-only row is no drop target.
class ResourceRefEditorTests
{
	private static readonly Guid sWood = Guid(0x1234, 0x5678, 0, 0, 0, 0, 0, 0, 0, 0, 0);
	private static readonly Guid sLost = Guid(9, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0);

	/// A grid 300 by 240 in a root 400 by 300, over a bag of `objects` objects, its Reference rows
	/// this editor over the bed's own services, and a panel the drags start from.
	private class Bed
	{
		public SceneRoot Root;
		public PropertyGrid Grid;
		public Sedulous.GUI.PropertyBag Bag;
		public ResourceRefServices Services = new .();
		public Panel Source;
		public List<Guid> Opened = new .();
		public List<Guid> Revealed = new .();
		/// The picker's answer, held until the test gives it (the picker owns it).
		public delegate void(Guid id) Chosen;
		public List<String> PickedFrom = new .();
		public int Commits = 0;

		public this(int objects = 1)
		{
			Bag = new Sedulous.GUI.PropertyBag(objects);
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(400.0f, 300.0f);
			Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
			Grid = new PropertyGrid();
			Grid.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(300.0f);
					s.Height = LayoutLength.Px(240.0f);
				});
			Root.AddChild(Grid);
			Source = new Panel();
			Root.AddChild(Source);
			Source.ReleaseRef();

			Services.AcceptedTypes = new (target, outTypes) =>
				{
					if (target == typeof(RefTestMesh))
					{
						outTypes.Add(new String("ModelAsset"));
						outTypes.Add(new String("MeshAsset"));
					}
				};
			Services.Describe = new (id, outShown) =>
				{
					if (id != sWood)
						return false;
					outShown.Name.Set("Wood");
					outShown.Glyph.Set("Editor/Icons/Types/MeshAsset.svg");
					outShown.GlyphClass.Set("cat-rendering");
					return true;
				};
			Services.Pick = new [=this] (types, answer) =>
				{
					ClearAndDeleteItems!(PickedFrom);
					for (let type in types)
						PickedFrom.Add(new String(type));
					delete Chosen;
					Chosen = answer;
				};
			Services.Open = new [=this] (id) => { Opened.Add(id); };
			Services.Reveal = new [=this] (id) => { Revealed.Add(id); };
			ResourceRefEditor.Register(Grid.Editors, Services);
			Grid.Refresh();
			Bag.SetOnCommit(new [=this] (commit) => { Commits++; });
		}

		public ~this()
		{
			delete Chosen; // lets go of the row the picker held
			Grid.Source = null;
			Grid.ReleaseRef();
			Root.ReleaseRef();
			delete Bag;
			delete Services; // after the grid: its editors borrow it
			delete Opened;
			delete Revealed;
			DeleteContainerAndItems!(PickedFrom);
		}

		public PropertyInfo Add(StringView path, Guid value)
		{
			let text = scope String();
			if (!value.IsNil)
				value.ToString(text);
			let info = Bag.Add(path, .Reference, Sedulous.GUI.Variant(text));
			info.ReferenceType = typeof(RefTestMesh);
			return info;
		}

		public void Show()
		{
			Grid.Source = Bag;
			Root.UpdateLayout();
		}

		public ResourceRefEditor Editor(StringView path)
		{
			let editor = Grid.FindEditor(path) as ResourceRefEditor;
			Test.Assert(editor != null, "a Reference row is this editor");
			return editor;
		}

		/// Whether object `object`'s value at `path` is `expected`.
		public bool TextIs(StringView path, int object, StringView expected)
		{
			var value = Bag.GetValue(path, object);
			defer value.Dispose();
			return value.AsString == expected;
		}

		public EventDispatcher D => Root.EventDispatcher;
	}

	private static String Text(Guid id, String outText)
	{
		id.ToString(outText);
		return outText;
	}

	[Test]
	public static void AReferenceRowIsASlotTakingTheTypesForItsTargetNoneThenTheAssetsNameAndGlyph()
	{
		let bed = scope Bed();
		bed.Add("mesh", .Empty);
		bed.Add("other", sLost);
		bed.Show();
		let mesh = bed.Editor("mesh");
		let slot = mesh.Slot;
		Test.Assert(slot.AcceptedTypes.Length == 2);
		Test.Assert(slot.AcceptedTypes[0] == "ModelAsset");
		Test.Assert(slot.AcceptedTypes[1] == "MeshAsset");
		Test.Assert(slot.ShownName == "None");
		Test.Assert(!slot.HasValue);
		Test.Assert(slot.PickButton.Displayed);
		Test.Assert(!slot.ClearButton.Displayed);
		let other = bed.Editor("other").Slot;
		Test.Assert(other.ShownName == ResourceRefEditor.cMissingText, "dangling: says so");
		Test.Assert(other.ClearButton.Displayed, "dangling: still cleared");
		Test.Assert(other.PickButton.Displayed, "dangling: still replaced");
		Test.Assert(!other.GlyphImage.Displayed);

		// A pick: over the row's types, one write, the slot showing the asset and its glyph.
		slot.Pick();
		Test.Assert(bed.Chosen != null);
		Test.Assert(bed.PickedFrom.Count == 2);
		Test.Assert(bed.PickedFrom[0] == "ModelAsset");
		Test.Assert(bed.Commits == 0, "a pick opened is no write");
		bed.Chosen(sWood);
		bed.Root.UpdateLayout();
		Test.Assert(bed.Commits == 1, "a pick is one undo step");
		Test.Assert(bed.TextIs("mesh", 0, Text(sWood, .. scope .())));
		Test.Assert(mesh.Current == sWood);
		Test.Assert(slot.ShownName == "Wood");
		Test.Assert(slot.GlyphImage.Source == "Editor/Icons/Types/MeshAsset.svg");
		Test.Assert(slot.GlyphImage.HasClass("cat-rendering"));
		Test.Assert(slot.GlyphImage.Displayed);

		// Open and reveal name it; a clear is one write to nothing.
		Test.Assert(slot.OpenButton.Displayed);
		Test.Assert(slot.RevealButton.Displayed);
		Test.Assert(slot.OpenButton.HandleActivate());
		Test.Assert(slot.RevealButton.HandleActivate());
		Test.Assert(bed.Opened.Count == 1);
		Test.Assert(bed.Opened[0] == sWood);
		Test.Assert(bed.Revealed.Count == 1, "reveal shows it, open does not");
		Test.Assert(bed.Revealed[0] == sWood);
		Test.Assert(bed.Commits == 1, "open and reveal write nothing");
		Test.Assert(slot.ClearButton.HandleActivate());
		bed.Root.UpdateLayout();
		Test.Assert(bed.Commits == 2, "a clear is one undo step");
		Test.Assert(bed.TextIs("mesh", 0, ""));
		Test.Assert(mesh.Current.IsNil);
		Test.Assert(slot.ShownName == "None");
		Test.Assert(!slot.GlyphImage.Displayed);
	}

	[Test]
	public static void ADroppedAssetIsOneWriteAReadOnlyOneOnlyOpensObjectsThatDifferAreMixed()
	{
		let bed = scope Bed(2);
		bed.Add("mesh", .Empty);
		bed.Add("fixed", sWood).ReadOnly = true;
		bed.Add("both", .Empty);
		bed.Bag.SetValue("both", 1, Sedulous.GUI.Variant(Text(sWood, .. scope .())));
		bed.Show();

		// A drop goes through the slot's drop target, the same write as a pick.
		let node = bed.Editor("mesh").Slot;
		var at = node.ScreenBounds;
		var over = Float2(at.X + 10.0f, at.Y + at.Height * 0.5f);
		let request = scope DragRequest();
		AssetDrag.Payload(sWood, "MeshAsset", "Wood", request.Payload);
		bed.D.InjectMouseMove(over);
		bed.D.StartDrag(bed.Source, request);
		bed.D.RequeryDrag();
		Test.Assert(bed.D.DropReason == "Use Wood");
		bed.D.InjectMouseUp(over, .Left);
		bed.Root.UpdateLayout();
		Test.Assert(bed.Commits == 1, "a drop is one undo step");
		Test.Assert(bed.TextIs("mesh", 0, Text(sWood, .. scope .())));
		Test.Assert(bed.TextIs("mesh", 1, Text(sWood, .. scope .())), "each object");

		// Read only: it shows and opens, and neither picks, clears nor takes a drop.
		let fixedEditor = bed.Editor("fixed");
		let fixedSlot = fixedEditor.Slot;
		Test.Assert(fixedSlot.ShownName == "Wood");
		Test.Assert(!fixedSlot.PickButton.Displayed);
		Test.Assert(!fixedSlot.ClearButton.Displayed);
		Test.Assert(fixedSlot.OpenButton.Displayed);
		Test.Assert(fixedSlot.OpenButton.HandleActivate());
		Test.Assert(bed.Opened.Count == 1);
		Test.Assert(bed.Opened[0] == sWood);
		at = fixedSlot.ScreenBounds;
		over = Float2(at.X + 10.0f, at.Y + at.Height * 0.5f);
		let again = scope DragRequest();
		AssetDrag.Payload(sLost, "MeshAsset", "Brick", again.Payload);
		bed.D.InjectMouseMove(over);
		bed.D.StartDrag(bed.Source, again);
		bed.D.RequeryDrag();
		Test.Assert(bed.D.DropTarget != fixedSlot, "read only: no drop target");
		bed.D.InjectMouseUp(over, .Left);
		bed.Root.UpdateLayout();
		Test.Assert(bed.Commits == 1, "nothing written over a read-only row");
		Test.Assert(bed.TextIs("fixed", 0, Text(sWood, .. scope .())));

		// Objects that differ: Mixed, cleared to one, but neither opened nor revealed (which one?).
		let both = bed.Editor("both").Slot;
		Test.Assert(both.ShownName == MixedValueText());
		Test.Assert(bed.Editor("both").Current.IsNil);
		Test.Assert(!both.OpenButton.Displayed, "which one?");
		Test.Assert(!both.RevealButton.Displayed);
		Test.Assert(both.ClearButton.Displayed);
		Test.Assert(both.PickButton.Displayed);
	}

	/// Rows are pooled: a pick answered after its row was rebound to another property lands
	/// nowhere, rather than on the property the row shows now.
	[Test]
	public static void APickAnsweredAfterTheRowWasReboundIsDropped()
	{
		let bed = scope Bed();
		bed.Add("mesh", .Empty);
		bed.Add("other", .Empty);
		bed.Show();
		let mesh = bed.Editor("mesh");
		mesh.Slot.Pick();
		Test.Assert(bed.Chosen != null);

		// The row now shows "other", as a pooled row does after a scroll or a rebuild.
		var value = bed.Grid.ReadPropertyValue("other", .Reference);
		mesh.Bind(bed.Grid, "other", bed.Bag.FindInfo("other"), value);
		value.Dispose();
		Test.Assert(mesh.Path == "other");

		bed.Chosen(sWood);
		bed.Root.UpdateLayout();
		Test.Assert(bed.Commits == 0, "the stale answer is dropped");
		Test.Assert(bed.TextIs("other", 0, ""));
		Test.Assert(bed.TextIs("mesh", 0, ""));
	}

	[Test]
	public static void TheContextsTableAsksTheBuildersJoinForTheTypesAndRoutesOpenAndReveal()
	{
		let context = scope EditorContext();
		let icons = scope EditorIcons(new (path) => false);
		context.SourceAssetTypesOf = new (product, outAssets) =>
			{
				if (product == typeof(RefTestMesh))
					outAssets.Add(typeof(RefTestMeshAsset));
			};
		let opened = scope List<Guid>();
		let revealed = scope List<Guid>();
		context.OpenAsset = new [=opened] (id) => { opened.Add(id); };
		context.RevealAsset = new [=revealed] (id) => { revealed.Add(id); };
		let services = ResourceRefServices.From(context, icons);
		defer delete services;

		let types = scope List<String>();
		defer { ClearAndDeleteItems!(types); }
		services.AcceptedTypes(typeof(RefTestMesh), types);
		Test.Assert(types.Count == 1);
		Test.Assert(types[0] == "RefTestMeshAsset");
		ClearAndDeleteItems!(types);
		services.AcceptedTypes(typeof(float), types);
		Test.Assert(types.IsEmpty, "nothing the builders make it from");

		let shown = scope ResourceRefShown();
		Test.Assert(!services.Describe(Guid(1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0), shown), "no project: nothing is there");
		Test.Assert(services.Pick == null, "the picker comes with the small dialogs");
		services.Open(Guid(1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0));
		services.Reveal(Guid(3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0));
		Test.Assert(opened.Count == 1);
		Test.Assert(opened[0] == Guid(1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0));
		Test.Assert(revealed.Count == 1);
		Test.Assert(revealed[0] == Guid(3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0));

		// Unwired, the join names nothing: the row takes any asset, as an empty list does.
		delete context.SourceAssetTypesOf;
		context.SourceAssetTypesOf = null;
		ClearAndDeleteItems!(types);
		services.AcceptedTypes(typeof(RefTestMesh), types);
		Test.Assert(types.IsEmpty);
	}
}
