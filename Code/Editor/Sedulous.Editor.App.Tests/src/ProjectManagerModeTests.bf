using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.GUI;
using Sedulous.Pipeline.Core;
using Sedulous.Engine.Project;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The project manager's part of the application, headless: a real EditorSession over the real
/// cook, job and thumbnail services (its registry never written to the user data: no
/// UserSettings), the pages and the GUI of a PagesBed, the screen the window would show kept
/// here. The manager shows over the window and its Open opens at the next drain, the frame back;
/// a folder with no project is said; a project another engine saved asks first (a newer one's
/// Cancel and Open Anyway, its stamp kept; an older one's Open Without Backup and Back Up and
/// Open, stamped with this engine, the backup beside the manifest); New Project makes the project
/// with the starter content and opens it, a folder that is a project already refused; Close
/// Project asks about the unsaved pages (Cancel stays), then closes the project and shows the
/// manager, and does nothing with no project.
class ProjectManagerModeTests
{
	private class ModeBed
	{
		public String Dir = new .() ~ delete _;
		public EditorContext Context = new .() ~ delete _;
		public BuilderRegistry Builders = new .() ~ delete _;
		public EditorCookService Cook = new .() ~ delete _;
		public EditorJobService Jobs = new .() ~ delete _;
		public ThumbnailService Thumbnails = new .() ~ delete _;
		/// The user's project registry, never written to the user data.
		public Settings Registry = new .() ~ delete _;
		public ProjectManagerController Projects ~ delete _;
		public EditorSession Session;
		public PagesBed Pages;
		public ProjectManagerMode Mode;
		/// The screen over the window, a reference of ours; null: the frame.
		public Node Shown = null;
		public int Seeds = 0;
		public int StoreSaves = 0;

		public this(StringView leaf)
		{
			EditorAppSerializables.RegisterEditorProjectSettingsTypes();
			PathJoin(System.IO.Directory.GetCurrentDirectory(.. scope .()), leaf, Dir);
			RemoveDirectoryRecursive(Dir);
			Test.Assert(CreateDirectory(Dir));
			Projects = new .(Registry);
			let bed = this;
			let session = new EditorSessionServices();
			session.Context = Context;
			session.Cook = Cook;
			session.Jobs = Jobs;
			session.Builders = Builders;
			session.Thumbnails = Thumbnails;
			session.Projects = Projects;
			session.SeedNewProject = new [=bed] (context, project) => { bed.Seeds++; };
			Session = new EditorSession(session);
			Pages = new PagesBed(PathJoin(Dir, "Pages", .. scope .()));

			let services = new ProjectManagerModeServices();
			services.Projects = Projects;
			services.Session = Session;
			services.Pages = Pages.Pages;
			services.Root = new [=bed] () => bed.Pages.Root;
			services.ShowScreen = new [=bed] (screen) => { bed.Show(screen); };
			services.LoadMarkup = new (path) => PagesBed.LoadMarkup(path);
			services.StoreChanged = new [=bed] () => { bed.StoreSaves++; };
			Mode = new ProjectManagerMode(services);
		}

		public ~this()
		{
			Show(null);
			delete Mode;
			delete Session; // the project closed while the cook it shuts down lives
			Cook.Shutdown();
			delete Pages;
			RemoveDirectoryRecursive(Dir);
		}

		/// As EditorWindow.ShowScreen: the screen over the window in place of the frame.
		public void Show(Node screen)
		{
			if (screen != null)
				screen.AddRef();
			if (Shown != null)
			{
				Shown.RemoveFromParent();
				Shown.ReleaseRef();
			}
			Shown = screen;
			if (Shown != null)
				Pages.Root.AddChild(Shown);
		}

		public bool ShowsManager => (Shown != null) && (Mode.View != null) && (Shown === Mode.View.Content);

		/// The GUI's next drain: what a click asked for happens.
		public void Drain() => Pages.Root.MutationQueue.Drain();

		/// A project named `name` made in the scratch folder `leaf`.
		public void MadeProject(StringView leaf, StringView name, String outDir)
		{
			PathJoin(Dir, leaf, outDir);
			Test.Assert(EditorProject.Create(outDir, name) case .Ok);
		}

		/// The question open over the GUI (asserted that one is).
		public MessageBox Question()
		{
			Pages.Root.UpdateLayout();
			let question = PagesBed.FindBox(Pages.Root);
			Test.Assert(question != null, "it asks");
			return question;
		}

		public static void StampOf(StringView directory, String outVersion)
		{
			let probed = scope ProjectSettings();
			Test.Assert(ProjectRegistry.ProbeProject(directory, probed) case .Ok);
			outVersion.Set(probed.EngineVersion);
		}
	}

