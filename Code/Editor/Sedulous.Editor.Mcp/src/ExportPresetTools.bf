using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.VFS;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Mcp;

/// export_presets and export_preset_set: the project's export targets (export_presets.xml),
/// what the editor's Export Presets dialog edits, and the templates this machine can export
/// them with. project_export runs one.
static class ExportPresetTools
{
	private static StringView[3] cConfigs = .("Debug", "Release", "Test");
	/// The wire names of FitMode and WindowMode, in their declaration order.
	private static StringView[4] cFitNames = .("stretch", "letterbox", "crop", "integerScale");
	private static StringView[3] cWindowModeNames = .("windowed", "fullscreen", "borderless");

	public static void Register(McpServer server, ProjectSession session)
	{
		server.RegisterTool("export_presets",
			"The open project's export presets and the export templates this machine has. Each preset: name, platform, templateId (\"\" resolves by platform and config), config, playerName, outputSubdir, additionalFiles, stageSymbols, pruneToReachable, its display overrides (`render` and `window`, each null unless the preset overrides the project's), and `template`: the id it resolves to here, or null when this machine has no template for it. A project without export_presets.xml has one synthesized preset for the host (`synthesized`: true). Each template: id, name, platform, config, engineVersion, host (the player beside this tool, not an installed bundle). export_preset_set changes them; project_export runs one.",
			scope SchemaBuilder().Build(), .ReadOnly,
			new (arguments, outResult, outError) => List(session, outResult, outError));

		let schema = scope SchemaBuilder();
		schema.Str("name", "the preset to create or change, by name (required)");
		schema.Boolean("remove", "delete the preset instead; nothing else may be given");
		schema.Str("platform", "the build platform: Linux64, Win64 or Web");
		schema.Str("templateId", "the template to export with, an id export_presets lists; \"\" resolves by platform and config");
		schema.Enum("config", scope StringView[]("Debug", "Release", "Test"), "the build config the template must be; default Release");
		schema.Str("playerName", "the shipped executable's name; \"\" keeps the template's");
		schema.Str("outputSubdir", "the directory under the export root; \"\" is the preset's name");
		schema.Arr("additionalFiles", "string", "project-relative files shipped beside the player, the whole list; [] for none");
		schema.Boolean("stageSymbols", "ship the template's symbol files too");
		schema.Boolean("pruneToReachable", "ship only what the entry points reach, not every asset");
		schema.Boolean("overridesRender", "draw at this preset's resolution rather than the project's");
		schema.Integer("renderWidth", "the width this platform draws at; 0 with renderHeight 0 for the output's own size");
		schema.Integer("renderHeight", "the height this platform draws at");
		schema.Enum("renderFit", scope StringView[]("stretch", "letterbox", "crop", "integerScale"), "how the render resolution fits a screen of another shape");
		schema.Boolean("overridesWindow", "open this preset's window rather than the project's");
		schema.Integer("windowWidth", "this platform's window width");
		schema.Integer("windowHeight", "this platform's window height");
		schema.Enum("windowMode", scope StringView[]("windowed", "fullscreen", "borderless"), "how this platform's window takes the screen");
		schema.Boolean("windowResizable", "whether this platform's window may be resized");
		server.RegisterTool("export_preset_set",
			"Create, change or remove one export preset of the open project, by name: only what is given changes, and a new preset starts as the host's platform, Release. Checked in full before anything changes, then saved to export_presets.xml (a project with none starts from its synthesized host preset, which stays). A templateId need not exist on this machine - presets travel with the project and templates do not - so the result's `template` says whether it resolves here. Returns the presets as export_presets does.",
			schema.Build(), .Overwrites,
			new (arguments, outResult, outError) => Set(session, arguments, outResult, outError));
	}

	/// The presets on disk, else the synthesized default. True when they came from the file.
	private static bool LoadPresets(EditorProject project, ExportPresetSet outPresets)
	{
		let projectFs = scope NativeFileSystem(project.Directory);
		if (ExportPresetsFile.Load(projectFs, outPresets) case .Ok)
			return true;
		ExportPresetsFile.Defaults(outPresets);
		return false;
	}

	/// The templates an export from this host would see: the shared root, then the player
	/// beside this tool, as the inline export builds them.
	private static void RefreshTemplates(TemplateRegistry registry)
	{
		registry.Refresh(ExportTemplates.ResolveRoot("", .. scope .()),
			BuildLayout.PlayerDirectoryBeside(GetExecutableDirectory(.. scope .()), .. scope .()));
	}

