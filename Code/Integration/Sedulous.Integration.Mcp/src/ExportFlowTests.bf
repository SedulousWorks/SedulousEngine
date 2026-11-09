using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Composition;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Registration;
using Sedulous.VFS;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// project_export: a REAL dist from an authored project, its player from a stand in build
/// (StagedPlayerBuilder: no compiler runs), plus the refusals: no project, an unknown preset.
static class ExportFlowTests
{
	[Test]
	public static void ProjectExportMakesARealDistFromAnAuthoredProject()
	{
		let dir = Scratch("mcp_export_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		// Where the stand in builds go: the export's player without a compile.
		let playerDir = Scratch("mcp_export_player", .. scope .());
		defer RemoveDirectoryRecursive(playerDir);
		CreateDirectory(playerDir);
		let players = scope StagedPlayerBuilder(playerDir);
		let dataRoot = scope String();
		FindDataRoot(dataRoot);
		Test.Assert(!dataRoot.IsEmpty, "the Data/.dataroot walk from the test binary");

		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders, FindDataRoot(.. scope .()));
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		ProjectInfoTool.Register(server, session);
		let operations = scope InlineProjectOperations(session, builders, dataRoot);
		operations.Players = players;
		ProjectExportTool.Register(server, session, operations);

		let noProject = scope String();
		CallErr(server, "project_export", Obj(), noProject);
		Test.Assert(noProject.Contains("project_open"));
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Exportable"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));
		{
			let authored = scope Scene("main");
			EngineSceneComposition.AddAllSceneManagers(authored);
			authored.CreateEntity("anchor");
			let instance = session.Project.SourceDb.RootGroup.CreateInstance("main", McpTools.cSceneDocument);
			Test.Assert(SceneStorage.SaveScene(authored, instance) case .Ok);
		}
		let unknown = scope String();
		CallErr(server, "project_export", With(Obj(), "preset", "NoSuchPreset"), unknown);
		Test.Assert(unknown.Contains("available"), "the refusal lists the presets");

		let exported = CallOk(server, "project_export", Obj());
		defer delete exported;
		Test.Assert(exported.Get("exported").AsBool());
		Test.Assert(exported.Get("scenesStaged").AsInt() >= 1);
		Test.Assert(exported.Get("cookFailed").AsInt() == 0);
		let outputDir = scope String(exported.Get("outputDir").AsString());
		Test.Assert(!outputDir.IsEmpty);
		Test.Assert(FileExists(PathJoin(outputDir, "Content.pak", .. scope .())) && FileExists(PathJoin(outputDir, "player.xml", .. scope .())));
		Test.Assert(FileExists(PathJoin(outputDir, "Data/Engine/Shaders/shaders.dpak", .. scope .())), "the shader pack cooked from the data root");
		Test.Assert(exported.Get("filesStaged").AsInt() >= 1, "the player staged");
		Test.Assert(players.Builds == 1, "the export built its player");
		// Named by the game, the project's name made an identifier.
		Test.Assert(FileExists(PathJoin(outputDir, BuildLayout.ExecutableName("Exportable", .. scope .()), .. scope .())), "the game's player");
		Test.Assert(FileExists(PathJoin(outputDir, StagedPlayerBuilder.cLibrary, .. scope .())), "the libraries its build left beside it");
		Test.Assert(!FileExists(PathJoin(outputDir, StagedPlayerBuilder.cDxcLibrary, .. scope .())), "and not the shader compiler's");
		// The licences the player's binary carries go with it: a file the build leaves beside it.
		Test.Assert(FileExists(PathJoin(outputDir, BuildLayout.cThirdPartyNotices, .. scope .())), "the third-party notices arrive with the player");
		// A stand-in compiles nothing: there is no build job to report.
		Test.Assert(!exported.Get("build").Get("built").AsBool(), "nothing compiled the stand-in");
		Test.Assert(exported.Get("warning") == null, "no template, nothing to warn of");
	}

	/// What the fake BeefBuild never starts.
	private const String cFakeBeefBuild = "/fake/BeefBuild";
	/// The project's name, and so the game's: its player is ExportablePlayer.
	private const String cGame = "Exportable";

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

	/// `path`'s folder and the folders above it made, then `text` written there.
	private static void Write(StringView path, StringView text)
	{
		MakeDirectories(PathParent(path, .. scope .()));
		Test.Assert(WriteFile(path, .((uint8*)text.Ptr, text.Length)) case .Ok);
	}

	private static void MakeDirectories(StringView dir)
	{
		if (dir.IsEmpty || DirectoryExists(dir))
			return;
		MakeDirectories(PathParent(dir, .. scope .()));
		CreateDirectory(dir);
	}

	/// What a BeefBuild run of `arguments` leaves for the project in `projectDir`, as a build that
	/// worked: the desktop player, a shared library beside it and the notices.
	private static void MakePlayer(StringView projectDir, Span<StringView> arguments)
	{
		let made = ProjectBuild.EntryPath(projectDir, cGame, .Player, Argument(arguments, "config"), .. scope .());
		Write(made, "#!built\n");
		let dir = PathParent(made, .. scope .());
		Write(PathJoin(dir, StagedPlayerBuilder.cLibrary, .. scope .()), "so\n");
		Write(PathJoin(dir, BuildLayout.cThirdPartyNotices, .. scope .()), "notices\n");
	}

	private static JsonValue WithBool(JsonValue arguments, StringView key, bool value)
	{
		arguments.Set(key, JsonValue.MakeBool(value));
		return arguments;
	}

