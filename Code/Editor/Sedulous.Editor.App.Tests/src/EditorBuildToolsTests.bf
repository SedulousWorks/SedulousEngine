using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Runtime;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The build tools over a scratch project with a package of its own and a scratch SDK, their
/// builds run on a real build lane by the editor's build service with a fake BeefBuild: a build
/// waited for answers succeeded with what it made, a failed one its diagnostics (errors first,
/// files relative to the project, capped with the counts), one while another runs is refused,
/// build_status shows a running build's step and output and build_cancel ends it. editor_relaunch
/// refuses with nothing to open, an editor not built or older than the code, or unsaved pages it
/// cannot keep aside, and otherwise keeps them aside (or drops them), writes what the next editor
/// restores and starts the project's editor on this host's port with it, and exits; with build it
/// builds first, a failed build answered and nothing relaunched. Build and Relaunch, a person's,
/// builds, then asks about unsaved pages, or says why the build failed. host_info says whether the
/// project's editor is stale.
class EditorBuildToolsTests
{
	private const String cFixture = Compiler.ReadText("../Sedulous.Editor.Projects.Tests/src/Fixtures/beefbuild-errors.txt");
	/// Where the fixture's game lived; the bench's project stands in for it.
	private const String cFixtureProject = "/home/user/Games/Spike";
	/// What the fake runs; never started.
	private const String cFakeBeefBuild = "/fake/BeefBuild";

	/// What the fake BeefBuild does.
	enum FakeMode
	{
		/// Prints a line and makes what it was asked to.
		Build,
		/// Prints the fixture's errors and fails.
		FailFixture,
		/// Prints the fixture's errors and many more, and fails.
		FailMany,
		/// Prints two lines and waits until it is cancelled or released.
		Hold
	}

	/// The fake BeefBuild's mode and its hold, which the test thread and the build lane share.
	class Fake
	{
		public FakeMode Mode = .Build;
		public volatile bool Started;
		public volatile bool Release;
		public volatile int Runs;
	}

	/// A scratch SDK (what a build reads of it) with its data root, a project "Built" whose game
	/// package is in Code/ (an Engine part), a context with its build lane, the build service over
	/// the fake, and the tools on a server. Each relaunch's command line is kept, and the exits.
	class Bench
	{
		public String Root = new .() ~ delete _;
		public String Sdk = new .() ~ delete _;
		public String DataRoot = new .() ~ delete _;
		public String ProjectDir = new .() ~ delete _;
		public String Game = new .() ~ delete _;
		public EditorProject Project ~ delete _;
		public Fake FakeBuild = new .() ~ delete _;
		public EditorContext Context = new .() ~ delete _;
		public ProjectBuildService Service ~ delete _;
		public McpServer Server = new .() ~ delete _;
		public List<String> Unsaved = new .() ~ DeleteContainerAndItems!(_);
		public List<String> Launched = new .() ~ DeleteContainerAndItems!(_);
		public bool LaunchWorks = true;
		public int Exits = 0;
		/// The unsaved lines can be kept aside (each a kept page by its line); false refuses each.
		public bool KeepWorks = true;
		/// How often a person was asked about unsaved pages, and what goes on once they answer.
		public int Asks = 0;
		public delegate void() Proceed = null ~ delete _;
		/// How often the state the next editor reads was saved.
		public int StateSaves = 0;
		/// The notices a person heard.
		public List<String> Said = new .() ~ DeleteContainerAndItems!(_);

		public this(StringView leaf)
		{
			EditorSerializables.RegisterAll();
			let cwd = GetCurrentDirectory(.. scope .());
			PathJoin(cwd, scope $"scratch_build_tools_{leaf}", Root);
			RemoveDirectoryRecursive(Root);
			PathJoin(Root, "sdk", Sdk);
			PathJoin(Sdk, "Data", DataRoot);
			PathJoin(Root, "Built", ProjectDir);
			for (let library in StringView[6]("Code/Editor/Sedulous.Editor.Main", "Code/Engine/Sedulous.Engine.Player.DesktopMain",
				"Code/Engine/Sedulous.Engine.Player.WebMain", "Code/Editor/Sedulous.Editor.McpMain", "Code/Editor/Sedulous.Editor.CookMain",
				"Code/Editor/Sedulous.Editor.ExportMain"))
				Write(Sdk, scope $"{library}/BeefProj.toml", "");
			for (let stock in StringView[3](ProjectBuild.cStockEditorProject, ProjectBuild.cStockWebProject, ProjectBuild.cStockToolsProject))
				Write(Sdk, stock, "FileVersion = 1\n");
			MakeDirectories(DataRoot);

			MakeDirectories(ProjectDir);
			Test.Assert(EditorProject.Create(ProjectDir, "Built") case .Ok);
			Project = EditorProject.Open(ProjectDir);
			Test.Assert(Project != null);
			ProjectBuild.GameName(Project.Settings.Name, Game);
			AddGamePackage();

			let fake = FakeBuild;
			let bench = this;
			Service = new ProjectBuildService(new [=fake, =bench](executable, arguments, onLine, cancelled) =>
				{
					fake.Runs++;
					if ((fake.Mode == .FailFixture) || (fake.Mode == .FailMany))
					{
						let text = scope String(cFixture);
						text.Replace(cFixtureProject, bench.ProjectDir);
						for (let line in text.Split('\n'))
							onLine(line);
						if (fake.Mode == .FailMany)
						{
							for (int i < 55)
								onLine(scope $"ERROR: Problem {i} at line {i + 1}:1 in {bench.ProjectDir}/Code/{bench.Game}/src/Many.bf");
						}
						return Result<int, ErrorCode>.Ok(1);
					}
					onLine(scope $"Compiling {Argument(arguments, "project")}");
					if (fake.Mode == .Hold)
					{
						onLine("Compiling Sedulous.Core");
						fake.Started = true;
						while (!fake.Release)
						{
							if (cancelled())
								return Result<int, ErrorCode>.Err(.Cancelled);
							Thread.Sleep(1);
						}
					}
					bench.Make(arguments);
					return Result<int, ErrorCode>.Ok(0);
				}, cFakeBeefBuild);
			let said = Said;
			Context.OnNotice = new [=said] (kind, message) => { said.Add(new String(message)); };
			EditorBuildTools.Register(Server, MakeSeams());
		}