	private static bool List(ProjectSession session, JsonValue outResult, String outError)
	{
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let presets = scope ExportPresetSet();
		let fromFile = LoadPresets(session.Project, presets);
		let templates = scope TemplateRegistry();
		RefreshTemplates(templates);
		Describe(presets, fromFile, templates, outResult);
		return true;
	}

	private static void Describe(ExportPresetSet presets, bool fromFile, TemplateRegistry templates, JsonValue outResult)
	{
		let list = JsonValue.MakeArray();
		for (let preset in presets.Presets)
		{
			let json = JsonValue.MakeObject();
			json.Set("name", JsonValue.MakeString(preset.Name));
			json.Set("platform", JsonValue.MakeString(preset.Platform));
			json.Set("templateId", JsonValue.MakeString(preset.TemplateId));
			json.Set("config", JsonValue.MakeString(preset.EffectiveConfig));
			json.Set("playerName", JsonValue.MakeString(preset.PlayerName));
			json.Set("outputSubdir", JsonValue.MakeString(preset.OutputSubdir));
			let files = JsonValue.MakeArray();
			for (let file in preset.AdditionalFiles)
				files.Add(JsonValue.MakeString(file));
			json.Set("additionalFiles", files);
			json.Set("stageSymbols", JsonValue.MakeBool(preset.StageSymbols));
			json.Set("pruneToReachable", JsonValue.MakeBool(preset.PruneToReachable));
			if (preset.OverridesRender)
			{
				let render = JsonValue.MakeObject();
				render.Set("width", JsonValue.MakeNumber(preset.RenderWidth));
				render.Set("height", JsonValue.MakeNumber(preset.RenderHeight));
				render.Set("fit", JsonValue.MakeString(cFitNames[(int)preset.RenderFit]));
				json.Set("render", render);
			}
			else
			{
				json.Set("render", JsonValue.MakeNull());
			}
			if (preset.OverridesWindow)
			{
				let window = JsonValue.MakeObject();
				window.Set("width", JsonValue.MakeNumber(preset.WindowWidth));
				window.Set("height", JsonValue.MakeNumber(preset.WindowHeight));
				window.Set("mode", JsonValue.MakeString(cWindowModeNames[(int)preset.WindowMode]));
				window.Set("resizable", JsonValue.MakeBool(preset.WindowResizable));
				json.Set("window", window);
			}
			else
			{
				json.Set("window", JsonValue.MakeNull());
			}
			let resolved = templates.Resolve(preset);
			json.Set("template", (resolved != null) ? JsonValue.MakeString(resolved.Id) : JsonValue.MakeNull());
			list.Add(json);
		}
		outResult.Set("presets", list);
		outResult.Set("synthesized", JsonValue.MakeBool(!fromFile));

		let templateList = JsonValue.MakeArray();
		for (int i < templates.Count)
		{
			let template = templates.At(i);
			let json = JsonValue.MakeObject();
			json.Set("id", JsonValue.MakeString(template.Id));
			json.Set("name", JsonValue.MakeString(template.Name));
			json.Set("platform", JsonValue.MakeString(template.Platform));
			json.Set("config", JsonValue.MakeString(template.EffectiveConfig));
			json.Set("engineVersion", JsonValue.MakeString(template.EngineVersion));
			json.Set("host", JsonValue.MakeBool(template.IsHost));
			templateList.Add(json);
		}
		outResult.Set("templates", templateList);
	}