	/// The project "Exportable" made in `dir` and opened, with one authored scene.
	private static void OpenAuthored(McpServer server, ProjectSession session, StringView dir)
	{
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", cGame));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));
		let authored = scope Scene("main");
		EngineSceneComposition.AddAllSceneManagers(authored);
		authored.CreateEntity("anchor");
		let instance = session.Project.SourceDb.RootGroup.CreateInstance("main", McpTools.cSceneDocument);
		Test.Assert(SceneStorage.SaveScene(authored, instance) case .Ok);
	}

	/// The export builds the game's player through the project's build (a fake BeefBuild that
	/// leaves what a real one would, over this checkout as the SDK) and answers with that build as
	/// project_build gives one: its state, steps, counts and what it made. With `build: false` it
	/// runs no BeefBuild and ships what that build left, saying so.
	[Test]
	public static void ProjectExportReportsThePlayersBuildAndRepackagesOverIt()
	{
		let dir = Scratch("mcp_export_build", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let dataRoot = FindDataRoot(.. scope .());
		Test.Assert(!dataRoot.IsEmpty, "the Data/.dataroot walk from the test binary");
		int runs = 0;
		let service = scope ProjectBuildService(new [&](executable, arguments, onLine, cancelled) =>
			{
				runs++;
				onLine(scope $"Compiling {Argument(arguments, "project")}");
				MakePlayer(dir, arguments);
				return .Ok(0);
			}, cFakeBeefBuild);
		let players = scope ProjectPlayerBuilder(service, dataRoot);

		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders, dataRoot);
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		let operations = scope InlineProjectOperations(session, builders, dataRoot);
		operations.Players = players;
		ProjectExportTool.Register(server, session, operations);
		OpenAuthored(server, session, dir);

		let config = scope String();
		ProjectBuild.BuildConfigFor("Release", config);
		{
			let exported = CallOk(server, "project_export", Obj());
			defer delete exported;
			Test.Assert(exported.Get("exported").AsBool());
			Test.Assert(runs == 1, "the export ran BeefBuild once");
			Test.Assert(exported.Get("player").AsString() == scope $"{cGame}Player, {config}, {BuildLayout.HostPlatformName}",
				scope String(exported.Get("player").AsString()));
			let build = exported.Get("build");
			Test.Assert((build != null) && build.Get("built").AsBool(), "the build is reported");
			Test.Assert(build.Get("state").AsString() == "succeeded", scope String(build.Get("state").AsString()));
			Test.Assert(build.Get("target").AsString() == "player");
			Test.Assert((build.Get("steps").Count == 1) && (build.Get("steps").At(0).Get("project").AsString() == scope $"{cGame}Player")
				&& (build.Get("steps").At(0).Get("config").AsString() == config), "its one step: the player in the preset's config");
			Test.Assert((build.Get("errorCount").AsInt() == 0) && (build.Get("diagnostics").Count == 0), "no diagnostics");
			Test.Assert(build.Get("durationMs") != null);
			Test.Assert(build.Get("executables").Count == 1, "what it made");
			let outputDir = scope String(exported.Get("outputDir").AsString());
			Test.Assert(FileExists(PathJoin(outputDir, BuildLayout.ExecutableName(cGame, .. scope .()), .. scope .())), "the built player, named by the game");
			Test.Assert(FileExists(PathJoin(outputDir, StagedPlayerBuilder.cLibrary, .. scope .())), "the library its build left beside it");
		}

		// Without a build: nothing runs, what the last build left ships, and the answer says so.
		{
			let repackaged = CallOk(server, "project_export", WithBool(Obj(), "build", false));
			defer delete repackaged;
			Test.Assert(repackaged.Get("exported").AsBool());
			Test.Assert(runs == 1, "no BeefBuild ran");
			Test.Assert(!repackaged.Get("build").Get("built").AsBool(), "nothing compiled it");
			Test.Assert(repackaged.Get("player").AsString().EndsWith("(the last build)"), scope String(repackaged.Get("player").AsString()));
			let outputDir = scope String(repackaged.Get("outputDir").AsString());
			Test.Assert(FileExists(PathJoin(outputDir, BuildLayout.ExecutableName(cGame, .. scope .()), .. scope .())), "the last build's player");
		}
	}

	/// `build: false` with no build of the preset's config to ship is refused, saying so, and a
	/// player that does not compile refuses the export with BeefBuild's errors.
	[Test]
	public static void ProjectExportIsRefusedWithoutABuildToReuseOrWhenThePlayerDoesNotCompile()
	{
		let dir = Scratch("mcp_export_unbuilt", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let dataRoot = FindDataRoot(.. scope .());
		Test.Assert(!dataRoot.IsEmpty, "the Data/.dataroot walk from the test binary");
		int runs = 0;
		let service = scope ProjectBuildService(new [&](executable, arguments, onLine, cancelled) =>
			{
				runs++;
				onLine(scope $"ERROR: Broken player at line 3:1 in {dir}/Code/Broken.bf");
				return .Ok(1);
			}, cFakeBeefBuild);
		let players = scope ProjectPlayerBuilder(service, dataRoot);

		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders, dataRoot);
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		let operations = scope InlineProjectOperations(session, builders, dataRoot);
		operations.Players = players;
		ProjectExportTool.Register(server, session, operations);
		OpenAuthored(server, session, dir);

		let refusal = scope String();
		CallErr(server, "project_export", WithBool(Obj(), "build", false), refusal);
		Test.Assert(refusal.Contains("has not been built"), refusal);
		Test.Assert(runs == 0, "no BeefBuild ran");

		CallErr(server, "project_export", Obj(), refusal..Clear());
		Test.Assert(runs == 1);
		Test.Assert(refusal.Contains(scope $"BeefBuild failed building {cGame}Player"), refusal);
		Test.Assert(refusal.Contains("Broken player"), refusal);
	}
}