		/// The seams over the bench, as the editor makes them: the tools' and Build and
		/// Relaunch's. The caller's.
		public BuildToolSeams MakeSeams()
		{
			let bench = this;
			let seams = new BuildToolSeams();
			seams.Service = Service;
			seams.Context = Context;
			seams.DataRoot.Set(DataRoot);
			seams.KeepAside = new [=bench](folder, state, outRefused) =>
				{
					for (let line in bench.Unsaved)
					{
						if (!bench.KeepWorks)
						{
							outRefused.Add(new .(line));
							continue;
						}
						let kept = new RelaunchState.KeptPage();
						kept.Title.Set(line);
						state.Kept.Add(kept);
					}
					return outRefused.IsEmpty;
				};
			seams.AskUnsaved = new [=bench](proceed) =>
				{
					bench.Asks++;
					delete bench.Proceed;
					bench.Proceed = proceed;
				};
			seams.SaveState = new [=bench](state) =>
				{
					bench.StateSaves++;
					let game = new RelaunchState.GameTab();
					game.PieId.Set(RelaunchState.cPrimaryGame);
					game.Playing = true;
					state.Games.Add(game);
				};
			seams.Start = new [=bench](target, config, platform, outError) =>
				EditorBuildTools.StartBuild(bench.Context, bench.Service, bench.Project, bench.DataRoot, target, config, platform, outError);
			seams.Project = new [=bench]() => bench.Project;
			seams.UnsavedWork = new [=bench](outLines) =>
				{
					for (let line in bench.Unsaved)
						outLines.Add(new .(line));
				};
			seams.McpPort = new () => (uint16)7419;
			seams.Launch = new [=bench](executable, arguments) =>
				{
					bench.Launched.Add(new .(executable));
					for (let argument in arguments)
						bench.Launched.Add(new .(argument));
					return bench.LaunchWorks;
				};
			seams.Exit = new [=bench]() => { bench.Exits++; };
			return seams;
		}

		public ~this()
		{
			// The lane's work ends before the service and the project it reads go.
			Context.Tasks.CancelAll();
			Context.Tasks.Finish();
			DeleteAndNullify!(Project); // closed before its folder goes
			RemoveDirectoryRecursive(Root);
		}

		/// The game's package: Code/ with its manifest and its Engine part's project, enabled in
		/// the project's settings (in memory: the build copies them).
		private void AddGamePackage()
		{
			let entry = new EnabledPlugin();
			entry.Id.Set("built");
			entry.Path.Set("Code");
			Project.Settings.Plugins.Add(entry);
			let manifest = scope PluginManifest();
			manifest.Id.Set("built");
			manifest.Name.Set("Built");
			manifest.Version.Set("0.1.0");
			manifest.EngineVersion.Set("0.1");
			let part = new PluginManifestPart();
			part.Kind.Set("Engine");
			manifest.Parts.Add(part);
			let xml = scope String();
			Test.Assert(manifest.Write(xml) case .Ok);
			Write(ProjectDir, "Code/Plugin.xml", xml);
			Write(ProjectDir, scope $"Code/{Game}/BeefProj.toml", "");
			Write(ProjectDir, scope $"Code/{Game}/src/Game.bf", "// the game\n");
		}

		/// The project's editor, as a build that worked makes it.
		public void MakeEditor()
		{
			let path = ProjectBuild.ExecutablePath(ProjectDir, Game, true, "Debug", .. scope .());
			Write(ProjectDir, path.Substring(ProjectDir.Length + 1), "#!built\n");
		}

		/// Writes the executable a BeefBuild run of `arguments` would make.
		public void Make(Span<StringView> arguments)
		{
			let editor = Argument(arguments, "project").EndsWith(ProjectBuild.cEditorSuffix);
			let path = ProjectBuild.ExecutablePath(ProjectDir, Game, editor, Argument(arguments, "config"), .. scope .());
			Write(ProjectDir, path.Substring(ProjectDir.Length + 1), "#!built\n");
		}

		public static void Write(StringView dir, StringView relative, StringView text)
		{
			let path = PathJoin(dir, relative, .. scope .());
			MakeDirectories(PathParent(path, .. scope .()));
			Test.Assert(WriteFile(path, .((uint8*)text.Ptr, text.Length)) case .Ok);
		}

