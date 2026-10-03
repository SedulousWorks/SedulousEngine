using System;
using System.Collections;
using System.Reflection;
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
/// them with. project_export runs one. A preset's fields are ExportPreset's reflection (its
/// [Setting] fields), through ReflectedFields; the tools' own rules are the preset's name (its
/// identity), removal, and a platform the engine targets and a config it builds.
static class ExportPresetTools
{
	private static StringView[3] cPlatforms = .("Linux64", "Win64", "Web");
	private static StringView[3] cConfigs = .("Debug", "Release", "Test");

	public static void Register(McpServer server, ProjectSession session)
	{
		server.RegisterTool("export_presets",
			"The open project's export presets and the export templates this machine has. Each preset: its fields as export_preset_set takes them (name, platform, templateId - \"\" resolves by platform and config - playerName, outputSubdir, additionalFiles, config - \"\" is Release - stageSymbols, pruneToReachable, and the display overrides: overridesRender with renderWidth/renderHeight/renderFit, overridesWindow with windowWidth/windowHeight/windowMode/windowResizable), and `template`: the id it resolves to here, or null when this machine has no template for it. A project without export_presets.xml has one synthesized preset for the host (`synthesized`: true). Each template: id, name, platform, config, engineVersion, notes, host (the player beside this tool, not an installed bundle). export_preset_set changes them; project_export runs one.",
			scope SchemaBuilder().Build(), .ReadOnly,
			new (arguments, outResult, outError) => List(session, outResult, outError));

		let fields = scope List<FieldInfo>();
		SettingFields.Of(typeof(ExportPreset), fields);
		let schema = scope SchemaBuilder();
		ReflectedFields.AddToSchema(schema, fields);
		schema.Boolean("remove", "delete the preset instead; nothing but `name` may be given");
		server.RegisterTool("export_preset_set",
			"Create, change or remove one export preset of the open project, by `name` (required): only what is given changes, a field name that is no preset field is refused with the list, and a new preset starts as the host's platform, Release. `platform` takes Linux64, Win64 or Web and `config` Debug, Release, Test or \"\" (Release); a choice takes one of its values by name (renderFit, windowMode). Checked in full before anything changes, then saved to export_presets.xml (a project with none starts from its synthesized host preset, which stays). A templateId need not exist on this machine - presets travel with the project and templates do not - so the result's `template` says whether it resolves here. Returns the presets as export_presets does.",
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
		let fields = scope List<FieldInfo>();
		SettingFields.Of(typeof(ExportPreset), fields);
		for (let preset in presets.Presets)
		{
			let json = ReflectedFields.ToJson(preset, fields, null);
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
			json.Set("notes", JsonValue.MakeString(template.Notes));
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
		let fields = scope List<FieldInfo>();
		SettingFields.Of(typeof(ExportPreset), fields);
		let unknown = scope String();
		if (ReflectedFields.UnknownArgument(arguments, fields, scope StringView[]("remove"), unknown))
		{
			outError.AppendF("no preset field '{}'; the fields are: {}, remove", unknown, ReflectedFields.Keys(fields, .. scope .()));
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
		let changes = scope List<ReflectedFields.Change>();
		defer ClearAndDeleteItems(changes);
		if (!ReflectedFields.Check(arguments, fields, null, changes, outError))
			return false;
		// The platform the engine targets and a config it builds. A template need not exist
		// here: presets travel with the project and templates do not.
		if (let arg = arguments.Get("platform"))
		{
			if (!Contains(cPlatforms, arg.AsString()))
			{
				outError.Append("`platform` takes Linux64, Win64 or Web");
				return false;
			}
		}
		if (let arg = arguments.Get("config"))
		{
			if (!arg.AsString().IsEmpty && !Contains(cConfigs, arg.AsString()))
			{
				outError.Append("`config` takes Debug, Release, Test or \"\" (Release)");
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
		ReflectedFields.Apply(preset, changes);
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

	private static bool Contains(Span<StringView> names, StringView name)
	{
		for (let entry in names)
		{
			if (entry == name)
				return true;
		}
		return false;
	}
}
