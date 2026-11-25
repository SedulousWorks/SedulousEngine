using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Dialogue;

/// A page over an asset that is a list of items, each edited apart. The items are a list beside the
/// grid, by name; the list's bar adds an item and removes the chosen one, and its search keeps the
/// items whose name holds the text. The grid shows the chosen item's fields from reflection, its
/// asset slots offering only assets of their kind. Every edit is one undo step; Save writes the asset
/// and requests a cook. The asset's own rows are not shown: the items are the asset.
///   * DialogueCastPage (Data/Editor/Dialogue/CastPage.xml): a cast's speakers, by id.
///   * DialogueAssetsPage (Data/Editor/Dialogue/AssetsPage.xml): a dialogue assets list's entries,
///     by name.
abstract class DialogueListPage : AssetObjectPage
{
	/// The grid's section the chosen item's rows are in.
	public const String cItemSection = "item";

	/// The chosen item's rows; the base's sections let go of them first (ClearSections).
	private FieldPropertySource mValues = null;
	private TreeModel mModel = new .() ~ delete _;
	/// The item each list row stands for, by node id.
	private List<int32> mRows = new .() ~ delete _;
	private int32 mChosen = -1;
	/// Set while code makes a choice, so it is not taken as the user's.
	private bool mShowing = false;
	private String mSearch = new .() ~ delete _;
	private String mItemTitle = new .() ~ delete _;
	/// The markup's: the tree holds it.
	private TreeView mList = null;

	/// The page over `instance`, an asset of `assetType`, from the markup at `markupPath`; the chosen
	/// item's section is titled `title`. It takes `services`.
	protected this(EditorContext context, AssetPageServices services, Instance instance, Type assetType, StringView markupPath, StringView title)
		: base(context, services, instance, assetType, markupPath)
	{
		mItemTitle.Set(title);
	}

	public ~this()
	{
		if (mList != null)
			mList.Model = null;
		if (Grid != null)
			Grid.Source = null;
		// The grid's sections let go of the rows before they go (the base's outlive these).
		ClearSections();
		delete mValues;
	}

	/// The item the grid shows (-1: none).
	public int32 Chosen => mChosen;
	/// The chosen item's rows.
	public IPropertySource ItemRows => mValues;

	/// Chooses item `item` (-1: none): the grid shows it and the list selects it.
	public void Choose(int32 item)
	{
		mChosen = item;
		Bind();
		ShowList();
	}

	/// Adds an item after the others and chooses it.
	public void Add()
	{
		if (AssetObject == null)
			return;
		EditWhole("edit_dialogue", scope [&] (object) => { AddItem(object); });
		Choose((int32)ItemCount - 1);
	}

	/// Removes the chosen item; false when none is chosen.
	public bool RemoveChosen()
	{
		if ((AssetObject == null) || (mChosen < 0) || (mChosen >= ItemCount))
			return false;
		let item = (int)mChosen;
		EditWhole("edit_dialogue", scope [&] (object) => { RemoveItem(object, item); });
		return true;
	}

	/// Keeps the items whose name holds `text` (empty: every one).
	public void Search(StringView text)
	{
		var trimmed = text;
		trimmed.Trim();
		mSearch.Set(trimmed);
		ShowList();
	}

	/// The list's rows, one a line, appended.
	public void List(String outText)
	{
		let label = scope String();
		for (let item in mRows)
		{
			if (!outText.IsEmpty)
				outText.Append('\n');
			label.Clear();
			ItemLabel(item, label);
			outText.Append(label);
		}
	}

