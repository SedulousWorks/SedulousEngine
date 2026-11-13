using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Registration;
using Sedulous.VFS;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// export_presets and export_preset_set: a project starts with the synthesized host preset,
/// a new preset is written beside it with only what was given changed, a template this
/// machine lacks is kept and reported as unresolved, and a refusal changes nothing.
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

		// No file: the synthesized host preset, and the host template beside it.
		{
			let listed = CallOk(server, "export_presets", Obj());
			defer delete listed;
			Test.Assert(listed.Get("synthesized").AsBool());
			Test.Assert(listed.Get("presets").Count == 1);
			Test.Assert(listed.Get("presets").At(0).Get("platform").AsString() == BuildLayout.HostPlatformName);
			bool host = false;
			let templates = listed.Get("templates");
			for (int i < templates.Count)
				host |= templates.At(i).Get("host").AsBool();
			Test.Assert(host, "the host template is always there");
		}

		// Refusals leave nothing written.
		let refusal = scope String();
		CallErr(server, "export_preset_set", With(With(Obj(), "name", "Deck"), "platform", "Amiga"), refusal);
		Test.Assert(refusal.Contains("Linux64"));
		CallErr(server, "export_preset_set", With(With(Obj(), "name", "Deck"), "renderWidth", 99999), refusal..Clear());
		Test.Assert(refusal.Contains("16384"));
		CallRefusedArgument(server, "export_preset_set", With(With(Obj(), "name", "Deck"), "renderSize", 99), refusal..Clear());
		Test.Assert(refusal.StartsWith("export_preset_set: no argument 'renderSize' (it takes: name, platform,"), refusal);
		CallErr(server, "export_preset_set", With(With(Obj(), "name", "Deck"), "config", "Shipping"), refusal..Clear());
		Test.Assert(refusal.Contains("Debug, Release, Test"), refusal);
		CallErr(server, "export_preset_set", With(Obj(), "platform", "Linux64"), refusal..Clear());
		Test.Assert(refusal.Contains("name"));
		CallErr(server, "export_preset_set", WithBool(With(Obj(), "name", "Deck"), "remove", true), refusal..Clear());
		Test.Assert(refusal.Contains("no preset"));
		Test.Assert(!FileExists(PathJoin(dir, ExportPresetsFile.cFileName, .. scope .())), "a refusal writes nothing");

		// A new preset: kept beside the synthesized one, its overrides as given, and a
		// template this machine does not have kept but reported unresolved.
		{
			var args = With(With(With(Obj(), "name", "Deck"), "platform", "Linux64"), "templateId", "sedulous-nosuch-release-0.0.0");
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
			Test.Assert(deck.Get("templateId").AsString() == "sedulous-nosuch-release-0.0.0");
			Test.Assert(deck.Get("template").IsNull, "a template this machine lacks does not resolve");
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

	/// A preset's quality level: one of the project's levels, or refused (the export would ship
	/// a level the game's options menu does not know); "" is the project's default.
	[Test]
	public static void APresetsQualityLevelIsOneOfTheProjects()
	{
		let dir = Scratch("mcp_export_preset_quality", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		let creators = scope AssetCreatorRegistry();
		PipelineRegistration.RegisterAllBuilders(builders, FindDataRoot(.. scope .()));
		PipelineRegistration.RegisterAllCreators(creators);
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		ProjectInfoTool.Register(server, session);
		ExportPresetTools.Register(server, session);
		let operations = scope InlineProjectOperations(session, builders, "", "");
		AssetCreateTools.Register(server, session, creators, operations);
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Levels"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		let lowMade = CallOk(server, "asset_create", With(With(Obj(), "creator", "Render Quality"), "name", "Low"));
		defer delete lowMade;
		let highMade = CallOk(server, "asset_create", With(With(Obj(), "creator", "Render Quality"), "name", "High"));
		defer delete highMade;
		let low = scope String(lowMade.Get("guid").AsString());
		let high = scope String(highMade.Get("guid").AsString());
		{
			let listed = JsonValue.MakeArray();
			listed.Add(JsonValue.MakeString(low));
			let arguments = Obj();
			arguments.Set("qualityLevelIds", listed);
			delete CallOk(server, "project_settings_set", arguments);
		}

		let refusal = scope String();
		CallErr(server, "export_preset_set", With(With(Obj(), "name", "Deck"), "qualityLevelId", high), refusal);
		Test.Assert(refusal.StartsWith("preset 'Deck' starts at a quality level the project does not list"), refusal);
		Test.Assert(!FileExists(PathJoin(dir, ExportPresetsFile.cFileName, .. scope .())), "a refusal writes nothing");

		let set = CallOk(server, "export_preset_set", With(With(Obj(), "name", "Deck"), "qualityLevelId", low));
		defer delete set;
		let deck = Named(set.Get("presets"), "name", "Deck");
		Test.Assert(deck != null);
		Test.Assert(deck.Get("qualityLevelId").Get("guid").AsString() == low);
		Test.Assert(deck.Get("qualityLevelId").Get("path").AsString() == "Quality/Low");

		// "" is the project's default again.
		let cleared = CallOk(server, "export_preset_set", With(With(Obj(), "name", "Deck"), "qualityLevelId", ""));
		defer delete cleared;
		Test.Assert(Named(cleared.Get("presets"), "name", "Deck").Get("qualityLevelId").IsNull);
	}
}