	[Test]
	public static void TheManagerShowsOverTheWindowItsOpenOpensAtTheNextDrainTheFrameBackAFolderWithNoProjectIsSaid()
	{
		let bed = scope ModeBed("scratch_manager_mode_open");
		let dir = bed.MadeProject("Harbour", "Harbour", .. scope .());
		bed.Projects.NoteOpened(dir, "Harbour", EngineVersion.String);
		bed.Mode.Enter();
		Test.Assert(bed.ShowsManager);
		Test.Assert(bed.Mode.View.ShownCount == 1);
		let open = ProjectLauncherTests.ButtonText(bed.Mode.View.Content, "Open");
		Test.Assert(open != null);
		Test.Assert(open.HandleActivate());
		Test.Assert(bed.Session.Project == null, "not inside the click");
		bed.Drain();
		Test.Assert(bed.Session.Project != null);
		Test.Assert(bed.Session.Project.Directory == dir);
		Test.Assert(bed.Shown == null, "the frame back");

		bed.Session.Close();
		bed.Mode.Enter();
		Test.Assert(bed.ShowsManager);
		bed.Mode.OpenFrom(PathJoin(bed.Dir, "Nowhere", .. scope .()));
		Test.Assert(bed.Mode.View.Status == "Not a project (no Project.xml there).");
		Test.Assert(bed.Session.Project == null);
		Test.Assert(bed.ShowsManager);
		// Shown again, its status line starts empty.
		bed.Mode.Enter();
		Test.Assert(bed.Mode.View.Status.IsEmpty);
	}

	[Test]
	public static void AProjectAnotherEngineSavedAsksFirstEachOfItsAnswersDoingWhatItSays()
	{
		let bed = scope ModeBed("scratch_manager_mode_engines");
		let dir = bed.MadeProject("Old", "Old", .. scope .());
		let newer = scope $"{EngineVersion.Major + 1}.0.0";
		const String cOlder = "0.0.1";
		let manifest = PathJoin(dir, ProjectLayout.ManifestFile, .. scope .());
		let backup = scope $"{manifest}.{cOlder}.bak";
		bed.Mode.Enter();

		// A newer engine's: Cancel stays, Open Anyway opens with its stamp kept.
		ProjectLauncherTests.Stamp(dir, newer);
		bed.Mode.OpenFrom(dir);
		var question = bed.Question();
		Test.Assert(question.Title == "Project from a newer engine");
		Test.Assert(question.ButtonCount == 2);
		Test.Assert(PagesBed.ButtonNamed(question, "Open Without Backup") == null);
		Test.Assert(PagesBed.ButtonNamed(question, "Cancel").HandleActivate());
		bed.Drain();
		Test.Assert(bed.Session.Project == null);
		Test.Assert(bed.ShowsManager);
		bed.Mode.OpenFrom(dir);
		question = bed.Question();
		Test.Assert(PagesBed.ButtonNamed(question, "Open Anyway").HandleActivate());
		Test.Assert(bed.Session.Project == null, "not inside the click");
		bed.Drain();
		Test.Assert(bed.Session.Project != null);
		Test.Assert(bed.Shown == null);
		Test.Assert(ModeBed.StampOf(dir, .. scope .()) == newer, "a newer engine's stamp kept");
		bed.Session.Close();
		bed.Mode.Enter();

		// An older engine's: Open Without Backup opens and stamps it, no backup made.
		ProjectLauncherTests.Stamp(dir, cOlder);
		bed.Mode.OpenFrom(dir);
		question = bed.Question();
		Test.Assert(question.Title == "Open with this engine version?");
		Test.Assert(question.ButtonCount == 3);
		Test.Assert(PagesBed.ButtonNamed(question, "Open Anyway") == null);
		Test.Assert(PagesBed.ButtonNamed(question, "Open Without Backup").HandleActivate());
		bed.Drain();
		Test.Assert(bed.Session.Project != null);
		Test.Assert(ModeBed.StampOf(dir, .. scope .()) == EngineVersion.String, "stamped with this engine");
		Test.Assert(!FileExists(backup));
		bed.Session.Close();
		bed.Mode.Enter();

		// A backup that cannot be written (a folder where it would go): not opened, and said.
		ProjectLauncherTests.Stamp(dir, cOlder);
		Test.Assert(CreateDirectory(backup));
		bed.Mode.OpenFrom(dir);
		question = bed.Question();
		Test.Assert(PagesBed.ButtonNamed(question, "Back Up and Open").HandleActivate());
		bed.Drain();
		Test.Assert(bed.Session.Project == null, "a failed backup opens nothing");
		Test.Assert(bed.Mode.View.Status == "The backup FAILED: not opening.");
		Test.Assert(ModeBed.StampOf(dir, .. scope .()) == cOlder, "nor stamps it");
		Test.Assert(RemoveDirectoryRecursive(backup));

		// Back Up and Open: the manifest backed up beside it first, then the same.
		bed.Mode.OpenFrom(dir);
		question = bed.Question();
		Test.Assert(PagesBed.ButtonNamed(question, "Back Up and Open").HandleActivate());
		bed.Drain();
		Test.Assert(bed.Session.Project != null);
		Test.Assert(FileExists(backup));
		Test.Assert(ModeBed.StampOf(dir, .. scope .()) == EngineVersion.String);
	}

