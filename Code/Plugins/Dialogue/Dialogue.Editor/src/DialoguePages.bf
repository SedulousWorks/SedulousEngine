using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Scene;
using Sedulous.Runtime.Client;
using Sedulous.Run;
using Sedulous.Scene;

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

/// A dialogue file's text in the code editor (Data/Editor/Dialogue/DialoguePage.xml), coloured as
/// dialogue (Data/Editor/Code/dialogue.xml) and checked as the cook checks it a moment after each
/// edit (DialogueCook.CheckDialogueText, its project gathered with the other files read from the
/// sources), the problems in the list and on their lines; an outline of its conversations, which
/// moves the cursor to the one chosen; and the file's own slots, its cast and its dialogue assets,
/// in the grid. Preview plays the chosen conversation, as the text now reads, in the open scene
/// page's Simulate (started when it is not running): a runner of the page's own over the scene
/// page's run, in the stock box, with flags of its own that go when the preview stops. Its pane says
/// what the conversation waits on and takes the advance, the answers and a command's done, since
/// Simulate's pointer is the scene's.
class DialogueTextPage : CodeAssetPage
{
	public const String cMarkupPath = "Editor/Dialogue/DialoguePage.xml";

	private class Entry
	{
		public String Id = new .() ~ delete _;
		/// From 1.
		public uint32 Line;
	}

	/// The plugin's, which outlive the page.
	private DialogueSettings mSettings;
	/// The conversations as the last check found them.
	private List<Entry> mConversations = new .() ~ DeleteContainerAndItems!(_);
	private TreeModel mModel = new .() ~ delete _;
	/// The markup's.
	private TreeView mOutline = null;
	/// Set while the check fills the outline, so it is not taken as the user's choice.
	private bool mShowing = false;
	/// The last check's compiled conversations and texts, for Preview; whether it found no error.
	private List<DialogueConversation> mBuilt = new .() ~ DeleteContainerAndItems!(_);
	private List<DialogueLineText> mBuiltLines = new .() ~ DeleteContainerAndItems!(_);
	private bool mBuilds = false;
	/// The conversation Preview plays.
	private int mChosen = 0;
	private DialogueRunService mPreview = null;
	/// The scene page the preview plays in, BORROWED while it is open.
	private EditorPage mPreviewPage = null;
	private bool mStartedSimulation = false;
	/// The markup's.
	private ButtonBase mPreviewButton = null;
	private Label mPreviewState = null;
	private UIWidget mPreviewAnswers = null;
	/// What the pane shows, so it is shown again when it changes.
	private int mShownAnswers = 0;
	private DialogueWait mShownWait = .Nothing;

	public this(EditorContext context, AssetPageServices services, Instance instance, DialogueSettings settings)
		: base(context, services, instance, typeof(DialogueAsset), cMarkupPath)
	{
		mSettings = settings;
		mOutline = Find<TreeView>("dialogue-outline");
		if (mOutline != null)
		{
			mOutline.Model = mModel;
			mOutline.SetOnSelectionChanged(new [=this] (index) =>
				{
					if (!mShowing && index.IsValid)
						GoToConversation((int)index.InternalId);
				});
		}
		mPreviewButton = Find<ButtonBase>("dialogue-preview");
		mPreviewState = Find<Label>("dialogue-preview-state");
		mPreviewAnswers = Find<UIWidget>("dialogue-preview-answers");
		if (mPreviewButton != null)
		{
			mPreviewButton.SetOnClick(new [=this] () =>
				{
					if (IsPreviewing)
						StopPreview();
					else
						StartPreview();
				});
		}
		if (let advance = Find<ButtonBase>("dialogue-preview-advance"))
			advance.SetOnClick(new [=this] () => { mPreview?.Advance(); });
		if (let done = Find<ButtonBase>("dialogue-preview-done"))
			done.SetOnClick(new [=this] () => { mPreview?.Done(); });
		OpenCode("dialogue");
		ShowPreview();
	}

	public ~this()
	{
		StopPreview();
		if (mOutline != null)
			mOutline.Model = null;
	}

	/// Moves the cursor to conversation `index` of the last check, and chooses it for Preview.
	public void GoToConversation(int index)
	{
		if ((index >= 0) && (index < mConversations.Count))
		{
			mChosen = index;
			ShowLine(mConversations[index].Line, 1);
		}
	}

	public bool IsPreviewing => mPreview != null;

