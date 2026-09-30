using System;
using System.Collections;
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
			"Details about the currently open project: name, directory, sources root, and its settings - the default scene, startup script, default input map, bus layout, UI theme, loading screen and UI font (each {guid, path}, or null when unset), the other UI fonts (`uiFonts`, a list of {guid, path}), the display (`render`: {width, height, fit}, the resolution the game draws at, 0 for its output's size; `window`: {width, height, mode, resizable}, the player's window), the native module and the MSAA samples. project_settings_set changes them.",
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
		setSchema.Arr("uiFonts", "string", "FontAsset guids the game UI loads beside the default, each its own family a label picks with font-family (a title face); the whole list, [] for none. They need defaultUiFont set");
		setSchema.Str("nativeModule", "a project-relative path to the built native game module; \"\" clears");
		setSchema.Integer("msaa", "scene-pass samples: 1 (off), 2 or 4");
		setSchema.Integer("renderWidth", "the width the game draws at, fitted into whatever shows it; 0 (with renderHeight 0) draws at the output's own size");
		setSchema.Integer("renderHeight", "the height the game draws at; 0 for the output's own size");
		setSchema.Enum("renderFit", scope StringView[]("stretch", "letterbox", "crop", "integerScale"), "how a fixed render resolution fits an output of another shape");
		setSchema.Integer("windowWidth", "the player window's width");
		setSchema.Integer("windowHeight", "the player window's height");
		setSchema.Enum("windowMode", scope StringView[]("windowed", "fullscreen", "borderless"), "how the player's window takes the screen (borderless takes the display's size)");
		setSchema.Boolean("windowResizable", "whether the player's window may be resized");
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
		let fonts = JsonValue.MakeArray();
		for (let id in settings.UiFontIds)
		{
			let instance = project.SourceDb.GetInstance(id);
			let entry = JsonValue.MakeObject();
			entry.Set("guid", McpTools.GuidToJson(id));
			entry.Set("path", (instance != null) ? JsonValue.MakeString(instance.GetPath(.. scope .())) : JsonValue.MakeNull());
			fonts.Add(entry);
		}
		json.Set("uiFonts", fonts);
		let render = JsonValue.MakeObject();
		render.Set("width", JsonValue.MakeNumber(settings.RenderWidth));
		render.Set("height", JsonValue.MakeNumber(settings.RenderHeight));
		render.Set("fit", JsonValue.MakeString(cFitNames[(int)settings.RenderFit]));
		json.Set("render", render);
		let window = JsonValue.MakeObject();
		window.Set("width", JsonValue.MakeNumber(settings.WindowWidth));
		window.Set("height", JsonValue.MakeNumber(settings.WindowHeight));
		window.Set("mode", JsonValue.MakeString(cWindowModeNames[(int)settings.WindowMode]));
		window.Set("resizable", JsonValue.MakeBool(settings.WindowResizable));
		json.Set("window", window);
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
				outError.AppendF("`{}` takes an asset of type {}; '{}' is of type {}", assets[i].Key, assets[i].Type, instance.Name, instance.TypeName);
				return false;
			}
			chosen[i] = id;
		}
		let fontIds = scope List<Guid>();
		let fontsArg = arguments.Get("uiFonts");
		if (fontsArg != null)
		{
			if (!fontsArg.IsArray)
			{
				outError.Append("`uiFonts` takes an array of FontAsset guids");
				return false;
			}
			for (int i < fontsArg.Count)
			{
				if (!McpTools.ParseGuid(fontsArg.At(i).AsString(), outError, let id))
					return false;
				let instance = project.SourceDb.GetInstance(id);
				if (instance == null)
				{
					outError.AppendF("`uiFonts`[{}]: no asset with guid {} in the project", i, id);
					return false;
				}
				if (!IsType(instance, "FontAsset"))
				{
					outError.AppendF("`uiFonts`[{}] takes a FontAsset; '{}' is of type {}", i, instance.Name, instance.TypeName);
					return false;
				}
				if (!fontIds.Contains(id))
					fontIds.Add(id);
			}
		}
		// The display: sizes within reason, the enums by name.
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
		if (let arg = arguments.Get("renderWidth"))
			settings.RenderWidth = (uint32)arg.AsInt();
		if (let arg = arguments.Get("renderHeight"))
			settings.RenderHeight = (uint32)arg.AsInt();
		if (fitIndex >= 0)
			settings.RenderFit = (FitMode)fitIndex;
		if (let arg = arguments.Get("windowWidth"))
			settings.WindowWidth = (uint32)arg.AsInt();
		if (let arg = arguments.Get("windowHeight"))
			settings.WindowHeight = (uint32)arg.AsInt();
		if (modeIndex >= 0)
			settings.WindowMode = (WindowMode)modeIndex;
		if (let arg = arguments.Get("windowResizable"))
			settings.WindowResizable = arg.AsBool();
		if (fontsArg != null)
		{
			settings.UiFontIds.Clear();
			settings.UiFontIds.AddRange(fontIds);
		}
		if (project.SaveSettings() case .Err)
		{
			outError.Append("the settings changed but the manifest did not save (log_read says why)");
			return false;
		}
		if (session.OnSettingsChanged != null)
			session.OnSettingsChanged();
		return Info(session, outResult, outError);
	}

	/// The wire names of FitMode and WindowMode, in their declaration order.
	private static StringView[4] cFitNames = .("stretch", "letterbox", "crop", "integerScale");
	private static StringView[3] cWindowModeNames = .("windowed", "fullscreen", "borderless");

	private static int IndexOfName(Span<StringView> names, StringView name)
	{
		for (int i < names.Length)
		{
			if (names[i] == name)
				return i;
		}
		return -1;
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