	/// Builds the list and binds the first item; a derived page's constructor calls it once its own
	/// state is set, since it asks the derived page.
	protected void Start()
	{
		HideAssetRows(); // the asset is its items: the grid shows the chosen one
		mList = Find<TreeView>("dialogue-list");
		if (let add = Find<ButtonBase>("dialogue-add"))
			add.SetOnClick(new [=this] () => { Add(); });
		if (let remove = Find<ButtonBase>("dialogue-remove"))
			remove.SetOnClick(new [=this] () => { RemoveChosen(); });
		if (let search = Find<TextField>("dialogue-search"))
			search.SetOnTextChanging(new [=this] (text) => { Search(text); });
		if (mList != null)
		{
			mList.Model = mModel;
			mList.SetOnSelectionChanged(new [=this] (index) =>
				{
					if (mShowing || !index.IsValid)
						return;
					let node = (int)index.InternalId;
					if ((node >= 0) && (node < mRows.Count))
						Choose(mRows[node]);
				});
		}

		// The chosen item's rows come from reflection, and each edit is one undo step. The item is
		// found again each time: the list moves as items come and go.
		mValues = new FieldPropertySource(ItemType, 1,
			new [=this] (object) =>
			{
				let item = ItemAt(mChosen);
				return (item != null) ? Internal.UnsafeCastToPtr(item) : null;
			},
			new [=this] (apply) =>
			{
				let chosen = mChosen;
				EditWhole("edit_dialogue", scope [&] (object) =>
					{
						if (let item = ItemAt(chosen))
							apply(0, Internal.UnsafeCastToPtr(item));
					});
			}, Context.Resources);
		AddSection(cItemSection, mItemTitle, mValues);
		Choose((ItemCount > 0) ? 0 : -1);
	}

	/// The type of the asset's items.
	protected abstract Type ItemType { get; }
	protected abstract int ItemCount { get; }
	/// Item `item`; null when there is none.
	protected abstract Object ItemAt(int item);
	/// The item's name in the list, appended.
	protected abstract void ItemLabel(int item, String outLabel);
	/// Adds a new item to the asset (inside an undo step).
	protected abstract void AddItem(ISerializable asset);
	/// Removes item `item` from the asset (inside an undo step).
	protected abstract void RemoveItem(ISerializable asset, int item);

	protected override void OnObjectChanged()
	{
		// A whole edit, or its undo: the chosen item may be gone, or may have moved.
		if (mChosen >= ItemCount)
			mChosen = (int32)ItemCount - 1;
		Bind();
		ShowList();
	}

	/// The first of `base`, `base_2`, `base_3`... that `taken` does not answer true for, appended.
	protected static void FreeName(StringView stem, delegate bool(StringView name) taken, String outName)
	{
		if (!taken(stem))
		{
			outName.Append(stem);
			return;
		}
		let name = scope String();
		for (int n = 2; ; n++)
		{
			name.Clear();
			name.AppendF("{}_{}", stem, n);
			if (!taken(name))
			{
				outName.Append(name);
				return;
			}
		}
	}

	// The item's rows read again (the field source finds the item through its resolver each time).
	private void Bind()
	{
		if (mValues != null)
			mValues.Refresh();
	}

	private void ShowList()
	{
		mShowing = true;
		mModel.Clear();
		mRows.Clear();
		int32 chosen = -1;
		let label = scope String();
		for (int32 i < (int32)ItemCount)
		{
			label.Clear();
			ItemLabel(i, label);
			if (!mSearch.IsEmpty && !label.Contains(mSearch, true))
				continue;
			let node = mModel.AddNode(TreeModel.Root, label);
			mRows.Add(i);
			if (i == mChosen)
				chosen = node;
		}
		if ((mList != null) && (chosen >= 0))
		{
			ItemId[1] id = .((ItemId)chosen);
			mList.SetSelectedIds(id);
		}
		mShowing = false;
	}
}

