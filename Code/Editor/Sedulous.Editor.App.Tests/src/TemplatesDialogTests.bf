using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.App.Tests;

/// The export templates dialog over a scratch templates root: it lists what the root holds and
/// the host build, shows the selected one's details (its engine version, warned when not this
/// editor's), installs a bundle from a folder, and removes one (never the host build).
class TemplatesDialogTests
{
	/// A template bundle in `dir`: its manifest and a player file.
	private static void WriteBundle(StringView dir, StringView id, StringView name, StringView engineVersion)
	{
		Test.Assert(CreateDirectory(dir));
		let template = scope ExportTemplate();
		template.Id.Set(id);
		template.Name.Set(name);
		template.Platform.Set("Linux64");
		template.Config.Set("Release");
		template.EngineVersion.Set(engineVersion);
		template.PlayerBinary.Set("Sedulous.Engine.Player.Desktop");
		template.Sidecars.Add(new .("libwgpu_native.so"));
		template.Notes.Set("for the test");
		Test.Assert(ExportTemplates.SaveManifest(scope NativeFileSystem(dir), template) case .Ok);
		let player = "#!player\n";
		Test.Assert(WriteFile(PathJoin(dir, "Sedulous.Engine.Player.Desktop", .. scope .()), .((uint8*)player.Ptr, player.Length)) case .Ok);
	}

	private class Fixture
	{
		public String Root = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_templates_dialog_root", .. new .()) ~ delete _;
		public String Source = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_templates_dialog_source", .. new .()) ~ delete _;
		public String HostDir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_templates_dialog_host", .. new .()) ~ delete _;
		public EditorContext Context = new .() ~ delete _;
		/// What the folder picker answers; empty is a cancel.
		public String Picked = new .() ~ delete _;
		public List<String> Revealed = new .() ~ DeleteContainerAndItems!(_);

		public this()
		{
			Clean();
			Test.Assert(CreateDirectory(Root));
			WriteBundle(PathJoin(Root, "t-linux", .. scope .()), "t-linux", "Linux Release", EngineVersion.String);
			WriteBundle(PathJoin(Root, "t-old", .. scope .()), "t-old", "Old Linux", "0.0.1");
			// The host build: a player beside the (pretend) editor.
			Test.Assert(CreateDirectory(HostDir));
			let player = "#!player\n";
			let playerPath = PathJoin(HostDir, BuildLayout.ExecutableName(BuildLayout.cPlayerBaseName, .. scope .()), .. scope .());
			Test.Assert(WriteFile(playerPath, .((uint8*)player.Ptr, player.Length)) case .Ok);
		}

		public ~this()
		{
			Clean();
		}

		private void Clean()
		{
			RemoveDirectoryRecursive(Root);
			RemoveDirectoryRecursive(Source);
			RemoveDirectoryRecursive(HostDir);
		}

		public TemplatesDialogSeams Seams()
		{
			let seams = new TemplatesDialogSeams();
			seams.TemplatesRoot = new [=this](outRoot) => { outRoot.Set(Root); };
			seams.Refresh = new [=this](registry) => { registry.Refresh(Root, HostDir); };
			seams.PickFolder = new [=this](chosen) =>
				{
					chosen(Picked);
					delete chosen;
				};
			seams.RevealFolder = new [=this](folder) => { Revealed.Add(new .(folder)); };
			return seams;
		}

		public static int IndexOf(TemplatesDialog dialog, StringView id)
		{
			for (int i < dialog.TemplateCount)
			{
				if (dialog.TemplateAt(i).Id == id)
					return i;
			}
			return -1;
		}
	}

	/// The root's templates and the host build are listed; the selected one's details show,
	/// a template built for another engine says so, and the host build is never removable.
	[Test]
	public static void ListsTheRootsTemplatesAndTheHostBuildTheSelectedOnesDetails()
	{
		let f = scope Fixture();
		let dialog = new TemplatesDialog(f.Context, f.Seams());
		defer dialog.ReleaseRef();
		Test.Assert(dialog.TemplateCount == 3, "two installed, the host build");
		Test.Assert(dialog.Selected != null, "the first, selected on open");

		let linuxIndex = Fixture.IndexOf(dialog, "t-linux");
		Test.Assert(linuxIndex >= 0);
		dialog.Select(linuxIndex);
		Test.Assert(dialog.DetailText("Platform") == "Linux64");
		Test.Assert(dialog.DetailText("Engine") == EngineVersion.String);
		Test.Assert(dialog.DetailText("Runtime files") == "libwgpu_native.so");
		Test.Assert(dialog.DetailText("Notes") == "for the test");
		Test.Assert(dialog.RemoveButton.IsEnabled);
		dialog.RevealButton.FireClick();
		Test.Assert(f.Revealed.Count == 1);
		Test.Assert(f.Revealed[0].EndsWith("t-linux"));

		// Built for another engine: it says so, and that an export still runs.
		dialog.Select(Fixture.IndexOf(dialog, "t-old"));
		Test.Assert(dialog.DetailText("Engine").StartsWith("0.0.1 (this editor is"));

		// The host build is this editor's own: never removable.
		for (int i < dialog.TemplateCount)
		{
			if (dialog.TemplateAt(i).IsHost)
				dialog.Select(i);
		}
		Test.Assert(dialog.Selected.IsHost);
		Test.Assert(!dialog.RemoveButton.IsEnabled);
		dialog.RemoveSelected(true);
		Test.Assert(dialog.TemplateCount == 3);
	}

	/// Install copies the picked folder's bundle in, lists and selects it; a cancelled pick
	/// does nothing; Remove deletes the folder and the row.
	[Test]
	public static void InstallsABundleFromAFolderAndRemovesOneTheListFollowing()
	{
		let f = scope Fixture();
		let dialog = new TemplatesDialog(f.Context, f.Seams());
		defer dialog.ReleaseRef();
		Test.Assert(dialog.TemplateCount == 3);

		WriteBundle(f.Source, "t-new", "New Linux", EngineVersion.String);
		f.Picked.Set(f.Source);
		dialog.InstallFromFolder();
		Test.Assert(dialog.TemplateCount == 4);
		Test.Assert((dialog.Selected != null) && (dialog.Selected.Id == "t-new"));
		Test.Assert(DirectoryExists(PathJoin(f.Root, "t-new", .. scope .())));

		// A cancelled pick does nothing.
		f.Picked.Clear();
		dialog.InstallFromFolder();
		Test.Assert(dialog.TemplateCount == 4);

		// Remove (confirmed): its folder goes, and so does its row.
		dialog.RemoveSelected(true);
		Test.Assert(dialog.TemplateCount == 3);
		Test.Assert(!DirectoryExists(PathJoin(f.Root, "t-new", .. scope .())));
		Test.Assert(Fixture.IndexOf(dialog, "t-new") < 0);
	}
}