		public static void MakeDirectories(StringView dir)
		{
			if (DirectoryExists(dir))
				return;
			MakeDirectories(PathParent(dir, .. scope .()));
			CreateDirectory(dir);
		}
	}

	/// The value of `-name=` among `arguments`.
	private static StringView Argument(Span<StringView> arguments, StringView name)
	{
		let prefix = scope $"-{name}=";
		for (let argument in arguments)
		{
			if (argument.StartsWith(prefix))
				return argument.Substring(prefix.Length);
		}
		return default;
	}

	/// A tools/call's answer: the payload when it succeeded, OWNED, or the error text.
	class Answer
	{
		public bool Ok;
		public JsonValue Payload ~ delete _;
		public String Error = new .() ~ delete _;
	}

	/// One tools/call, entered again as the host would each frame while it answers not yet (the
	/// lane's completions pumped between), for up to about ten seconds.
	private static Answer Call(Bench bench, StringView tool, StringView argumentsJson)
	{
		let line = scope String();
		line.AppendF("{{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{{\"name\":\"{}\",\"arguments\":{}}}}}", tool, argumentsJson);
		let reply = scope String();
		LineState state = .NotFinished;
		for (int i = 0; i < 10000; i++)
		{
			reply.Clear();
			state = bench.Server.HandleLine(line, reply);
			if (state != .NotFinished)
				break;
			bench.Context.Tasks.Pump();
			Thread.Sleep(1);
		}
		Test.Assert(state == .Answered, scope String()..AppendF("{} never answered", tool));
		let response = JsonValue.Parse(reply);
		defer delete response;
		let result = response.Get("result");
		let answer = new Answer();
		if (result == null)
		{
			answer.Ok = false;
			answer.Error.Set(response.Get("error").Get("message").AsString());
			return answer;
		}
		answer.Ok = !result.Get("isError").AsBool();
		let text = result.Get("content").At(0).Get("text").AsString();
		if (answer.Ok)
			answer.Payload = JsonValue.Parse(text);
		else
			answer.Error.Set(text);
		return answer;
	}

	/// Pumps the lane until `job` has ended, for up to about ten seconds.
	private static void WaitEnded(Bench bench, BuildJob job)
	{
		for (int i = 0; (i < 10000) && !job.IsEnded; i++)
		{
			bench.Context.Tasks.Pump();
			Thread.Sleep(1);
		}
		Test.Assert(job.IsEnded);
		bench.Context.Tasks.Pump(); // its completion
	}

	[Test]
	public static void RegistersItsFourTools()
	{
		let server = scope McpServer();
		EditorBuildTools.Register(server, new BuildToolSeams());
		Test.Assert(server.ToolCount == EditorBuildTools.cBuildToolCount);
	}

	/// A build of the editor waited for: one BeefBuild run, answered succeeded with its step, its
	/// duration, no diagnostics and the editor it made; build_status then shows it ended, its
	/// output, and the editor no longer stale.
	[Test]
	public static void AWaitedBuildAnswersSucceededWithWhatItMade()
	{
		let bench = scope Bench("succeeds");
		{
			let status = Call(bench, "build_status", "{}");
			defer delete status;
			Test.Assert(status.Ok);
			Test.Assert(!status.Payload.Get("building").AsBool());
			Test.Assert(status.Payload.Get("last").IsNull);
			Test.Assert(status.Payload.Get("stale").AsBool(), "not built");
		}
		let answer = Call(bench, "project_build", "{\"target\":\"editor\"}");
		defer delete answer;
		Test.Assert(answer.Ok, answer.Error);
		let payload = answer.Payload;
		Test.Assert(bench.FakeBuild.Runs == 1);
		Test.Assert(payload.Get("state").AsString() == "succeeded");
		Test.Assert(payload.Get("target").AsString() == "editor");
		Test.Assert(payload.Get("id").AsNumber() == 1);
		let editorProject = scope $"{bench.Game}{ProjectBuild.cEditorSuffix}";
		let steps = payload.Get("steps");
		Test.Assert((steps.Count == 1) && (steps.At(0).Get("project").AsString() == editorProject) && (steps.At(0).Get("config").AsString() == "Debug"));
		Test.Assert(payload.Get("step").Get("project").AsString() == editorProject);
		Test.Assert(payload.Get("durationMs").AsNumber() >= 0);
		Test.Assert((payload.Get("errorCount").AsNumber() == 0) && (payload.Get("warningCount").AsNumber() == 0));
		Test.Assert(payload.Get("diagnostics").Count == 0);
		Test.Assert(!payload.Has("error"));
		let executables = payload.Get("executables");
		Test.Assert(executables.Count == 1);
		Test.Assert(executables.At(0).AsString() == ProjectBuild.ExecutablePath(bench.ProjectDir, bench.Game, true, "Debug", .. scope .()));

		let status = Call(bench, "build_status", "{\"tail\":5}");
		defer delete status;
		Test.Assert(status.Ok);
		Test.Assert(!status.Payload.Get("building").AsBool());
		let last = status.Payload.Get("last");
		Test.Assert(last.Get("state").AsString() == "succeeded");
		let output = last.Get("output");
		Test.Assert((output.Count == 1) && (output.At(0).AsString() == scope $"Compiling {editorProject}"));
		Test.Assert(!status.Payload.Get("stale").AsBool(), "just built");
	}