/// A cast's speakers, by id (and shown name). A new speaker is `speaker` (`speaker_2`, ...) with a
/// `neutral` mood.
class DialogueCastPage : DialogueListPage
{
	public const String cMarkupPath = "Editor/Dialogue/CastPage.xml";

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(DialogueCastAsset), cMarkupPath, "Speaker")
	{
		Start();
	}

	protected override Type ItemType => typeof(DialogueSpeaker);

	protected override int ItemCount
	{
		get
		{
			let cast = ObjectAs<DialogueCastAsset>();
			return (cast != null) ? cast.Speakers.Count : 0;
		}
	}

	protected override Object ItemAt(int item)
	{
		let cast = ObjectAs<DialogueCastAsset>();
		return ((cast != null) && (item >= 0) && (item < cast.Speakers.Count)) ? cast.Speakers[item] : null;
	}

	protected override void ItemLabel(int item, String outLabel)
	{
		let speaker = ObjectAs<DialogueCastAsset>().Speakers[item];
		outLabel.Append(speaker.Id);
		if (!speaker.ShownName.IsEmpty && (speaker.ShownName != speaker.Id))
			outLabel.AppendF("   {}", speaker.ShownName);
	}

	protected override void AddItem(ISerializable asset)
	{
		let speakers = ((DialogueCastAsset)asset).Speakers;
		let speaker = new DialogueSpeaker();
		FreeName("speaker", scope (id) =>
			{
				for (let other in speakers)
				{
					if (other.Id == id)
						return true;
				}
				return false;
			}, speaker.Id);
		speaker.Moods.Add(new DialogueMood("neutral", .())); // every speaker has a default mood
		speakers.Add(speaker);
	}

	protected override void RemoveItem(ISerializable asset, int item)
	{
		let speakers = ((DialogueCastAsset)asset).Speakers;
		if ((item >= 0) && (item < speakers.Count))
		{
			delete speakers[item];
			speakers.RemoveAt(item);
		}
	}
}

/// A dialogue assets list's entries, by name, each an asset slot that takes any asset. It has no Cook
/// button: the list has no cooked form.
class DialogueAssetsPage : DialogueListPage
{
	public const String cMarkupPath = "Editor/Dialogue/AssetsPage.xml";

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(DialogueAssetListAsset), cMarkupPath, "Dialogue Asset")
	{
		Start();
	}

	protected override Type ItemType => typeof(DialogueAssetEntry);

	protected override int ItemCount
	{
		get
		{
			let list = ObjectAs<DialogueAssetListAsset>();
			return (list != null) ? list.Entries.Count : 0;
		}
	}

	protected override Object ItemAt(int item)
	{
		let list = ObjectAs<DialogueAssetListAsset>();
		return ((list != null) && (item >= 0) && (item < list.Entries.Count)) ? list.Entries[item] : null;
	}

	protected override void ItemLabel(int item, String outLabel)
	{
		outLabel.Append(ObjectAs<DialogueAssetListAsset>().Entries[item].Name);
	}

	protected override void AddItem(ISerializable asset)
	{
		let entries = ((DialogueAssetListAsset)asset).Entries;
		let entry = new DialogueAssetEntry();
		FreeName("asset", scope (name) =>
			{
				for (let other in entries)
				{
					if (other.Name == name)
						return true;
				}
				return false;
			}, entry.Name);
		entries.Add(entry);
	}

	protected override void RemoveItem(ISerializable asset, int item)
	{
		let entries = ((DialogueAssetListAsset)asset).Entries;
		if ((item >= 0) && (item < entries.Count))
		{
			delete entries[item];
			entries.RemoveAt(item);
		}
	}
}

/// Opens a DialogueCastAsset in the cast page; a page asks for its services when it is made.
class DialogueCastPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(DialogueCastAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new DialogueCastPage(context, mServices.Make(), instance);
}

/// Opens a DialogueAssetListAsset in the dialogue assets page; a page asks for its services when it
/// is made.
class DialogueAssetsPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(DialogueAssetListAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new DialogueAssetsPage(context, mServices.Make(), instance);
}

static class DialoguePages
{
	/// Adds the dialogue's pages to the editor's page registry; their keys, to remove them by, are
	/// appended to `outKeys`. `services` is borrowed and outlives the pages.
	public static void Register(EditorContext context, AssetPageServicesSource services, List<uint64> outKeys)
	{
		outKeys.Add(context.Pages.Register(new DialogueCastPageFactory(services)));
		outKeys.Add(context.Pages.Register(new DialogueAssetsPageFactory(services)));
	}
}
