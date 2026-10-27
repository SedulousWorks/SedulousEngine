using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The asset types of the asset picker's project. AlwaysInclude, so their type data (the name the
/// registry resolves, the category) is there to be asked.
[Category("Rendering"), AlwaysInclude]
class PickMeshAsset
{
}

[AlwaysInclude]
class PickSoundAsset
{
}

/// The asset picker's request (Sedulous adds these so each behaviour has a test; Raptor's are in
/// ResourceRefEditorTests): only the assets of the types taken, by short or full name, the wildcard
/// or none taking any; each under its group, Content for the top, in the groups' name order; its type
/// beside its name and its type's glyph and tint; the favourites starred and listed first; the
/// current one checked and lit; None allowed and picking nothing; and with none of the types, the
/// empty state naming them.
static class AssetPickerTests
{
	/// A scratch project: Crate (a mesh) at the top; Zoo/Bear (a mesh); Attic/Bell (a sound),
	/// Attic/Lamp and Attic/Inner/Lid (meshes). Zoo is made before Attic, so only the database's
	/// order puts Attic first.
	private class ProjectBed
	{
		public String Dir = new .("scratch_asset_picker") ~ delete _;
		public EditorProject Project;
		public EditorPageRegistry Registry = new .() ~ delete _;
		public EditorIcons Icons;
		public List<Guid> Favourites = new .() ~ delete _;
		public String MeshName = new .() ~ delete _;
		public String SoundName = new .() ~ delete _;
		public Guid Crate;
		public Guid Bear;
		public Guid Bell;
		public Guid Lamp;
		public Guid Lid;

		public this()
		{
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "Picks") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			// The mesh has an icon of its own; the sound takes the generic asset's.
			Icons = new EditorIcons(new (path) => (path == "Editor/Icons/Types/PickMeshAsset.svg") || (path == "Editor/Icons/Types/Asset.svg"));
			typeof(PickMeshAsset).GetFullName(MeshName);
			typeof(PickSoundAsset).GetFullName(SoundName);
			let top = Project.SourceDb.RootGroup;
			Crate = top.CreateInstance("Crate", MeshName).Id;
			let zoo = top.CreateGroup("Zoo");
			Bear = zoo.CreateInstance("Bear", MeshName).Id;
			let attic = top.CreateGroup("Attic");
			Bell = attic.CreateInstance("Bell", SoundName).Id;
			Lamp = attic.CreateInstance("Lamp", MeshName).Id;
			Lid = attic.CreateGroup("Inner").CreateInstance("Lid", MeshName).Id;
		}

		public ~this()
		{
			delete Icons;
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The request over `types`, `current` checked. The caller's.
		public PickerRequest Request(Span<String> types, Guid current = default) =>
			AssetPicker.Request(Project.SourceDb, Icons, Registry, Favourites, types, current);
	}

	/// The picker in a GUI scene of its own, 800 by 600, and what it picked.
	private class PickerBed
	{
		public SceneRoot Root;
		public Picker View;
		public List<String> Picked = new .() ~ DeleteContainerAndItems!(_);

		public this()
		{
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(800.0f, 600.0f);
			View = new Picker(PagesBed.LoadMarkup(Picker.cMarkupPath));
			Test.Assert(View.Content != null);
		}

		public ~this()
		{
			DeleteAndNullify!(View); // closed while the root is there
			Root.ReleaseRef();
		}

