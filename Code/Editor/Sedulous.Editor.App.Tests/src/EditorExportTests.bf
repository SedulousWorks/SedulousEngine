using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.Pipeline.Core;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// EditorExport: an export asks for a project and runs one at a time; it cooks first, then
/// hands the job to the job service, whose failure is a notice; the templates' folder is the
/// user's override when there is one; the presets save to the project and are read back when it
/// opens again; a resource report with no project is a line in the log, not a crash.
class EditorExportTests
{
	/// The services an exporter runs on, over the real cook and job services; the notices land
	/// in Said, the last one in Last.
	class Bench
	{
		public EditorContext Context = new .() ~ delete _;
		public BuilderRegistry Builders = new .() ~ delete _;
		public EditorCookService Cook = new .() ~ delete _;
		public TaskPool Tasks = new .(2) ~ delete _;
		public TaskLane Lane = Tasks.CreateLane("Build");
		public Settings User = new .() ~ delete _;
		public List<String> Said = new .() ~ DeleteContainerAndItems!(_);
		public EditorProject Project = null ~ delete _;
		public String Dir = new .() ~ delete _;

		public this()
		{
			let said = Said;
			Context.OnNotice = new [=said](kind, message) => { said.Add(new String(message)); };
		}

		public ~this()
		{
			Cook.Shutdown();
			DeleteAndNullify!(Tasks); // drops what waits and joins what runs, before the project goes
			if (Project != null)
			{
				DeleteAndNullify!(Project);
				RemoveDirectoryRecursive(Dir);
			}
		}

		/// A scratch project, the cook initialised over it as the application does.
		public void OpenProject(StringView leaf)
		{
			Dir.Set(leaf);
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "Export") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Cook.Initialize(Project, Builders);
			let tasks = Tasks;
			let lane = Lane;
			Cook.ExternalMutationLock = new [=tasks, =lane]() => tasks.IsLaneBusy(lane);
		}

		/// The services over this bench; the exporter owns them.
		public EditorExportServices Services()
		{
			let services = new EditorExportServices();
			services.Context = Context;
			services.Cook = Cook;
			services.Tasks = Tasks;
			services.Lane = Lane;
			services.Builders = Builders;
			services.UserSettings = User;
			return services;
		}