	/// The player target builds the game's player as an export of a preset would: this host's
	/// platform and Release (the shipping build) by default, a Profile config as a Release build,
	/// one BeefBuild run each answered with the player it made. Another host's platform is refused
	/// before anything runs; the web is wasm32, and a Test config is no player.
	[Test]
	public static void ThePlayerTargetBuildsAPresetsPlayer()
	{
		let bench = scope Bench("player");
		let player = scope $"{bench.Game}Player";
		for (int round < 2)
		{
			let answer = Call(bench, "project_build", (round == 0) ? "{\"target\":\"player\"}" : "{\"target\":\"player\",\"config\":\"Profile\"}");
			defer delete answer;
			Test.Assert(answer.Ok, answer.Error);
			let payload = answer.Payload;
			StringView built = (round == 0) ? "Debug" : "Release"; // none given: Debug
			Test.Assert(bench.FakeBuild.Runs == round + 1);
			Test.Assert(payload.Get("state").AsString() == "succeeded");
			Test.Assert(payload.Get("target").AsString() == "player");
			let steps = payload.Get("steps");
			Test.Assert((steps.Count == 1) && (steps.At(0).Get("project").AsString() == player) && (steps.At(0).Get("config").AsString() == built),
				scope String(steps.At(0).Get("config").AsString()));
			let executables = payload.Get("executables");
			Test.Assert((executables.Count == 1) && (executables.At(0).AsString() == ProjectBuild.ExecutablePath(bench.ProjectDir, bench.Game, false, built, .. scope .())));
		}

		StringView otherHost = (BuildLayout.HostPlatformName == "Win64") ? "Linux64" : "Win64";
		let refused = Call(bench, "project_build", scope $"{{\"target\":\"player\",\"platform\":\"{otherHost}\"}}");
		defer delete refused;
		Test.Assert(!refused.Ok && refused.Error.Contains(scope $"a {otherHost} player builds on"), refused.Error);
		Test.Assert(bench.FakeBuild.Runs == 2, "nothing more ran");

		let config = scope String();
		let platform = scope String();
		let error = scope String();
		let web = JsonValue.Parse("{\"platform\":\"Web\",\"config\":\"Debug\"}");
		defer delete web;
		Test.Assert(EditorBuildTools.PlayerStep(web, config, platform, error), error);
		Test.Assert((platform == "wasm32") && (config == "Debug"), platform);
		let testConfig = JsonValue.Parse("{\"config\":\"Test\"}");
		defer delete testConfig;
		Test.Assert(!EditorBuildTools.PlayerStep(testConfig, config, platform, error) && error.Contains("links the test runner"), error);
	}

	/// A failed build is an answer, not a tool error: state failed, the counts, the diagnostics
	/// with errors first, a file in the project relative to it and one outside absolute, a
	/// warning's code and a note's place. Past the cap the errors fill it and the rest are counted.
	[Test]
	public static void AFailedBuildAnswersItsDiagnosticsCappedWithRelativePaths()
	{
		let bench = scope Bench("fails");
		bench.FakeBuild.Mode = .FailFixture;
		{
			let answer = Call(bench, "project_build", "{}");
			defer delete answer;
			Test.Assert(answer.Ok, answer.Error);
			let payload = answer.Payload;
			Test.Assert(payload.Get("state").AsString() == "failed");
			Test.Assert(payload.Get("error").AsString().StartsWith(scope $"BeefBuild failed building {bench.Game}Editor (Debug), exit 1, 4 errors"));
			Test.Assert((payload.Get("errorCount").AsNumber() == 4) && (payload.Get("warningCount").AsNumber() == 6));
			Test.Assert(payload.Get("diagnosticsOmitted").AsNumber() == 0);
			let diagnostics = payload.Get("diagnostics");
			Test.Assert(diagnostics.Count == 10);
			for (int i < 10)
				Test.Assert(diagnostics.At(i).Get("severity").AsString() == ((i < 4) ? "error" : "warning"), "errors first");
			let first = diagnostics.At(0);
			Test.Assert(first.Get("file").AsString() == "Code/Game/src/Other.bf", scope String(first.Get("file").AsString()));
			Test.Assert((first.Get("line").AsNumber() == 7) && (first.Get("column").AsNumber() == 17));
			Test.Assert(first.Get("message").AsString() == "Expression expected");
			Test.Assert(!first.Has("code") && !first.Has("notes"));
			Test.Assert(diagnostics.At(4).Get("code").AsString() == "BF0168");
			let duplicate = diagnostics.At(7);
			Test.Assert(duplicate.Get("code").AsString() == "BF4200");
			Test.Assert(duplicate.Get("file").AsString() == "/home/user/Sedulous/Code/Foundation/Sedulous.Core/src/Math/Gradient.bf", "outside the project: as BeefBuild named it");
			let note = duplicate.Get("notes").At(0);
			Test.Assert(note.Get("message").AsString() == "Previous declaration");
			Test.Assert((note.Get("line").AsNumber() == 60) && (note.Get("column").AsNumber() == 62));
			Test.Assert(payload.Get("executables").Count == 0);
		}

		bench.FakeBuild.Mode = .FailMany;
		{
			let answer = Call(bench, "project_build", "{\"wait\":true}");
			defer delete answer;
			Test.Assert(answer.Ok, answer.Error);
			let payload = answer.Payload;
			Test.Assert(payload.Get("id").AsNumber() == 2);
			Test.Assert((payload.Get("errorCount").AsNumber() == 59) && (payload.Get("warningCount").AsNumber() == 6));
			let diagnostics = payload.Get("diagnostics");
			Test.Assert(diagnostics.Count == BuildJobJson.cMaxDiagnostics);
			Test.Assert(payload.Get("diagnosticsOmitted").AsNumber() == 65 - BuildJobJson.cMaxDiagnostics);
			for (int i < diagnostics.Count)
				Test.Assert(diagnostics.At(i).Get("severity").AsString() == "error", "the errors fill the cap");
			let many = diagnostics.At(4);
			Test.Assert(many.Get("file").AsString() == scope $"Code/{bench.Game}/src/Many.bf", scope String(many.Get("file").AsString()));
			Test.Assert(many.Get("message").AsString() == "Problem 0");
		}
	}