	/// Plays the chosen conversation in `scenePage`'s Simulate (null: the first open scene page),
	/// started for it when it is not running. False, told, when there is no scene page or the text
	/// does not build.
	public bool StartPreview(ISceneEditorPage scenePage = null)
	{
		StopPreview();
		var page = (scenePage != null) ? FindOpen(scenePage) : null;
		if (scenePage == null)
		{
			for (let open in Context.OpenPages)
			{
				if (open is ISceneEditorPage)
				{
					page = open;
					break;
				}
			}
		}
		let found = page as ISceneEditorPage;
		if (found == null)
		{
			Context.Notify(.Warning, "Preview: open a scene to play the conversation in");
			ShowPreview();
			return false;
		}
		mStartedSimulation = !found.IsSimulating;
		if (mStartedSimulation)
			found.StartSimulation();
		let scene = found.EditContext.Scene;
		let run = scene.Run as RunBase;
		if ((run == null) || !found.IsSimulating)
		{
			Context.Notify(.Warning, "Preview: the scene did not start");
			if (mStartedSimulation)
				found.StopSimulation();
			mStartedSimulation = false;
			ShowPreview();
			return false;
		}
		mPreviewPage = page;
		if (!PlayPreview(scene, run))
		{
			StopPreview();
			return false;
		}
		return true;
	}

	/// Plays the chosen conversation in `scene` of `run` (what StartPreview does once the scene
	/// page simulates); false, told, when the text does not build.
	public bool PlayPreview(Scene scene, RunBase run)
	{
		DeleteAndNullify!(mPreview);
		CheckNow(); // the text as it reads now
		if (!mBuilds || mBuilt.IsEmpty)
		{
			Context.Notify(.Warning, "Preview: the dialogue has errors, or no conversation");
			ShowPreview();
			return false;
		}
		// The text as it reads now, as the file the runner plays.
		let file = new DialogueResource();
		Swap!(file.Conversations, mBuilt);
		Swap!(file.Lines, mBuiltLines);
		if (let asset = ObjectAs<DialogueAsset>())
			file.Cast = asset.Cast;
		let conversation = scope String();
		if (mChosen < file.Conversations.Count)
			conversation.Set(file.Conversations[mChosen].Id);
		mPreview = new DialogueRunService(mSettings, run);
		mPreview.Host.ShowStockBox(true);
		mPreview.Host.SetDialogue(InstanceId, file);
		mPreview.Host.SetScene(scene);
		if (!mPreview.Play(InstanceId, conversation))
		{
			DeleteAndNullify!(mPreview);
			ShowPreview();
			return false;
		}
		ShowPreview();
		return true;
	}

	/// Ends the preview, and the Simulate it started.
	public void StopPreview()
	{
		let was = mPreview != null;
		DeleteAndNullify!(mPreview); // the box and the fade go with its host
		if (mStartedSimulation && (mPreviewPage != null) && (FindOpen(mPreviewPage as ISceneEditorPage) != null))
			(mPreviewPage as ISceneEditorPage).StopSimulation();
		mPreviewPage = null;
		mStartedSimulation = false;
		if (was)
			ShowPreview();
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		base.OnUpdate(host, dt);
		if (mPreview == null)
			return;
		if (mPreviewPage != null)
		{
			let scenePage = FindOpen(mPreviewPage as ISceneEditorPage) as ISceneEditorPage;
			if ((scenePage == null) || !scenePage.IsSimulating)
			{
				mStartedSimulation = false; // it closed or stopped on its own: nothing of it to stop
				StopPreview();
				return;
			}
			if (!scenePage.IsPaused)
				mPreview.Update(dt);
		}
		else
			mPreview.Update(dt);
		if ((mPreview != null) && ((mPreview.Waiting != mShownWait) || (mPreview.Box.AnswerCount != mShownAnswers)))
			ShowPreview();
	}

	public override void OnClose()
	{
		StopPreview();
		base.OnClose();
	}

	// === For tests ===

	/// The preview's runner; null when no preview plays.
	public DialogueRunService PreviewRunner => mPreview;

	/// What the preview's pane says, appended.
	public void PreviewState(String outText)
	{
		if (mPreview == null)
		{
			outText.Append("Not playing");
			return;
		}
		switch (mPreview.Waiting)
		{
		case .Line: outText.Append("A line shows: Advance goes on");
		case .Choice: outText.Append("A choice: take an answer");
		case .Time: outText.Append("Waiting");
		case .Staging: outText.Append("Staging: waiting for it to end");
		case .Command: outText.Append("A command waits: Done goes on");
		case .Nothing: outText.Append(mPreview.IsPlaying ? "Playing" : "Ended");
		}
	}

	// The open page that is `scenePage`, or null when it has closed.
	private EditorPage FindOpen(ISceneEditorPage scenePage)
	{
		if (scenePage == null)
			return null;
		for (let open in Context.OpenPages)
		{
			if (Internal.UnsafeCastToPtr(open) == Internal.UnsafeCastToPtr(scenePage))
				return open;
		}
		return null;
	}

