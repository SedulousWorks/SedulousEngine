using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Graphics;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Shell;
using Sedulous.Pipeline.Core;
using Sedulous.Engine.DefaultApp;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;
using Sedulous.Run;
using Dialogue;

namespace Sedulous.Integration.Plugins;

/// The dialogue plugin's Editor part in an editor session. Opening a project that enables the plugin
/// adds the dialogue file's, the cast's and the dialogue assets' pages; a cast opens in its page,
/// its speakers a list by id beside the chosen one's rows, where a speaker is added, undone, found
/// and removed, a dialogue assets list opens in its, and a dialogue file opens in the text page with
/// its problems as the cook finds them and its conversations in the outline; closing the project
/// removes the pages again.
static class DialogueEditorTests
{
	class HostOnly : IApplicationHost
	{
		public SubsystemManager Subsystems { get; } = new .() ~ delete _;

		public IShell Shell => null;
		public GraphicsDevice Graphics => null;
		public RenderWindow MainRenderWindow => null;

		public RenderWindow OpenWindow(WindowSettings windowSettings, RenderWindowDesc renderDesc) => null;
		public void CloseWindow(RenderWindow window) {}
		public void RequestExit(int code = 0) {}
	}

	static String List(DialogueListPage page, String outText)
	{
		page.List(outText..Clear());
		return outText;
	}

	static String State(DialogueTextPage page, String outText)
	{
		page.PreviewState(outText..Clear());
		return outText;
	}