	[Test]
	public static void NewProjectMakesItWithTheStarterContentAndOpensItAFolderThatIsAProjectAlreadyIsRefused()
	{
		let bed = scope ModeBed("scratch_manager_mode_create");
		bed.Mode.Enter();
		let view = bed.Mode.View;
		view.ShowCreateDialog();
		bed.Pages.Root.UpdateLayout();
		let dialog = view.CreateDialog;
		Test.Assert(dialog != null);
		let d = bed.Pages.Root.EventDispatcher;
		(dialog.FindElement("new-project-name") as Sedulous.GUI.TextField).RequestFocus();
		d.InjectText("Harbour");
		(dialog.FindElement("new-project-parent") as Sedulous.GUI.TextField).RequestFocus();
		d.InjectText(bed.Dir);
		Test.Assert((dialog.FindElement("new-project-create") as Sedulous.GUI.Button).HandleActivate());
		Test.Assert(bed.Session.Project == null, "not inside the click");
		bed.Drain();
		let made = PathJoin(bed.Dir, "Harbour", .. scope .());
		Test.Assert(bed.Session.Project != null);
		Test.Assert(bed.Session.Project.Directory == made);
		Test.Assert(bed.Session.Project.Name == "Harbour");
		Test.Assert(bed.Seeds == 1, "the starter content, once");
		Test.Assert(bed.Shown == null, "the frame back");

		// Its folder is a project now: refused, nothing opened or seeded.
		bed.Session.Close();
		bed.Mode.Enter();
		bed.Mode.CreateFrom(made, "Again");
		Test.Assert(view.Status == "That folder is a project already: Open Folder opens it.");
		Test.Assert(bed.Session.Project == null);
		Test.Assert(bed.Seeds == 1);
		Test.Assert(bed.ShowsManager);
	}

	[Test]
	public static void CloseProjectAsksAboutTheUnsavedPagesThenClosesItAndShowsTheManager()
	{
		let bed = scope ModeBed("scratch_manager_mode_close");
		// No project: nothing to close, nothing asked.
		bed.Mode.CloseProject();
		bed.Drain();
		Test.Assert(PagesBed.FindBox(bed.Pages.Root) == null);
		Test.Assert(bed.Shown == null);

		let dir = bed.MadeProject("Harbour", "Harbour", .. scope .());
		Test.Assert(bed.Mode.OpenProject(dir));
		let page = (PagesTestPage)bed.Pages.Pages.Open(bed.Pages.One);
		Test.Assert(page != null);
		page.MarkDirty();

		bed.Mode.CloseProject();
		var question = bed.Question();
		Test.Assert(question.Title == "Unsaved changes");
		Test.Assert(PagesBed.ButtonNamed(question, "Save All and Close") != null);
		Test.Assert(PagesBed.ButtonNamed(question, "Cancel").HandleActivate());
		bed.Drain();
		Test.Assert(bed.Session.Project != null, "Cancel stays");
		Test.Assert(bed.Shown == null);

		bed.Mode.CloseProject();
		question = bed.Question();
		Test.Assert(PagesBed.ButtonNamed(question, "Close Without Saving").HandleActivate());
		Test.Assert(bed.Session.Project != null, "not inside the click");
		bed.Drain();
		Test.Assert(bed.Session.Project == null);
		Test.Assert(bed.ShowsManager);
		Test.Assert(page.Saves == 0);
		Test.Assert(bed.Mode.View.ShownCount == 1, "the project it closed listed");

		// Save All and Close saves first; nothing unsaved closes with no question.
		Test.Assert(bed.Mode.OpenProject(dir));
		Test.Assert(bed.Shown == null);
		bed.Mode.CloseProject();
		question = bed.Question();
		Test.Assert(PagesBed.ButtonNamed(question, "Save All and Close").HandleActivate());
		Test.Assert(page.Saves == 1);
		bed.Drain();
		Test.Assert(bed.Session.Project == null);
		Test.Assert(bed.ShowsManager);
		Test.Assert(bed.Mode.OpenProject(dir));
		bed.Mode.CloseProject();
		Test.Assert(PagesBed.FindBox(bed.Pages.Root) == null, "nothing unsaved: nothing asked");
		bed.Drain();
		Test.Assert(bed.Session.Project == null);
		Test.Assert(bed.ShowsManager);
	}
}
