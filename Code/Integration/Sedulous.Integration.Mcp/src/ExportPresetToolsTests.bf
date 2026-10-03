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
		CallErr(server, "export_preset_set", With(With(Obj(), "name", "Deck"), "renderSize", 99), refusal..Clear());
		Test.Assert(refusal.StartsWith("no preset field 'renderSize'; the fields are: name, platform,"), refusal);
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
}