	private static bool Set(ProjectSession session, JsonValue arguments, JsonValue outResult, String outError)
	{
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let project = session.Project;
		let name = McpTools.ArgString(arguments, "name", .. scope .());
		if (name.IsEmpty)
		{
			outError.Append("`name` names the preset to create, change or remove");
			return false;
		}
		let presets = scope ExportPresetSet();
		LoadPresets(project, presets);
		let existing = presets.Find(name);

		if (let remove = arguments.Get("remove"))
		{
			if (remove.AsBool())
			{
				if (arguments.Count > 2)
				{
					outError.Append("`remove` takes only `name`");
					return false;
				}
				if (existing == null)
				{
					outError.AppendF("no preset named '{}'", name);
					return false;
				}
				presets.Presets.Remove(existing);
				delete existing;
				return Save(project, presets, outResult, outError);
			}
		}

		// Everything is checked before anything changes: a refusal leaves the file as it was.
		if (let arg = arguments.Get("platform"))
		{
			let platform = arg.AsString();
			if ((platform != "Linux64") && (platform != "Win64") && (platform != "Web"))
			{
				outError.Append("`platform` takes Linux64, Win64 or Web");
				return false;
			}
		}
		if (let arg = arguments.Get("config"))
		{
			if (IndexOfName(cConfigs, arg.AsString()) < 0)
			{
				outError.Append("`config` takes Debug, Release or Test");
				return false;
			}
		}
		let filesArg = arguments.Get("additionalFiles");
		if ((filesArg != null) && !filesArg.IsArray)
		{
			outError.Append("`additionalFiles` takes an array of project-relative paths");
			return false;
		}
		for (let key in StringView[4]("renderWidth", "renderHeight", "windowWidth", "windowHeight"))
		{
			if (let arg = arguments.Get(key))
			{
				let value = arg.AsInt(-1);
				let least = key.StartsWith("render") ? 0 : 1;
				if ((value < least) || (value > 16384))
				{
					outError.AppendF("`{}` takes {} to 16384", key, least);
					return false;
				}
			}
		}
		int fitIndex = -1;
		if (let arg = arguments.Get("renderFit"))
		{
			fitIndex = IndexOfName(cFitNames, arg.AsString());
			if (fitIndex < 0)
			{
				outError.Append("`renderFit` takes stretch, letterbox, crop or integerScale");
				return false;
			}
		}
		int modeIndex = -1;
		if (let arg = arguments.Get("windowMode"))
		{
			modeIndex = IndexOfName(cWindowModeNames, arg.AsString());
			if (modeIndex < 0)
			{
				outError.Append("`windowMode` takes windowed, fullscreen or borderless");
				return false;
			}
		}

		var preset = existing;
		if (preset == null)
		{
			preset = new ExportPreset();
			preset.Name.Set(name);
			preset.Platform.Set(BuildLayout.HostPlatformName);
			presets.Presets.Add(preset);
		}
		if (let arg = arguments.Get("platform"))
			preset.Platform.Set(arg.AsString());
		if (let arg = arguments.Get("templateId"))
			preset.TemplateId.Set(arg.AsString());
		if (let arg = arguments.Get("config"))
			preset.Config.Set(arg.AsString());
		if (let arg = arguments.Get("playerName"))
			preset.PlayerName.Set(arg.AsString());
		if (let arg = arguments.Get("outputSubdir"))
			preset.OutputSubdir.Set(arg.AsString());
		if (filesArg != null)
		{
			ClearAndDeleteItems(preset.AdditionalFiles);
			for (int i < filesArg.Count)
				preset.AdditionalFiles.Add(new String(filesArg.At(i).AsString()));
		}
		if (let arg = arguments.Get("stageSymbols"))
			preset.StageSymbols = arg.AsBool();
		if (let arg = arguments.Get("pruneToReachable"))
			preset.PruneToReachable = arg.AsBool();
		if (let arg = arguments.Get("overridesRender"))
			preset.OverridesRender = arg.AsBool();
		if (let arg = arguments.Get("renderWidth"))
			preset.RenderWidth = (uint32)arg.AsInt();
		if (let arg = arguments.Get("renderHeight"))
			preset.RenderHeight = (uint32)arg.AsInt();
		if (fitIndex >= 0)
			preset.RenderFit = (FitMode)fitIndex;
		if (let arg = arguments.Get("overridesWindow"))
			preset.OverridesWindow = arg.AsBool();
		if (let arg = arguments.Get("windowWidth"))
			preset.WindowWidth = (uint32)arg.AsInt();
		if (let arg = arguments.Get("windowHeight"))
			preset.WindowHeight = (uint32)arg.AsInt();
		if (modeIndex >= 0)
			preset.WindowMode = (WindowMode)modeIndex;
		if (let arg = arguments.Get("windowResizable"))
			preset.WindowResizable = arg.AsBool();
		return Save(project, presets, outResult, outError);
	}

	private static bool Save(EditorProject project, ExportPresetSet presets, JsonValue outResult, String outError)
	{
		let projectFs = scope NativeFileSystem(project.Directory);
		if (ExportPresetsFile.Save(projectFs, presets) case .Err)
		{
			outError.AppendF("{} did not save", ExportPresetsFile.cFileName);
			return false;
		}
		let templates = scope TemplateRegistry();
		RefreshTemplates(templates);
		Describe(presets, true, templates, outResult);
		return true;
	}

	private static int IndexOfName(Span<StringView> names, StringView name)
	{
		for (int i < names.Length)
		{
			if (names[i] == name)
				return i;
		}
		return -1;
	}
}
