using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Engine.Project;
using Sedulous.Engine.Render;

namespace Sedulous.Editor.Mcp;

/// project_info and project_settings_set: the open project's identity and its settings, the
/// ones the editor's Project Settings dialog edits, part of the surface every host serves. Both
/// read the settings from ProjectSettings' reflection (its [Setting] fields), the description
/// the dialog builds its rows from, through ReflectedFields. MSAA is the one setting with a rule
/// of its own: a level of the render subsystem's table.
static class ProjectInfoTool
{
	public static void Register(McpServer server, ProjectSession session)
	{
		server.RegisterTool("project_info",
			"Details about the currently open project: name, directory, sources root, and `settings`, keyed by the names project_settings_set takes: each asset setting (defaultSceneId, startupScriptId, defaultInputMapId, defaultBusLayoutId, defaultUiThemeId, loadingDocumentId, defaultUiFontId) as {guid, path} or null when unset, uiFontIds (the other UI fonts) a list of {guid, path}, the display (renderWidth/renderHeight, the resolution the game draws at, 0 for its output's size, and renderFit; the player's windowWidth, windowHeight, windowMode and windowResizable), name, nativeModule and renderMsaaSamples.",
			scope SchemaBuilder().Build(), .ReadOnly,
			new (arguments, outResult, outError) => Info(session, outResult, outError));

		let fields = scope List<FieldInfo>();
		SettingFields.Of(typeof(ProjectSettings), fields);
		let schema = scope SchemaBuilder();
		ReflectedFields.AddToSchema(schema, fields);
		server.RegisterTool("project_settings_set",
			"Change the open project's settings, what the editor's Project Settings dialog edits, by the names project_info reports: only what is given changes, and a name that is no setting is refused with the list. Every asset setting must name an asset of its type (the refusal says which), \"\" clears it; a list setting (uiFontIds, the fonts the game UI loads beside the default, each a family a label picks with font-family) takes the whole list, [] for none; a count takes its range (the display's sizes), a choice one of its values by name (renderFit, windowMode), a flag true or false; renderMsaaSamples takes the render levels (1, 2 or 4). Checked in full before anything changes, then saved to the manifest; the editor re-applies what depends on them (the game UI's font and theme). Returns the settings as project_info does.",
			schema.Build(), .Adjusts,
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
		let fields = scope List<FieldInfo>();
		SettingFields.Of(typeof(ProjectSettings), fields);
		outResult.Set("settings", ReflectedFields.ToJson(project.Settings, fields, project.SourceDb));
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
		let fields = scope List<FieldInfo>();
		SettingFields.Of(typeof(ProjectSettings), fields);

		// Unknown names first: a misspelled setting is refused, not ignored.
		let unknown = scope String();
		if (ReflectedFields.UnknownArgument(arguments, fields, .(), unknown))
		{
			outError.AppendF("no setting '{}'; the settings are: {}", unknown, ReflectedFields.Keys(fields, .. scope .()));
			return false;
		}

		// Everything is checked before anything changes: a refusal leaves the settings as they
		// were. MSAA takes a level of the render subsystem's table besides.
		let changes = scope List<ReflectedFields.Change>();
		defer ClearAndDeleteItems(changes);
		if (!ReflectedFields.Check(arguments, fields, project.SourceDb, changes, outError))
			return false;
		for (let change in changes)
		{
			if (change.Field.Name != "RenderMsaaSamples")
				continue;
			bool level = false;
			let levels = scope String();
			for (let entry in MsaaLevels.All)
			{
				level |= (entry.Samples == change.Number);
				if (!levels.IsEmpty)
					levels.Append(", ");
				levels.AppendF("{}", entry.Samples);
			}
			if (!level)
			{
				outError.AppendF("`renderMsaaSamples` takes {}", levels);
				return false;
			}
		}
		ReflectedFields.Apply(settings, changes);
		// The path mirrors the dialog keeps beside the guids.
		settings.RefreshPathMirrors(scope (id, outPath) =>
			{
				if (let instance = project.SourceDb.GetInstance(id))
					instance.GetPath(outPath);
			});
		if (project.SaveSettings() case .Err)
		{
			outError.Append("the settings changed but the manifest did not save (log_read says why)");
			return false;
		}
		if (session.OnSettingsChanged != null)
			session.OnSettingsChanged();
		return Info(session, outResult, outError);
	}
}