	[Test]
	public static void InTheEditorADialogueFileTheCastAndTheDialogueAssetsOpenInTheirPagesWhichLeaveWithThePlugin()
	{
		EditorAppSerializables.RegisterEditorProjectSettingsTypes();
		let dir = scope String();
		PathJoin(System.IO.Directory.GetCurrentDirectory(.. scope .()), "scratch_plugins_dialogue_editor", dir);
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "Dialogue Pages") case .Ok);
		{
			let project = EditorProject.Open(dir);
			Test.Assert(project != null);
			defer delete project;
			let entry = new EnabledPlugin();
			entry.Id.Set("dialogue");
			project.Settings.Plugins.Add(entry);
			Test.Assert(project.SaveSettings() case .Ok);
		}

		let host = scope HostOnly();
		let embedded = scope DefaultApplication();
		// The host's order: configured, the context started, then the application.
		embedded.Configure(host);
		host.Subsystems.Startup();
		embedded.OnStartup(host);
		let context = scope EditorContext();
		let builders = scope BuilderRegistry();
		let cook = scope EditorCookService();
		defer cook.Shutdown();
		let thumbnails = scope ThumbnailService();
		let pageServices = scope AssetPageServicesSource(); // pages with no window: enough to make and close them
		{
			let services = new EditorSessionServices();
			services.Context = context;
			services.Cook = cook;
			services.Builders = builders;
			services.Thumbnails = thumbnails;
			services.PageServices = pageServices;
			let session = scope EditorSession(services);
			session.SetEmbedded(host, embedded);
			Test.Assert(session.Open(dir));
			Test.Assert((context.Plugins != null) && context.Plugins.IsLoaded("dialogue"));
			Test.Assert(context.Pages.FindFactory(typeof(DialogueCastAsset)) != null);
			Test.Assert(context.Pages.FindFactory(typeof(DialogueAssetListAsset)) != null);

			let root = context.Project.SourceDb.RootGroup;
			let cast = root.CreateInstance("Cast", typeof(DialogueCastAsset).GetFullName(.. scope .()));
			let list = root.CreateInstance("Staging", typeof(DialogueAssetListAsset).GetFullName(.. scope .()));
			Test.Assert((cast != null) && (list != null));
			{
				let castAsset = scope DialogueCastAsset();
				let keeper = new DialogueSpeaker();
				keeper.Id.Set("keeper");
				castAsset.Speakers.Add(keeper);
				Test.Assert(cast.WriteObject(castAsset) case .Ok);
				let listAsset = scope DialogueAssetListAsset();
				Test.Assert(list.WriteObject(listAsset) case .Ok);
			}

			let text = scope String();
			let castPage = context.OpenPage(cast);
			Test.Assert(castPage != null);
			Test.Assert(castPage.Title == "Cast");
			let speakers = castPage as DialogueCastPage; // the dialogue's factory made it
			Test.Assert(speakers != null);
			Test.Assert(List(speakers, text) == "keeper");
			Test.Assert(speakers.Chosen == 0);
			speakers.Add();
			Test.Assert(List(speakers, text) == "keeper\nspeaker");
			Test.Assert(speakers.Chosen == 1);
			Test.Assert(castPage.IsDirty);
			let added = ((DialogueCastAsset)speakers.AssetObject).Speakers[1];
			Test.Assert((added.Moods.Count == 1) && (added.Moods[0].Name == "neutral"), "a default mood");
			castPage.Commands.Undo();
			Test.Assert(List(speakers, text) == "keeper");
			Test.Assert(speakers.Chosen == 0, "the chosen item, gone with the undo, falls back");
			speakers.Add();
			speakers.Add();
			Test.Assert(List(speakers, text) == "keeper\nspeaker\nspeaker_2");
			speakers.Search(" _2 ");
			Test.Assert(List(speakers, text) == "speaker_2");
			speakers.Search("");
			speakers.Choose(1);
			Test.Assert(speakers.RemoveChosen());
			Test.Assert(List(speakers, text) == "keeper\nspeaker_2");
			speakers.Choose(-1);
			Test.Assert(!speakers.RemoveChosen(), "none chosen");

			// The chosen speaker's rows edit it, one undo step, and the list shows its new name.
			speakers.Choose(1);
			let rows = speakers.ItemRows as FieldPropertySource;
			Test.Assert(rows != null);
			rows.BeginEdit("ShownName");
			rows.CommitEdit("ShownName", Sedulous.GUI.PropertyWrite(Sedulous.GUI.Variant("Aide")));
			Test.Assert(((DialogueCastAsset)speakers.AssetObject).Speakers[1].ShownName == "Aide");
			Test.Assert(List(speakers, text) == "keeper\nspeaker_2   Aide");
			castPage.Commands.Undo();
			Test.Assert(((DialogueCastAsset)speakers.AssetObject).Speakers[1].ShownName.IsEmpty, "one undo step");
			Test.Assert(List(speakers, text) == "keeper\nspeaker_2");

			let listPage = context.OpenPage(list);
			Test.Assert(listPage != null);
			Test.Assert(listPage.Title == "Staging");
			let entries = listPage as DialogueAssetsPage;
			Test.Assert((entries != null) && (entries.Chosen == -1), "an empty list chooses none");
			entries.Add();
			entries.Add();
			Test.Assert(List(entries, text) == "asset\nasset_2");
			Test.Assert(context.OpenPages.Count == 2);

			// A dialogue file opens in the text page: its problems as the cook finds them, at their
			// lines, and its conversations in the outline. (With no window the page has no code editor
			// to type in; typing and its checks are the code pages' own.)
			Test.Assert(context.Pages.FindFactory(typeof(DialogueAsset)) != null);
			let source = "conversation gate\n" +
				"@ keeper: Who goes there?\n" +
				"conversation lane\n" +
				"@ stranger: Me.\n";
			let path = context.Project.SourceFile("Dialogue/Gate.dialogue", .. scope .());
			CreateDirectory(PathParent(path, .. scope .()));
			Test.Assert(WriteFile(path, Span<uint8>((uint8*)source.Ptr, source.Length)) case .Ok);
			let file = root.CreateInstance("Gate", typeof(DialogueAsset).GetFullName(.. scope .()));
			Test.Assert(file != null);
			{
				let fileAsset = scope DialogueAsset();
				fileAsset.FileName.Set("Dialogue/Gate.dialogue");
				fileAsset.Cast = cast.Id;
				Test.Assert(file.WriteObject(fileAsset) case .Ok);
			}
			let filePage = context.OpenPage(file);
			Test.Assert(filePage != null);
			let textPage = filePage as DialogueTextPage;
			Test.Assert(textPage != null);
			Test.Assert(textPage.SourceRead);
			textPage.Outline(text..Clear());
			Test.Assert(text == "gate\nlane\n", text);
			Test.Assert(textPage.ConversationLine(0) == 1);
			Test.Assert(textPage.ConversationLine(1) == 3);
			Test.Assert(textPage.Found.Length == 1);
			Test.Assert(textPage.Found[0].Line == 3); // the fourth line, from 0
			Test.Assert(textPage.Found[0].Severity == .Error);
			Test.Assert(textPage.Found[0].Message.Contains("no speaker `stranger`"), textPage.Found[0].Message);
			Test.Assert(context.OpenPages.Count == 3);

			// Preview plays the text as it reads, here in a plain run and scene (the editor plays it
			// in the open scene page's Simulate); text with errors does not play.
			let run = scope RunBase("preview");
			let scene = scope Sedulous.Scene.Scene("preview");
			scene.SetRun(run);
			Test.Assert(!textPage.PlayPreview(scene, run), "`stranger` is no speaker");
			Test.Assert(!textPage.IsPreviewing);
			let clean = "conversation talk\n" +
				"set seen\n" +
				"if seen\n" +
				"  @ keeper: Seen.\n" +
				"end\n" +
				"choice\n" +
				"> Yes.\n" +
				"> No.\n" +
				"end\n";
			let cleanPath = context.Project.SourceFile("Dialogue/Talk.dialogue", .. scope .());
			Test.Assert(WriteFile(cleanPath, Span<uint8>((uint8*)clean.Ptr, clean.Length)) case .Ok);
			let talk = root.CreateInstance("Talk", typeof(DialogueAsset).GetFullName(.. scope .()));
			Test.Assert(talk != null);
			{
				let talkAsset = scope DialogueAsset();
				talkAsset.FileName.Set("Dialogue/Talk.dialogue");
				talkAsset.Cast = cast.Id;
				Test.Assert(talk.WriteObject(talkAsset) case .Ok);
			}
			let talkPage = context.OpenPage(talk) as DialogueTextPage;
			Test.Assert(talkPage != null);
			Test.Assert(State(talkPage, text) == "Not playing");
			Test.Assert(talkPage.PlayPreview(scene, run));
			let runner = talkPage.PreviewRunner;
			Test.Assert(runner != null);
			Test.Assert(runner.Waiting == .Line);
			Test.Assert(runner.Flag("seen"), "a flag of the preview's own: the run has no save");
			Test.Assert(State(talkPage, text) == "A line shows: Advance goes on");
			Test.Assert(runner.Advance());
			Test.Assert(runner.Waiting == .Choice);
			Test.Assert(State(talkPage, text) == "A choice: take an answer");
			Test.Assert(runner.Choose(1));
			Test.Assert(State(talkPage, text) == "Ended");
			talkPage.StopPreview();
			Test.Assert(!talkPage.IsPreviewing);
			Test.Assert(State(talkPage, text) == "Not playing");
			// Played again: the text is built again for it (the last play took what the check built).
			Test.Assert(talkPage.PlayPreview(scene, run));
			Test.Assert(talkPage.PreviewRunner.Waiting == .Line);
			talkPage.StopPreview();
			// With no scene page open, Start tells and plays nothing.
			Test.Assert(!talkPage.StartPreview());
			Test.Assert(!talkPage.IsPreviewing);

			session.Close();
			Test.Assert(context.Plugins == null);
			Test.Assert(context.OpenPages.Count == 0, "the plugin's pages closed with it");
			Test.Assert(context.Pages.FindFactory(typeof(DialogueCastAsset)) == null);
			Test.Assert(context.Pages.FindFactory(typeof(DialogueAssetListAsset)) == null);
			Test.Assert(context.Pages.FindFactory(typeof(DialogueAsset)) == null);
		}
		host.Subsystems.Shutdown();
		embedded.OnShutdown(host);
		host.Subsystems.Dispose();
	}
}