		/// Opens it for `request` (taken), what it picks into Picked, its list sized so it realises
		/// its rows, laid out.
		public void Open(PickerRequest request)
		{
			request.OnPicked = new [=this] (key) => { Picked.Add(new String(key)); };
			Test.Assert(View.Open(Root, request));
			View.List.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(400.0f);
					s.Height = LayoutLength.Px(400.0f);
				});
			// Twice: the popup is sized by what it holds, then what it holds is placed in it.
			Root.UpdateLayout();
			Root.UpdateLayout();
		}

		/// The rows shown, a heading marked #.
		public void Rows(String outText)
		{
			for (int32 i < (int32)View.RowCount)
			{
				if (!outText.IsEmpty)
					outText.Append(" ");
				if (View.IsHeader(i))
					outText.Append("#");
				outText.Append(View.RowText(i));
			}
		}

		/// The item row showing `item`; null when it is a heading or not realised.
		public PickerRow ShownRow(int32 item)
		{
			let row = View.List.RowForItem(item);
			return (row != null) ? (row.Content as PickerRow) : null;
		}
	}

	/// What the picker answers for `id`, into `outKey`.
	private static String Key(Guid id, String outKey) => AssetPicker.KeyOf(id, .. outKey);

	[Test]
	public static void OnlyTheAssetsOfTheTypesTakenByShortOrFullNameTheWildcardOrNoneTakingAny()
	{
		let bed = scope ProjectBed();
		String[1] meshes = .("PickMeshAsset");
		let byShort = bed.Request(meshes);
		defer delete byShort;
		Test.Assert(byShort.Items.Count == 4, "the sound is not one it takes");
		for (let item in byShort.Items)
			Test.Assert(item.Key != Key(bed.Bell, .. scope .()));

		String[1] full = .(bed.MeshName);
		let byFull = bed.Request(full);
		defer delete byFull;
		Test.Assert(byFull.Items.Count == 4);

		String[1] sounds = .("PickSoundAsset");
		let soundOnly = bed.Request(sounds);
		defer delete soundOnly;
		Test.Assert(soundOnly.Items.Count == 1);
		Test.Assert(soundOnly.Items[0].Name == "Bell");

		String[2] wild = .("PickSoundAsset", AssetPickerSlot.cAnyAsset);
		let any = bed.Request(wild);
		defer delete any;
		Test.Assert(any.Items.Count == 5, "the wildcard takes any");
		let none = bed.Request(Span<String>());
		defer delete none;
		Test.Assert(none.Items.Count == 5, "none named takes any");

		Test.Assert(AssetPicker.Takes(bed.MeshName, meshes));
		Test.Assert(!AssetPicker.Takes(bed.SoundName, meshes));
		Test.Assert(AssetPicker.Takes(bed.SoundName, Span<String>()));
	}

	[Test]
	public static void EachUnderItsGroupContentForTheTopInTheGroupsNameOrder()
	{
		let bed = scope ProjectBed();
		String[1] meshes = .("PickMeshAsset");
		let request = bed.Request(meshes);
		defer delete request;
		Test.Assert(request.Items.Count == 4);
		Test.Assert(request.Items[0].Name == "Crate");
		Test.Assert(request.Items[0].Section == AssetPicker.cTopGroup);
		Test.Assert(request.Items[0].Section == "Content");
		Test.Assert(request.Items[1].Name == "Lamp");
		Test.Assert(request.Items[1].Section == "Attic", "Attic before Zoo, though made after it");
		Test.Assert(request.Items[2].Name == "Lid");
		Test.Assert(request.Items[2].Section == "Attic/Inner", "a nested group by its path");
		Test.Assert(request.Items[3].Name == "Bear");
		Test.Assert(request.Items[3].Section == "Zoo");
		Test.Assert(request.Items[0].Key == Key(bed.Crate, .. scope .()), "its key is its guid as text");
		Test.Assert(request.Placeholder == "Search assets");

		let picker = scope PickerBed();
		picker.Open(bed.Request(meshes));
		Test.Assert(picker.Rows(.. scope .()) == "#Content Crate #Attic Lamp #Attic/Inner Lid #Zoo Bear");
	}

	[Test]
	public static void ItsTypeBesideItsNameAndItsTypesGlyphAndTint()
	{
		let bed = scope ProjectBed();
		let request = bed.Request(Span<String>());
		defer delete request;
		PickerItem crate = null;
		PickerItem bell = null;
		for (let item in request.Items)
		{
			if (item.Name == "Crate")
				crate = item;
			else if (item.Name == "Bell")
				bell = item;
		}
		Test.Assert((crate != null) && (bell != null));
		Test.Assert(crate.Detail == "PickMeshAsset", "the type's short name");
		Test.Assert(bell.Detail == "PickSoundAsset");
		Test.Assert(crate.Glyph == "Editor/Icons/Types/PickMeshAsset.svg");
		Test.Assert(crate.GlyphClass == "cat-rendering");
		Test.Assert(bell.Glyph == "Editor/Icons/Types/Asset.svg", "no icon of its own: the generic asset's");
		Test.Assert(bell.GlyphClass.IsEmpty, "no category: no tint");

		// As the row shows it.
		let picker = scope PickerBed();
		picker.Open(bed.Request(Span<String>()));
		Test.Assert(picker.View.RowText(1) == "Crate");
		let row = picker.ShownRow(1);
		Test.Assert(row != null);
		Test.Assert(row.ShownName == "Crate");
		Test.Assert(row.ShownDetail == "PickMeshAsset");
		Test.Assert(row.ShownGlyph == "Editor/Icons/Types/PickMeshAsset.svg");
	}

	[Test]
	public static void TheFavouritesStarredAndFirstTheCurrentCheckedAndLit()
	{
		let bed = scope ProjectBed();
		bed.Favourites.Add(bed.Lid);
		bed.Favourites.Add(bed.Bell); // not a type it takes: not listed
		String[1] meshes = .("PickMeshAsset");
		let request = bed.Request(meshes, bed.Lamp);
		defer delete request;
		for (let item in request.Items)
			Test.Assert(item.Favourite == (item.Name == "Lid"));
		Test.Assert(request.Current == Key(bed.Lamp, .. scope .()));
		let plain = bed.Request(meshes);
		defer delete plain;
		Test.Assert(plain.Current.IsEmpty, "nil: nothing checked");

		let picker = scope PickerBed();
		picker.Open(bed.Request(meshes, bed.Lamp));
		// #Favourites Lid #Content Crate #Attic Lamp #Attic/Inner Lid #Zoo Bear
		Test.Assert(picker.Rows(.. scope .()) == "#Favourites Lid #Content Crate #Attic Lamp #Attic/Inner Lid #Zoo Bear");
		for (int32 i < (int32)picker.View.RowCount)
		{
			if (picker.View.IsHeader(i))
				continue;
			let row = picker.ShownRow(i);
			Test.Assert(row != null);
			Test.Assert(row.ShowsStar == (row.ShownName == "Lid"));
			Test.Assert(row.ShowsCheck == (row.ShownName == "Lamp"));
		}
		Test.Assert(picker.View.LitKey == Key(bed.Lamp, .. scope .()), "the current lit as it opens");
		Test.Assert(picker.View.Hint == "Enter picks, Esc keeps Lamp");
	}

	[Test]
	public static void NoneIsAllowedAndPicksNothing()
	{
		let bed = scope ProjectBed();
		String[1] meshes = .("PickMeshAsset");
		let picker = scope PickerBed();
		picker.Open(bed.Request(meshes, bed.Crate));
		Test.Assert(picker.View.NoneButton.Displayed);
		Test.Assert(picker.View.NoneButton.HandleActivate());
		Test.Assert(picker.Picked.Count == 1);
		Test.Assert(picker.Picked[0].IsEmpty, "None: an empty key, which clears the reference");
		Test.Assert(!picker.View.IsOpen);
	}

	[Test]
	public static void WithNoneOfTheTypesTheEmptyStateNamesThem()
	{
		let bed = scope ProjectBed();
		String[2] missing = .("PickTextureAsset", "PickFontAsset");
		let request = bed.Request(missing);
		defer delete request;
		Test.Assert(request.Items.IsEmpty);
		Test.Assert(request.EmptyTitle == "No PickTextureAsset or PickFontAsset yet");
		Test.Assert(request.EmptyText == "Import or create one in the Assets panel.");

		String[1] one = .("PickTextureAsset");
		let single = bed.Request(one);
		defer delete single;
		Test.Assert(single.EmptyTitle == "No PickTextureAsset yet");
		String[1] wild = .(AssetPickerSlot.cAnyAsset);
		let any = bed.Request(wild);
		defer delete any;
		Test.Assert(any.EmptyTitle == "No assets yet", "the wildcard reads as words");

		let picker = scope PickerBed();
		picker.Open(bed.Request(missing));
		Test.Assert(picker.View.ShowsState);
		Test.Assert(picker.View.StateTitle == "No PickTextureAsset or PickFontAsset yet");
		Test.Assert(picker.View.StateText == "Import or create one in the Assets panel.");
	}
}
