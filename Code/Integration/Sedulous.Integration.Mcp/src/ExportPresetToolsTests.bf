using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// export_presets and export_preset_set: a project starts with the synthesized host preset,
/// a new preset is written beside it with only what was given changed, each says whether its
/// player builds here, a template id is no field any more, and a refusal changes nothing.
static class ExportPresetToolsTests
{
	private static JsonValue WithBool(JsonValue arguments, StringView key, bool value)
	{
		arguments.Set(key, JsonValue.MakeBool(value));
		return arguments;
	}

	[Test]
	public static void PresetsAreListedCreatedChangedAndRemoved()
	{
		let dir = Scratch("mcp_export_presets", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		ExportPresetTools.Register(server, session);

		let noProject = scope String();
		CallErr(server, "export_presets", Obj(), noProject);
		Test.Assert(noProject.Contains("project_open"));
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Presets"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		// No file: the synthesized host preset, whose player this host builds; no templates.
		{
			let listed = CallOk(server, "export_presets", Obj());
			defer delete listed;
			Test.Assert(listed.Get("synthesized").AsBool());
			Test.Assert(listed.Get("presets").Count == 1);
			let host = listed.Get("presets").At(0);
			Test.Assert(host.Get("platform").AsString() == BuildLayout.HostPlatformName);
			Test.Assert(host.Get("buildable").AsBool(), "the host's preset builds here");
			Test.Assert(host.Get("why").IsNull, "nothing to say for a preset that builds");
			Test.Assert(listed.Get("templates") == null, "no templates are listed");
		}

		// Refusals leave nothing written.
		let refusal = scope String();
		CallErr(server, "export_preset_set", With(With(Obj(), "name", "Deck"), "platform", "Amiga"), refusal);
		Test.Assert(refusal.Contains("Linux64"));
		CallErr(server, "export_preset_set", With(With(Obj(), "name", "Deck"), "renderWidth", 99999), refusal..Clear());
		Test.Assert(refusal.Contains("16384"));
		CallRefusedArgument(server, "export_preset_set", With(With(Obj(), "name", "Deck"), "renderSize", 99), refusal..Clear());
		Test.Assert(refusal.StartsWith("export_preset_set: no argument 'renderSize' (it takes: name, platform,"), refusal);
		// An export builds its player: there is no template for a preset to name.
		CallRefusedArgument(server, "export_preset_set", With(With(Obj(), "name", "Deck"), "templateId", "sedulous-nosuch-release-0.0.0"), refusal..Clear());
		Test.Assert(refusal.StartsWith("export_preset_set: no argument 'templateId'"), refusal);
		CallErr(server, "export_preset_set", With(With(Obj(), "name", "Deck"), "config", "Shipping"), refusal..Clear());
		Test.Assert(refusal.Contains("Debug, Release, Test"), refusal);
		CallErr(server, "export_preset_set", With(Obj(), "platform", "Linux64"), refusal..Clear());
		Test.Assert(refusal.Contains("name"));
		CallErr(server, "export_preset_set", WithBool(With(Obj(), "name", "Deck"), "remove", true), refusal..Clear());
		Test.Assert(refusal.Contains("no preset"));
		Test.Assert(!FileExists(PathJoin(dir, ExportPresetsFile.cFileName, .. scope .())), "a refusal writes nothing");

		// A new preset: kept beside the synthesized one, its overrides as given.
		{
			var args = With(With(Obj(), "name", "Deck"), "platform", "Linux64");
			args = WithBool(args, "overridesRender", true);
			args = With(With(With(args, "renderWidth", 1280), "renderHeight", 800), "renderFit", "Letterbox");
			args = With(WithBool(args, "overridesWindow", true), "windowMode", "Fullscreen");
			let set = CallOk(server, "export_preset_set", args);
			defer delete set;
			Test.Assert(!set.Get("synthesized").AsBool());
			let presets = set.Get("presets");
			Test.Assert(presets.Count == 2, scope $"{presets.Count} presets");
			let deck = Named(presets, "name", "Deck");
			Test.Assert(deck != null);
			Test.Assert((deck.Get("templateId") == null) && (deck.Get("template") == null), "no template is named or resolved");
			Test.Assert(deck.Get("buildable") != null, "whether it builds here is said");
			Test.Assert(deck.Get("config").AsString() == "", "unset: Release");
			Test.Assert(deck.Get("overridesRender").AsBool() && (deck.Get("renderWidth").AsInt() == 1280) && (deck.Get("renderHeight").AsInt() == 800));
			Test.Assert((deck.Get("renderFit").AsString() == "Letterbox") && (deck.Get("windowMode").AsString() == "Fullscreen"));
			Test.Assert(FileExists(PathJoin(dir, ExportPresetsFile.cFileName, .. scope .())));
		}

		// A change touches only what is given: the render override survives a rename of the
		// output directory, and the file round trips it.
		{
			let set = CallOk(server, "export_preset_set", With(With(Obj(), "name", "Deck"), "outputSubdir", "SteamDeck"));
			delete set;
			let listed = CallOk(server, "export_presets", Obj());
			defer delete listed;
			let deck = Named(listed.Get("presets"), "name", "Deck");
			Test.Assert(deck.Get("outputSubdir").AsString() == "SteamDeck");
			Test.Assert(deck.Get("renderWidth").AsInt() == 1280, "an unmentioned field keeps its value");
		}

		CallErr(server, "export_preset_set", WithBool(With(With(Obj(), "name", "Deck"), "platform", "Win64"), "remove", true), refusal..Clear());
		Test.Assert(refusal.Contains("only"));
		{
			let removed = CallOk(server, "export_preset_set", WithBool(With(Obj(), "name", "Deck"), "remove", true));
			defer delete removed;
			Test.Assert(removed.Get("presets").Count == 1);
			Test.Assert(Named(removed.Get("presets"), "name", "Deck") == null);
		}
	}

	/// Another host's desktop platform: Win64 on Linux, Linux64 on Windows.
	private static StringView OtherHost => (BuildLayout.HostPlatformName == "Win64") ? "Linux64" : "Win64";

	/// Each preset says whether its player builds on this host and, when it does not, why: a
	/// preset for another host's platform and one in the Test config are kept, and say so.
	[Test]
	public static void EachPresetSaysWhetherItsPlayerBuildsHere()
	{
		let dir = Scratch("mcp_export_presets_buildable", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		ExportPresetTools.Register(server, session);
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Buildable"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		delete CallOk(server, "export_preset_set", With(With(Obj(), "name", "Elsewhere"), "platform", OtherHost));
		let listed = CallOk(server, "export_preset_set", With(With(With(Obj(), "name", "Tested"), "platform", BuildLayout.HostPlatformName), "config", "Test"));
		defer delete listed;
		let presets = listed.Get("presets");
		Test.Assert(presets.Count == 3, scope $"{presets.Count} presets");

		let elsewhere = Named(presets, "name", "Elsewhere");
		Test.Assert((elsewhere != null) && !elsewhere.Get("buildable").AsBool(), "another host's platform builds there");
		Test.Assert(elsewhere.Get("why").AsString().Contains(scope $"a {OtherHost} player builds on"), scope String(elsewhere.Get("why").AsString()));

		let tested = Named(presets, "name", "Tested");
		Test.Assert((tested != null) && !tested.Get("buildable").AsBool(), "no player is built in Test");
		Test.Assert(tested.Get("why").AsString().Contains("test runner"), scope String(tested.Get("why").AsString()));

		// The host's own, synthesized and kept beside them, still builds.
		bool hostBuilds = false;
		for (int i < presets.Count)
		{
			let preset = presets.At(i);
			if ((preset.Get("platform").AsString() == BuildLayout.HostPlatformName) && (preset.Get("config").AsString() != "Test"))
				hostBuilds |= preset.Get("buildable").AsBool() && preset.Get("why").IsNull;
		}
		Test.Assert(hostBuilds, "the host's preset builds here");
	}
}