	/// Not waiting, project_build answers at once with the build's id and state. While it runs a
	/// second is refused, naming it; build_status shows its step and BeefBuild's last lines, and the
	/// editor stale; build_cancel stops it, it ends cancelled, and a second cancel is refused.
	[Test]
	public static void ARunningBuildIsRefusedFollowedAndCancelled()
	{
		let bench = scope Bench("running");
		bench.FakeBuild.Mode = .Hold;
		{
			let answer = Call(bench, "project_build", "{\"wait\":false}");
			defer delete answer;
			Test.Assert(answer.Ok, answer.Error);
			Test.Assert(answer.Payload.Get("id").AsNumber() == 1);
			Test.Assert(answer.Payload.Get("target").AsString() == "editor");
		}
		for (int i = 0; (i < 10000) && !bench.FakeBuild.Started; i++)
			Thread.Sleep(1);
		Test.Assert(bench.FakeBuild.Started);
		{
			let refused = Call(bench, "project_build", "{\"target\":\"player\"}");
			defer delete refused;
			Test.Assert(!refused.Ok);
			Test.Assert(refused.Error.Contains("build 1 (editor) is running"), refused.Error);
			Test.Assert(refused.Error.Contains("build_cancel"), refused.Error);
		}
		Test.Assert(bench.FakeBuild.Runs == 1, "nothing more started");
		{
			let status = Call(bench, "build_status", "{\"tail\":1}");
			defer delete status;
			Test.Assert(status.Ok);
			Test.Assert(status.Payload.Get("building").AsBool());
			let last = status.Payload.Get("last");
			Test.Assert(last.Get("state").AsString() == "building");
			Test.Assert(last.Get("step").Get("project").AsString() == scope $"{bench.Game}Editor");
			Test.Assert(last.Get("step").Get("config").AsString() == "Debug");
			let output = last.Get("output");
			Test.Assert((output.Count == 1) && (output.At(0).AsString() == "Compiling Sedulous.Core"), "the last line only");
			Test.Assert(status.Payload.Get("stale").AsBool());
		}
		{
			let relaunch = Call(bench, "editor_relaunch", "{}");
			defer delete relaunch;
			Test.Assert(!relaunch.Ok);
			Test.Assert(relaunch.Error.Contains("is running"), relaunch.Error);
		}
		{
			let cancelled = Call(bench, "build_cancel", "{}");
			defer delete cancelled;
			Test.Assert(cancelled.Ok, cancelled.Error);
			Test.Assert(cancelled.Payload.Get("cancelled").AsBool());
		}
		let job = bench.Service.GetLatest();
		defer job.ReleaseRef();
		WaitEnded(bench, job);
		Test.Assert(job.State == .Cancelled);
		{
			let status = Call(bench, "build_status", "{}");
			defer delete status;
			Test.Assert(status.Payload.Get("last").Get("state").AsString() == "cancelled");
			Test.Assert(!status.Payload.Get("building").AsBool());
		}
		{
			let again = Call(bench, "build_cancel", "{}");
			defer delete again;
			Test.Assert(!again.Ok);
			Test.Assert(again.Error.StartsWith("no build is running"), again.Error);
		}
	}

	/// A wait shorter than the build answers with the running state and timedOut; the build goes on
	/// and ends as it would have.
	[Test]
	public static void AWaitPastItsTimeoutAnswersTheRunningState()
	{
		let bench = scope Bench("timeout");
		bench.FakeBuild.Mode = .Hold;
		let answer = Call(bench, "project_build", "{\"timeoutSeconds\":1}");
		defer delete answer;
		Test.Assert(answer.Ok, answer.Error);
		Test.Assert(answer.Payload.Get("timedOut").AsBool());
		let state = answer.Payload.Get("state").AsString();
		Test.Assert((state == "building") || (state == "generating") || (state == "queued"), scope String(state));
		bench.FakeBuild.Release = true;
		let job = bench.Service.GetLatest();
		defer job.ReleaseRef();
		WaitEnded(bench, job);
		Test.Assert(job.State == .Succeeded);
	}