	// The preview's pane, after each step: what it waits on and the answers to take.
	private void ShowPreview()
	{
		if (mPreviewButton != null)
			mPreviewButton.Checked = IsPreviewing;
		if (mPreviewState != null)
			mPreviewState.Text = PreviewState(.. scope .());
		mShownWait = (mPreview != null) ? mPreview.Waiting : .Nothing;
		mShownAnswers = (mPreview != null) ? mPreview.Box.AnswerCount : 0;
		if (mPreviewAnswers == null)
			return;
		mPreviewAnswers.RemoveAllChildren();
		for (int i < mShownAnswers)
		{
			let button = mPreviewAnswers.AddElement("Button") as Button;
			if (button == null)
				continue;
			button.Text = mPreview.Box.AnswerText(i);
			let index = (int32)i;
			button.SetOnClick(new [=] () => { mPreview?.Choose(index); });
		}
	}

	// === For tests ===

	/// The outline's rows, one a line, appended.
	public void Outline(String outText)
	{
		for (let entry in mConversations)
			outText.AppendF("{}\n", entry.Id);
	}

	/// The line conversation `index`'s header is on (from 1); 0 when there is none.
	public uint32 ConversationLine(int index) => ((index >= 0) && (index < mConversations.Count)) ? mConversations[index].Line : 0;

	protected override void CheckCode(StringView text, List<CodeProblem> outProblems)
	{
		ClearAndDeleteItems!(mConversations);
		mBuilds = false;
		let project = Context.Project;
		if (project == null)
			return;
		DialogueSourceReader read = scope (fileName, outText) =>
			{
				let bytes = scope List<uint8>();
				if (ReadFile(project.SourceFile(fileName, .. scope .()), bytes) case .Err)
					return false;
				if (!bytes.IsEmpty)
					outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
				return true;
			};
		let parse = scope DialogueParse();
		DialogueCook.CheckDialogueText(text, mSettings, InstanceId, project.SourceDb, read, parse);
		mBuilds = parse.Ok;
		for (let problem in parse.Problems)
			outProblems.Add(new CodeProblem(problem.Warning ? .Warning : .Error, problem.Message, "", (problem.Line > 0) ? problem.Line - 1 : 0, 0, false));
		for (let conversation in parse.Conversations)
		{
			let entry = new Entry();
			entry.Id.Set(conversation.Id);
			// Its header's line, which its End (the last step) carries.
			entry.Line = conversation.Steps.IsEmpty ? 0 : conversation.Steps.Back.SourceLine;
			mConversations.Add(entry);
		}
		ClearAndDeleteItems!(mBuilt);
		ClearAndDeleteItems!(mBuiltLines);
		Swap!(mBuilt, parse.Conversations);
		Swap!(mBuiltLines, parse.Lines);
	}

	protected override void OnCodeChecked()
	{
		mShowing = true;
		mModel.Clear();
		for (let entry in mConversations)
			mModel.AddNode(TreeModel.Root, entry.Id);
		mShowing = false;
	}

	protected override void CleanSummary(String outText)
	{
		if (mConversations.Count == 1)
			outText.Append("No problems: 1 conversation");
		else
			outText.AppendF("No problems: {} conversations", mConversations.Count);
	}
}

/// Opens a DialogueAsset in the text page, checking against the plugin's settings; a page asks for
/// its services when it is made.
class DialogueTextPageFactory : IEditorPageFactory
{
	/// Borrowed, both: the editor's (or a test's) services and the plugin's settings, which outlive it.
	private AssetPageServicesSource mServices;
	private DialogueSettings mSettings;

	public this(AssetPageServicesSource services, DialogueSettings settings)
	{
		mServices = services;
		mSettings = settings;
	}

	public Type PrimaryType => typeof(DialogueAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new DialogueTextPage(context, mServices.Make(), instance, mSettings);
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
	/// Adds the dialogue's pages to the editor's page registry, the text page checking against
	/// `settings`; their keys, to remove them by, are appended to `outKeys`. `services` and
	/// `settings` (the plugin's) are borrowed and outlive the pages.
	public static void Register(EditorContext context, AssetPageServicesSource services, DialogueSettings settings, List<uint64> outKeys)
	{
		outKeys.Add(context.Pages.Register(new DialogueTextPageFactory(services, settings)));
		outKeys.Add(context.Pages.Register(new DialogueCastPageFactory(services)));
		outKeys.Add(context.Pages.Register(new DialogueAssetsPageFactory(services)));
	}
}
