using System;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// The watch over a project's own code: the packages' newest file (what builds and the IDE write in
/// Code/ left out, a Plugins/ package's files counted), where the code stands against the built
/// editor and the running one, and a change told once.
class CodeWatchTests
{
	/// The packages' newest file: what builds and the Beef IDE write at the top of Code/ is not the
	/// game's; a file of the game's own, or of a Plugins/ package, is.
	[Test]
	public static void TheNewestSourceLeavesOutWhatBuildsWriteAndCountsAPluginsFiles()
	{
		let bed = scope ProjectBuildTests.Bed();
		let first = ProjectBuild.NewestSource(bed.ProjectDir, bed.Settings);
		Test.Assert(first > 0);

		Thread.Sleep(50);
		bed.WriteCode("build/Debug_Linux64/NativeGame/NativeGame.o", "object\n");
		bed.WriteCode(".generated/NativeGameEditor/src/Program.bf", "// generated\n");
		bed.WriteCode("recovery/Part.bf", "// the IDE's\n");
		bed.WriteCode("BeefConfig.toml", "Version = 1\n");
		bed.WriteCode("BeefSpace_User.toml", "[Workspace]\n");
		Test.Assert(ProjectBuild.NewestSource(bed.ProjectDir, bed.Settings) == first, "what builds and the IDE write is not the game's");

		bed.WriteCode("NativeGame/src/Part.bf", "// changed\n");
		let afterGame = ProjectBuild.NewestSource(bed.ProjectDir, bed.Settings);
		Test.Assert(afterGame > first, "the game's own file counts");

		Thread.Sleep(50);
		ProjectBuildTests.Bed.Write(bed.ProjectDir, "Plugins/Lantern/Lantern.Engine/src/Part.bf", "// changed\n");
		Test.Assert(ProjectBuild.NewestSource(bed.ProjectDir, bed.Settings) > afterGame, "a Plugins/ package's file counts");
	}

	/// Where the code stands, from the times alone: the built editor behind the code (or missing)
	/// is a build due; the running editor behind the code or the built editor is a relaunch due;
	/// a running editor whose time is not known says nothing.
	[Test]
	public static void TheStalenessOfTheTimes()
	{
		var state = ProjectBuild.Staleness(10, 0, 5);
		Test.Assert(state.BuildStale && state.RunningStale, "not built, and this editor older than the code");
		state = ProjectBuild.Staleness(10, 20, 30);
		Test.Assert(!state.BuildStale && !state.RunningStale, "this editor runs the newest build");
		state = ProjectBuild.Staleness(10, 20, 15);
		Test.Assert(!state.BuildStale && state.RunningStale, "built since this editor was");
		state = ProjectBuild.Staleness(25, 20, 22);
		Test.Assert(state.BuildStale && state.RunningStale, "changed since both");
		state = ProjectBuild.Staleness(25, 20, 0);
		Test.Assert(state.BuildStale && !state.RunningStale, "this editor's time not known");
		Test.Assert(!state.Unlinked);
		state = ProjectBuild.Staleness(10, 20, 30, false);
		Test.Assert(!state.BuildStale && state.RunningStale && state.Unlinked, "newer than all, but not linking the project's code");
		state = ProjectBuild.Staleness(10, 20, 0, false);
		Test.Assert(state.RunningStale, "not linking it says so with no time known");
	}

	/// An editor whose plugin host has the project's own package missing (not in this build, as
	/// this test binary's, which links no game) runs none of the project's code: stale whatever the
	/// times. A project with no package of its own needs none linked.
	[Test]
	public static void AnEditorNotLinkingTheProjectsPackageIsStale()
	{
		let bed = scope ProjectBuildTests.Bed();
		let subsystems = scope SubsystemManager();
		let host = scope PluginHost(subsystems, .Editor, EngineVersion.String);
		Test.Assert(!ProjectBuild.LinksPackages(bed.Settings, host), "the test binary's host has the game's package missing");
		Test.Assert(!ProjectBuild.LinksPackages(bed.Settings, null), "a host that loads no plugins links none");
		let none = scope ProjectSettings();
		none.Name.Set("Stock Game");
		Test.Assert(ProjectBuild.LinksPackages(none, host), "no package of its own: nothing to link");

		// Built, and this editor newer than the build and the code: fresh only when it links them.
		Thread.Sleep(50);
		let editor = ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", true, "Debug", .. scope .());
		ProjectBuildTests.Bed.Write(bed.ProjectDir, editor.Substring(bed.ProjectDir.Length + 1), "#!editor\n");
		let later = ProjectBuild.FileTime(editor) + 1;
		var state = ProjectBuild.Staleness(bed.ProjectDir, bed.Settings, "Debug", later, true);
		Test.Assert(!state.BuildStale && !state.RunningStale);
		state = ProjectBuild.Staleness(bed.ProjectDir, bed.Settings, "Debug", later, ProjectBuild.LinksPackages(bed.Settings, host));
		Test.Assert(!state.BuildStale && state.RunningStale && state.Unlinked);

		// Told once, saying the project's own editor runs its code.
		let watch = scope CodeWatch();
		Test.Assert(watch.Observe(10, 20, 30, false));
		Test.Assert(!watch.Observe(10, 20, 30, false), "told once");
		let text = CodeWatch.NoticeText(watch.State, .. scope .());
		Test.Assert(text.Contains("its own editor") && text.Contains("Build Project, then Open With This Build"), text);
	}