	/// The relaunch's refusals, in the order an agent meets them: no package of its own, the editor
	/// not built, older than the code, unsaved pages that cannot be kept aside (named, with the way
	/// to save them); then, with discardUnsaved, the project's editor started on the project, the
	/// data root, this host's port and the relaunch folder, and this editor told to exit. A launch
	/// that fails is said, exits nothing and leaves no relaunch folder.
	[Test]
	public static void RelaunchIsRefusedUntilTheEditorIsBuiltAndWhatIsUnsavedIsKeptOrDropped()
	{
		let bench = scope Bench("relaunch");
		let editor = ProjectBuild.ExecutablePath(bench.ProjectDir, bench.Game, true, "Debug", .. scope .());
		{
			let entry = bench.Project.Settings.Plugins.PopBack();
			defer bench.Project.Settings.Plugins.Add(entry);
			let refused = Call(bench, "editor_relaunch", "{}");
			defer delete refused;
			Test.Assert(!refused.Ok && refused.Error.Contains("no package of its own"), refused.Error);
		}
		{
			let refused = Call(bench, "editor_relaunch", "{}");
			defer delete refused;
			Test.Assert(!refused.Ok && refused.Error.Contains("is not built") && refused.Error.Contains("project_build first"), refused.Error);
		}
		Thread.Sleep(50);
		bench.MakeEditor();
		Thread.Sleep(50);
		Bench.Write(bench.ProjectDir, scope $"Code/{bench.Game}/src/Game.bf", "// changed\n");
		{
			let refused = Call(bench, "editor_relaunch", "{}");
			defer delete refused;
			Test.Assert(!refused.Ok && refused.Error.Contains("older than the game's code"), refused.Error);
		}
		Thread.Sleep(50);
		bench.MakeEditor();
		bench.Unsaved.Add(new .("Level1"));
		bench.Unsaved.Add(new .("The clip 'Bounce', in Hero"));
		let folder = RelaunchState.Folder(bench.ProjectDir, .. scope .());
		bench.KeepWorks = false;
		{
			let refused = Call(bench, "editor_relaunch", "{}");
			defer delete refused;
			Test.Assert(!refused.Ok, "unsaved pages that cannot be kept are never dropped unasked");
			Test.Assert(refused.Error.Contains("cannot be kept aside"), refused.Error);
			Test.Assert(refused.Error.Contains("Level1; The clip 'Bounce', in Hero"), refused.Error);
			Test.Assert(refused.Error.Contains("file.save") && refused.Error.Contains("discardUnsaved"), refused.Error);
		}
		Test.Assert(bench.Launched.IsEmpty && (bench.Exits == 0));
		Test.Assert(!DirectoryExists(folder), "a refused relaunch leaves no folder");

		bench.LaunchWorks = false;
		{
			let refused = Call(bench, "editor_relaunch", "{\"discardUnsaved\":true}");
			defer delete refused;
			Test.Assert(!refused.Ok && refused.Error.Contains("could not start"), refused.Error);
			Test.Assert(bench.Exits == 0);
			Test.Assert(!DirectoryExists(folder), "nor one whose launch failed");
		}
		ClearAndDeleteItems!(bench.Launched);
		bench.LaunchWorks = true;
		let answer = Call(bench, "editor_relaunch", "{\"discardUnsaved\":true}");
		defer delete answer;
		Test.Assert(answer.Ok, answer.Error);
		Test.Assert(answer.Payload.Get("relaunched").AsBool());
		Test.Assert(answer.Payload.Get("port").AsNumber() == 7419);
		Test.Assert(answer.Payload.Get("executable").AsString() == editor);
		Test.Assert(answer.Payload.Get("discardedUnsaved").Count == 2);
		Test.Assert(bench.Exits == 1);
		Test.Assert(!answer.Payload.Has("keptAside"), "dropped, not kept");
		let expected = scope StringView[](editor, "--project", bench.ProjectDir, "--data-root", bench.DataRoot, "--mcp", "--mcp-port", "7419",
			EditorRelaunch.cArgument, folder);
		Test.Assert(bench.Launched.Count == expected.Count, scope String()..AppendF("{} launched", bench.Launched.Count));
		for (int i < expected.Count)
			Test.Assert(bench.Launched[i] == expected[i], bench.Launched[i]);
		Test.Assert(FileExists(PathJoin(folder, RelaunchState.cFileName, .. scope .())), "the state the next editor reads");
	}

