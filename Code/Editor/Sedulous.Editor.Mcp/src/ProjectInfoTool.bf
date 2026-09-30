using System;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Mcp;

/// project_info and project_settings_set: the open project's identity and its settings, the
/// ones the editor's Project Settings dialog edits, part of the surface every host serves.
static class ProjectInfoTool
{
	/// One asset setting: its argument name, the asset type it must be (the dialog's picker
	/// filter), and where it lives in the settings.
	private struct AssetSetting
	{
		public StringView Key;
		public StringView Type;
		public Guid* Id;

		public this(StringView key, StringView type, Guid* id)
		{
			Key = key;
			Type = type;
			Id = id;
		}
	}

	private static void AssetSettings(ProjectSettings settings, out AssetSetting[7] outSettings)
	{
		outSettings = .(
			.("defaultScene", "SceneDocument", &settings.DefaultSceneId),
			.("startupScript", "ScriptClassAsset", &settings.StartupScriptId),
			.("defaultInputMap", "InputMapAsset", &settings.DefaultInputMapId),
			.("defaultBusLayout", "AudioBusLayoutAsset", &settings.DefaultBusLayoutId),
			.("defaultUiTheme", "UIThemeAsset", &settings.DefaultUiThemeId),
			.("loadingScreen", "UIDocumentAsset", &settings.LoadingDocumentId),
			.("defaultUiFont", "FontAsset", &settings.DefaultUiFontId));
	}

	public static void Register(McpServer server, ProjectSession session)
	{
		server.RegisterTool("project_info",
			"Details about the currently open project: name, directory, sources root, and its settings - the default scene, startup script, default input map, bus layout, UI theme, loading screen and UI font (each {guid, path}, or null when unset), the native module and the MSAA samples. project_settings_set changes them.",
			scope SchemaBuilder().Build(), .ReadOnly,
			new (arguments, outResult, outError) => Info(session, outResult, outError));

		let setSchema = scope SchemaBuilder();
		setSchema.Str("name", "the project's display name");
		setSchema.Str("defaultScene", "a SceneDocument's guid, the scene play starts in; \"\" clears");
		setSchema.Str("startupScript", "a ScriptClassAsset's guid, the game-tier script play launches; \"\" clears");
		setSchema.Str("defaultInputMap", "an InputMapAsset's guid, the map play binds; \"\" clears");
		setSchema.Str("defaultBusLayout", "an AudioBusLayoutAsset's guid; \"\" is the built-in");
		setSchema.Str("defaultUiTheme", "a UIThemeAsset's guid; \"\" is the built-in");
		setSchema.Str("loadingScreen", "a UIDocumentAsset's guid; \"\" is the built-in");
		setSchema.Str("defaultUiFont", "a FontAsset's guid; \"\" is the built-in");
		setSchema.Str("nativeModule", "a project-relative path to the built native game module; \"\" clears");
		setSchema.Integer("msaa", "scene-pass samples: 1 (off), 2 or 4");
		server.RegisterTool("project_settings_set",
			"Change the open project's settings, what the editor's Project Settings dialog edits: only what is given changes. Every asset setting must name an asset of its type (the refusal says which), \"\" clears it. Checked in full before anything changes, then saved to the manifest; the editor re-applies what depends on them (the game UI's font and theme). Returns the settings as project_info does.",
			setSchema.Build(), .Adjusts,
			new (arguments, outResult, outError) => Set(session, arguments, outResult, outError));
	}

	private static bool Info(ProjectSession session, JsonValue outResult, String outError)
	{
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let project = session.Project;
		outResult.Set("name", JsonValue.MakeString(project.Name));
		outResult.Set("directory", JsonValue.MakeString(project.Directory));
		outResult.Set("sourcesRoot", JsonValue.MakeString(project.SourcesRoot(.. scope .())));
		let settings = project.Settings;
		AssetSettings(settings, let assets);
		let json = JsonValue.MakeObject();
		for (let setting in assets)
		{
			let id = *setting.Id;
			let instance = id.IsSet ? project.SourceDb.GetInstance(id) : null;
			if (!id.IsSet)
			{
				json.Set(setting.Key, JsonValue.MakeNull());
				continue;
			}
			let entry = JsonValue.MakeObject();
			entry.Set("guid", McpTools.GuidToJson(id));
			entry.Set("path", (instance != null) ? JsonValue.MakeString(instance.GetPath(.. scope .())) : JsonValue.MakeNull());
			json.Set(setting.Key, entry);
		}
		json.Set("nativeModule", JsonValue.MakeString(settings.NativeModule));
		json.Set("msaa", JsonValue.MakeNumber(settings.RenderMsaaSamples));
		outResult.Set("settings", json);
		return true;
	}

	private static bool Set(ProjectSession session, JsonValue arguments, JsonValue outResult, String outError)
	{
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let project = session.Project;
		let settings = project.Settings;
		AssetSettings(settings, let assets);

		// Everything is checked before anything changes: a refusal leaves the settings as
		// they were.
		Guid[7] chosen = default;
		bool[7] given = default;
		for (int i < assets.Count)
		{
			let arg = arguments.Get(assets[i].Key);
			if (arg == null)
				continue;
			given[i] = true;
			let text = arg.AsString();
			if (text.IsEmpty)
				continue; // clears
			if (!McpTools.ParseGuid(text, outError, let id))
				return false;
			let instance = project.SourceDb.GetInstance(id);
			if (instance == null)
			{
				outError.AppendF("`{}`: no asset with guid {} in the project", assets[i].Key, id);
				return false;
			}
			if (!IsType(instance, assets[i].Type))
			{
				outError.AppendF("`{}` takes a {}; '{}' is a {}", assets[i].Key, assets[i].Type, instance.Name, instance.TypeName);
				return false;
			}
			chosen[i] = id;
		}
		let msaaArg = arguments.Get("msaa");
		if (msaaArg != null)
		{
			let samples = msaaArg.AsInt();
			if ((samples != 1) && (samples != 2) && (samples != 4))
			{
				outError.Append("`msaa` takes 1, 2 or 4");
				return false;
			}
		}

		for (int i < assets.Count)
		{
			if (given[i])
				*assets[i].Id = chosen[i];
		}
		// The path mirrors the dialog keeps beside the guids.
		if (given[0])
			MirrorPath(project.SourceDb, settings.DefaultSceneId, settings.DefaultScene);
		if (given[1])
			MirrorPath(project.SourceDb, settings.StartupScriptId, settings.StartupScript);
		if (let name = arguments.Get("name"))
			settings.Name.Set(name.AsString());
		if (let module = arguments.Get("nativeModule"))
			settings.NativeModule.Set(module.AsString());
		if (msaaArg != null)
			settings.RenderMsaaSamples = (uint32)msaaArg.AsInt();
		if (project.SaveSettings() case .Err)
		{
			outError.Append("the settings changed but the manifest did not save (log_read says why)");
			return false;
		}
		if (session.OnSettingsChanged != null)
			session.OnSettingsChanged();
		return Info(session, outResult, outError);
	}

	private static void MirrorPath(ContentDatabase db, Guid id, String outPath)
	{
		outPath.Clear();
		if (let instance = id.IsSet ? db.GetInstance(id) : null)
			instance.GetPath(outPath);
	}

	/// The stored type name against the picker's short name ("SceneDocument").
	private static bool IsType(Instance instance, StringView shortName)
	{
		let typeName = instance.TypeName;
		return (typeName == shortName) || (typeName.EndsWith(shortName) && (typeName.Length > shortName.Length) && (typeName[typeName.Length - shortName.Length - 1] == '.'));
	}
}