	/// Through the files: a change after the running build leaves the running editor stale, and a
	/// build after it leaves it stale still, until it runs the new build.
	[Test]
	public static void AChangeAfterTheRunningBuildLeavesItStale()
	{
		let bed = scope ProjectBuildTests.Bed();
		Thread.Sleep(50);
		let runningPath = PathJoin(bed.Root, "running/Editor", .. scope .());
		ProjectBuildTests.Bed.Write(bed.Root, "running/Editor", "#!editor\n");
		let running = ProjectBuild.FileTime(runningPath);
		Test.Assert(running > 0);
		Test.Assert(ProjectBuild.FileTime(PathJoin(bed.Root, "running/none", .. scope .())) == 0);

		var state = ProjectBuild.Staleness(bed.ProjectDir, bed.Settings, "Debug", running);
		Test.Assert(state.BuildStale && !state.RunningStale, "not built; this editor is newer than the code");

		Thread.Sleep(50);
		let editor = ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", true, "Debug", .. scope .());
		let relative = editor.Substring(bed.ProjectDir.Length + 1);
		ProjectBuildTests.Bed.Write(bed.ProjectDir, relative, "#!editor\n");
		state = ProjectBuild.Staleness(bed.ProjectDir, bed.Settings, "Debug", running);
		Test.Assert(!state.BuildStale && state.RunningStale, "the built editor is newer than this one");

		// Relaunched into the build: it runs from the built file, written when it was.
		let built = ProjectBuild.FileTime(editor);
		state = ProjectBuild.Staleness(bed.ProjectDir, bed.Settings, "Debug", built);
		Test.Assert(!state.BuildStale && !state.RunningStale);

		Thread.Sleep(50);
		bed.WriteCode("NativeGame/src/Part.bf", "// changed\n");
		state = ProjectBuild.Staleness(bed.ProjectDir, bed.Settings, "Debug", built);
		Test.Assert(state.BuildStale && state.RunningStale, "a change after the running build");

		Thread.Sleep(50);
		ProjectBuildTests.Bed.Write(bed.ProjectDir, relative, "#!editor again\n");
		state = ProjectBuild.Staleness(bed.ProjectDir, bed.Settings, "Debug", built);
		Test.Assert(!state.BuildStale && state.RunningStale, "built again: this editor still runs the old code");
	}

	/// A change the running editor lacks is told once: not again at the next sweep, nor for a build
	/// alone; a later change is told, and a sweep that finds nothing behind tells nothing. A reset
	/// (another project) tells again.
	[Test]
	public static void AChangeIsToldOnce()
	{
		let watch = scope CodeWatch();
		Test.Assert(!watch.Judged);
		Test.Assert(!watch.State.BuildStale && !watch.State.RunningStale);
		Test.Assert(watch.Observe(10, 0, 5), "the first sweep finds this editor behind");
		Test.Assert(watch.Judged && watch.State.BuildStale && watch.State.RunningStale);
		Test.Assert(!watch.Observe(10, 0, 5), "the same change, swept again");
		Test.Assert(!watch.Observe(10, 20, 5), "a build alone is no change to the code");
		Test.Assert(!watch.State.BuildStale && watch.State.RunningStale);
		Test.Assert(watch.Observe(12, 20, 5), "a later change");
		Test.Assert(!watch.Observe(12, 20, 30), "this editor runs the newest build");
		Test.Assert(!watch.State.RunningStale);
		Test.Assert(watch.Observe(40, 20, 30), "a change after it");
		watch.Reset();
		Test.Assert(!watch.Judged);
		Test.Assert(watch.Observe(40, 20, 30), "after a reset, told again");

		let quiet = scope CodeWatch();
		Test.Assert(!quiet.Observe(3, 4, 5), "nothing behind: nothing told");
		Test.Assert(quiet.Observe(6, 4, 5), "a change after this editor: told, the quiet sweep used nothing up");

		let text = scope String();
		CodeWatch.NoticeText(ProjectBuild.Staleness(10, 0, 5), text);
		Test.Assert(text.Contains("Build Project") && text.Contains("Open With This Build"), text);
		text.Clear();
		CodeWatch.NoticeText(ProjectBuild.Staleness(10, 20, 5), text);
		Test.Assert(!text.Contains("Build Project") && text.Contains("Open With This Build"), text);
	}
}