	/// An agent's relaunch keeps the unsaved pages aside rather than asking or dropping them: each
	/// named in the answer, the state the next editor reads written into the relaunch folder (the
	/// pages kept, the Game tabs, when it was launched, no build), with the save timed.
	[Test]
	public static void AnAgentsRelaunchKeepsTheUnsavedPagesAsideAndWritesWhatTheNextEditorRestores()
	{
		let bench = scope Bench("relaunch_keep");
		Thread.Sleep(50); // the editor newer than the code the bench wrote
		bench.MakeEditor();
		bench.Unsaved.Add(new .("Level1"));
		let answer = Call(bench, "editor_relaunch", "{}");
		defer delete answer;
		Test.Assert(answer.Ok, answer.Error);
		Test.Assert(answer.Payload.Get("relaunched").AsBool());
		let kept = answer.Payload.Get("keptAside");
		Test.Assert((kept != null) && (kept.Count == 1) && (kept.At(0).AsString() == "Level1"));
		Test.Assert(!answer.Payload.Has("discardedUnsaved"));
		Test.Assert(answer.Payload.Get("saveMs").AsNumber() >= 0);
		Test.Assert(!answer.Payload.Has("buildMs") && !answer.Payload.Has("build"), "nothing was built");
		Test.Assert((bench.Exits == 1) && (bench.StateSaves == 1) && (bench.Asks == 0));

		let folder = RelaunchState.Folder(bench.ProjectDir, .. scope .());
		let state = RelaunchState.Load(folder);
		defer delete state;
		Test.Assert(state != null);
		Test.Assert((state.Kept.Count == 1) && (state.Kept[0].Title == "Level1"));
		Test.Assert((state.Games.Count == 1) && (state.Games[0].PieId == RelaunchState.cPrimaryGame) && state.Games[0].Playing);
		Test.Assert(state.LaunchedTicks > 0);
		Test.Assert(state.BuildMs < 0);
	}

	/// build: true builds the editor first when it needs it, waits, then relaunches with the build's
	/// answer and its time; an editor that is fresh relaunches without building.
	[Test]
	public static void ARelaunchAskedToBuildBuildsFirstThenRelaunchesTimingTheBuild()
	{
		let bench = scope Bench("relaunch_build");
		{
			let answer = Call(bench, "editor_relaunch", "{\"build\":true}");
			defer delete answer;
			Test.Assert(answer.Ok, answer.Error);
			Test.Assert(bench.FakeBuild.Runs == 1);
			Test.Assert(answer.Payload.Get("relaunched").AsBool());
			Test.Assert(answer.Payload.Get("build").Get("state").AsString() == "succeeded");
			Test.Assert(answer.Payload.Get("buildMs").AsNumber() >= 0);
			Test.Assert(bench.Exits == 1);
			let state = RelaunchState.Load(RelaunchState.Folder(bench.ProjectDir, .. scope .()));
			defer delete state;
			Test.Assert((state != null) && (state.BuildMs >= 0), "the next editor logs the build's time");
		}
		let answer = Call(bench, "editor_relaunch", "{\"build\":true}");
		defer delete answer;
		Test.Assert(answer.Ok, answer.Error);
		Test.Assert(bench.FakeBuild.Runs == 1, "fresh: nothing built");
		Test.Assert(!answer.Payload.Has("build"));
		Test.Assert(bench.Exits == 2);
	}

	/// A relaunch whose build fails answers the build's diagnostics with its first error in the
	/// note, and relaunches nothing: no launch, no exit, no relaunch folder.
	[Test]
	public static void ARelaunchWhoseBuildFailsAnswersTheDiagnosticsAndStays()
	{
		let bench = scope Bench("relaunch_fails");
		bench.FakeBuild.Mode = .FailFixture;
		let answer = Call(bench, "editor_relaunch", "{\"build\":true}");
		defer delete answer;
		Test.Assert(answer.Ok, answer.Error);
		Test.Assert(!answer.Payload.Get("relaunched").AsBool());
		let build = answer.Payload.Get("build");
		Test.Assert(build.Get("state").AsString() == "failed");
		Test.Assert((build.Get("errorCount").AsNumber() == 4) && (build.Get("diagnostics").Count == 10));
		let note = answer.Payload.Get("note").AsString();
		Test.Assert(note.Contains("nothing relaunched") && note.Contains("Other.bf:7:17: Expression expected"), scope String(note));
		Test.Assert(bench.Launched.IsEmpty && (bench.Exits == 0) && (bench.StateSaves == 0));
		Test.Assert(!DirectoryExists(RelaunchState.Folder(bench.ProjectDir, .. scope .())));
	}

	/// Build and Relaunch, a person's: it builds the stale editor on the lane, and once the build
	/// ends asks about the unsaved pages, relaunching only when they answer, with the relaunch
	/// folder on the command line.
	[Test]
	public static void BuildAndRelaunchBuildsThenAsksAboutUnsavedPagesThenRelaunches()
	{
		let bench = scope Bench("person");
		bench.Unsaved.Add(new .("Level1"));
		let person = scope BuildAndRelaunch(bench.MakeSeams());
		person.Run();
		Test.Assert(person.IsBuilding);
		let job = bench.Service.GetLatest();
		defer job.ReleaseRef();
		WaitEnded(bench, job);
		Test.Assert(job.State == .Succeeded);
		person.Update();
		Test.Assert(!person.IsBuilding);
		Test.Assert(bench.Asks == 1, "a person is asked");
		Test.Assert(bench.Launched.IsEmpty && (bench.Exits == 0), "nothing until they answer");
		bench.Proceed(); // Save All, or Relaunch Without Saving
		Test.Assert(bench.Exits == 1);
		let folder = RelaunchState.Folder(bench.ProjectDir, .. scope .());
		Test.Assert(bench.Launched.Count >= 2);
		Test.Assert((bench.Launched[bench.Launched.Count - 2] == EditorRelaunch.cArgument) && (bench.Launched.Back == folder), bench.Launched.Back);
		let state = RelaunchState.Load(folder);
		defer delete state;
		Test.Assert((state != null) && state.Kept.IsEmpty, "a person's pages are saved or dropped, never kept");
		Test.Assert(state.BuildMs >= 0);
	}