		public StringView Last => Said.IsEmpty ? "" : Said.Back;
	}

	[Test]
	public static void AnExportWithNoProjectSaysToOpenOneAndTheTemplatesFollowTheOverride()
	{
		let bench = scope Bench();
		let exporter = scope EditorExport(bench.Services());

		exporter.Run("Linux", false);
		Test.Assert(bench.Last == "Open a project first.");
		Test.Assert(!exporter.IsPending);

		bench.User.Section<EditorExportSettings>().TemplatesRoot.Set("/shared/templates");
		Test.Assert(exporter.TemplatesRoot(.. scope .()) == "/shared/templates");

		EditorExport.ReportResourceMemory(null); // no project: said in the log
	}

	/// No user settings at all reads as no override: the root is the CLI's own resolution.
	[Test]
	public static void NoUserSettingsResolveTheTemplatesAsTheCliDoes()
	{
		let bench = scope Bench();
		let services = bench.Services();
		services.UserSettings = null;
		let exporter = scope EditorExport(services);
		let expected = ExportTemplates.ResolveRoot("", .. scope .());
		Test.Assert(exporter.TemplatesRoot(.. scope .()) == expected);
		// The main thread's registry always carries the host template, found or not.
		let registry = scope TemplateRegistry();
		exporter.BuildTemplateRegistry(registry);
		Test.Assert(registry.Count >= 1);
	}

	/// The flow the menu takes: a cook first, a second export refused while one is pending,
	/// the job submitted by the pump once the cook is done, and its failure (a preset the
	/// project does not have) a notice, never the success callback.
	[Test]
	public static void AnExportCooksFirstThenRunsOneJobWhoseFailureIsANotice()
	{
		let bench = scope Bench();
		bench.OpenProject("scratch_editor_export_run");
		let services = bench.Services();
		int exported = 0;
		services.OnExported = new [&exported](folder) => { exported++; };
		let exporter = scope EditorExport(services);
		exporter.SetProject(bench.Project);

		exporter.Run("No Such Preset", false);
		Test.Assert(bench.Last == "Cooking before export...");
		Test.Assert(exporter.IsPending);

		exporter.Run("No Such Preset", false);
		Test.Assert(bench.Last == "An export is already in progress.");

		// The editor's frame: the services' pumps, then the exporter's.
		bool sawJob = false;
		for (int i < 5000)
		{
			bench.Cook.Update();
			bench.Tasks.Pump();
			exporter.Pump();
			sawJob = sawJob || (bench.Tasks.InFlight > 0); // submitted by the pump above, handed back by the next
			if (!exporter.IsPending && (bench.Tasks.InFlight == 0) && (bench.Last == "Export failed (see Console)."))
				break;
			Thread.Sleep(1);
		}
		Test.Assert(!exporter.IsPending);
		Test.Assert(sawJob);
		Test.Assert(bench.Last == "Export failed (see Console).");
		Test.Assert(bench.Cook.Revision == 1); // the export's cook went through the cook service
		Test.Assert(exported == 0);
	}

	/// Export All's notice names the presets it skipped, their players building on another host;
	/// with none skipped it adds nothing.
	[Test]
	public static void ExportAllSaysWhichPresetsItSkipped()
	{
		let skipped = scope List<String>();
		defer { ClearAndDeleteItems!(skipped); }
		Test.Assert(EditorExport.SkippedNote(skipped, .. scope .()).IsEmpty, "nothing skipped, nothing said");
		skipped.Add(new .("Windows Desktop"));
		skipped.Add(new .("Windows Debug"));
		let note = EditorExport.SkippedNote(skipped, .. scope .());
		Test.Assert(note == " Skipped, their players building on another host: Windows Desktop, Windows Debug.", note);
	}

	/// The dialog's presets save to the project's export_presets.xml and read back; with no
	/// project the save does nothing.
	[Test]
	public static void ThePresetsSaveToTheProject()
	{
		let bench = scope Bench();
		let exporter = scope EditorExport(bench.Services());
		exporter.SavePresets(); // no project: nothing, and no notice
		Test.Assert(bench.Said.IsEmpty);

		bench.OpenProject("scratch_editor_export_presets");
		exporter.SetProject(bench.Project);
		ExportPresetsFile.Defaults(exporter.Presets.Set);
		Test.Assert(exporter.Presets.Count == 1);
		exporter.SavePresets();
		Test.Assert(bench.Said.IsEmpty);

		let loaded = scope ExportPresetSet();
		let projectFs = scope Sedulous.VFS.NativeFileSystem(bench.Project.Directory);
		Test.Assert(ExportPresetsFile.Load(projectFs, loaded) case .Ok);
		Test.Assert(loaded.Presets.Count == 1);
		Test.Assert(loaded.Presets[0].Name == exporter.Presets.At(0).Name);
	}

	/// A project's presets saved are read back when it opens again: a new export over the same
	/// project has them (they were saved and never read back, so a restart lost them).
	[Test]
	public static void AProjectsPresetsAreReadBackWhenItOpensAgain()
	{
		let bench = scope Bench();
		bench.OpenProject("scratch_editor_export_presets_again");
		{
			let first = scope EditorExport(bench.Services());
			first.SetProject(bench.Project);
			let defaults = first.Presets.Count;
			let deck = scope ExportPreset();
			deck.Name.Set("Steam Deck");
			deck.Platform.Set("Linux64");
			first.Presets.Add(deck);
			first.SavePresets();
			Test.Assert(first.Presets.Count == defaults + 1);
		}
		// The next session: a new export over the same project.
		let again = scope EditorExport(bench.Services());
		again.SetProject(bench.Project);
		var found = false;
		for (let preset in again.Presets.Set.Presets)
			found = found || (preset.Name == "Steam Deck");
		Test.Assert(found);
	}
}