	/// A failed build stops Build and Relaunch there: said with its first error, nothing launched,
	/// nothing asked.
	[Test]
	public static void BuildAndRelaunchStaysWhenTheBuildFailsSayingItsFirstError()
	{
		let bench = scope Bench("person_fails");
		bench.FakeBuild.Mode = .FailFixture;
		let person = scope BuildAndRelaunch(bench.MakeSeams());
		person.Run();
		let job = bench.Service.GetLatest();
		defer job.ReleaseRef();
		WaitEnded(bench, job);
		person.Update();
		Test.Assert(!person.IsBuilding);
		Test.Assert(!bench.Said.IsEmpty);
		let said = bench.Said.Back;
		Test.Assert(said.Contains("the build failed (4 error(s))") && said.Contains("Expression expected"), said);
		Test.Assert(bench.Launched.IsEmpty && (bench.Exits == 0) && (bench.Asks == 0));
	}

	/// The relaunch's command line: the project and the data root always; the MCP host's flags
	/// only when it serves, its port only when one is named.
	[Test]
	public static void TheRelaunchCommandLinePassesTheMcpPortOn()
	{
		let arguments = scope List<String>();
		defer { ClearAndDeleteItems!(arguments); }
		EditorBuildTools.RelaunchArguments("Games/Built", "/engine/Data", true, 7420, arguments);
		let expected = StringView[7]("--project", "Games/Built", "--data-root", "/engine/Data", "--mcp", "--mcp-port", "7420");
		Test.Assert(arguments.Count == expected.Count);
		for (int i < expected.Count)
			Test.Assert(arguments[i] == expected[i], arguments[i]);
		ClearAndDeleteItems!(arguments);
		EditorBuildTools.RelaunchArguments("Games/Built", "/engine/Data", true, 0, arguments);
		Test.Assert((arguments.Count == 5) && (arguments[4] == "--mcp"), "the preference's port");
		ClearAndDeleteItems!(arguments);
		EditorBuildTools.RelaunchArguments("Games/Built", "/engine/Data", false, 7420, arguments);
		Test.Assert(arguments.Count == 4, "no MCP");
	}

	/// A diagnostic's file is relative only when it lies inside the project, whole folder names.
	[Test]
	public static void AFileIsRelativeOnlyInsideTheProject()
	{
		Test.Assert(BuildJobJson.RelativeFile("/games/Built/Code/Built/src/Game.bf", "/games/Built", .. scope .()) == "Code/Built/src/Game.bf");
		Test.Assert(BuildJobJson.RelativeFile("/games/BuiltOther/src/Game.bf", "/games/Built", .. scope .()) == "/games/BuiltOther/src/Game.bf");
		Test.Assert(BuildJobJson.RelativeFile("/engine/Code/Core.bf", "/games/Built", .. scope .()) == "/engine/Code/Core.bf");
		Test.Assert(BuildJobJson.RelativeFile("/games/Built/", "/games/Built", .. scope .()) == "/games/Built/");
	}

	/// host_info says whether the project's own editor is stale, for a project with a package of
	/// its own: true unbuilt, false once built; nothing for one the stock editor runs. And whether
	/// this process is: older than the code before the build (the bench's files are written as the
	/// test runs), older than the built editor after it.
	[Test]
	public static void HostInfoSaysWhetherTheProjectsEditorIsStale()
	{
		let bench = scope Bench("host_info");
		let logBuffer = scope EditorLogBuffer();
		let builders = scope BuilderRegistry();
		let importers = scope ImporterRegistry();
		let session = scope ProjectSession();
		session.Project = bench.Project;
		let operations = scope InlineProjectOperations(session, builders, "");
		let host = scope EditorMcpHost(bench.Context, session, logBuffer, builders, importers, scope EngineToolPaths(), operations, "stamp");
		let line = "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"host_info\",\"arguments\":{}}}";

		for (int round < 3)
		{
			if (round == 1)
			{
				Thread.Sleep(50); // newer than the package's files
				bench.MakeEditor();
			}
			if (round == 2)
				delete bench.Project.Settings.Plugins.PopBack();
			let reply = scope String();
			Test.Assert(host.Server.HandleLine(line, reply) == .Answered);
			let response = JsonValue.Parse(reply);
			defer delete response;
			let payload = JsonValue.Parse(response.Get("result").Get("content").At(0).Get("text").AsString());
			defer delete payload;
			let hostState = payload.Get("host");
			switch (round)
			{
			case 0:
				Test.Assert(hostState.Get("buildStale").AsBool(), "not built");
				Test.Assert(hostState.Get("runningStale").AsBool(), "this process is older than the code");
			case 1:
				Test.Assert(!hostState.Get("buildStale").AsBool(), "just built");
				Test.Assert(hostState.Get("runningStale").AsBool(), "this process is older than the built editor");
			default:
				Test.Assert(!hostState.Has("buildStale"), "no package of its own");
				Test.Assert(!hostState.Has("runningStale"));
			}
		}
		session.Project = null;
	}
}
