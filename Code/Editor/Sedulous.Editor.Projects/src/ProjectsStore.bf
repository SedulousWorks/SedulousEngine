using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;
using Sedulous.Editor.Projects;
using internal Sedulous.Editor.Project;

namespace Sedulous.Editor.Project;

/// The user's recent projects and the list's layout in a file of their own,
/// <user-data>/Sedulous/projects.xml: a settings store holding RecentProjectsSettings, which the
/// project manager and the editors of any version share. The list lived in the editor's store,
/// editor.settings.xml, before; the first load with no projects.xml takes it from there, once,
/// and writes projects.xml, so a later load never looks there again.
class ProjectsStore
{
	public const String cFileName = "projects.xml";
	/// The editor's own store under the user data folder, where the list was kept before.
	public const String cEditorSettingsFileName = "editor.settings.xml";

	private String mPath = new .() ~ delete _;
	private String mEditorSettingsPath = new .() ~ delete _;
	private bool mMigrated = false;

	/// The list kept in `path`, taken once from the editor's store at `editorSettingsPath` (empty:
	/// none) while `path` is not there. DefaultPath and DefaultEditorSettingsPath are the user's.
	public this(StringView path, StringView editorSettingsPath)
	{
		mPath.Set(path);
		mEditorSettingsPath.Set(editorSettingsPath);
	}

	public StringView Path => mPath;

	/// The last Load took the list from the editor's store (and wrote projects.xml).
	public bool Migrated => mMigrated;

	/// <user-data>/Sedulous/projects.xml.
	public static void DefaultPath(String outPath)
	{
		PathJoin(GetUserDataDirectory(.. scope .()), cFileName, outPath);
	}

	/// <user-data>/Sedulous/editor.settings.xml.
	public static void DefaultEditorSettingsPath(String outPath)
	{
		PathJoin(GetUserDataDirectory(.. scope .()), cEditorSettingsFileName, outPath);
	}

	/// The names the list's two types were saved under before they moved: from Editor.Core to the
	/// headless project half, then on to this library. A rename is one step, so each former name
	/// leads to where they are now. Registered once at startup, before a store loads: the editor
	/// through EditorSerializables, the manager itself.
	public static void RegisterFormerNames()
	{
		for (let name in StringView[?]("RecentProjectsSettings", "RecentProjectEntry"))
		{
			SerializableRenames.Register(scope $"Sedulous.Editor.Core.{name}", scope $"Sedulous.Editor.Projects.{name}");
			SerializableRenames.Register(scope $"Sedulous.Editor.Project.{name}", scope $"Sedulous.Editor.Projects.{name}");
		}
	}

	/// The file read into `outStore`. With no file yet, the list is taken from the editor's store
	/// when that has one (Migrated then says so), and projects.xml is written either way, so this
	/// happens once. A file that does not read is refused, not replaced.
	public Result<void, ErrorCode> Load(Settings outStore)
	{
		RegisterFormerNames(); // the editor's store may hold the list under a former name
		mMigrated = false;
		if (FileExists(mPath))
			return Read(mPath, outStore);
		if (!mEditorSettingsPath.IsEmpty && FileExists(mEditorSettingsPath))
		{
			let editor = scope Settings();
			if (Read(mEditorSettingsPath, editor) case .Ok)
			{
				if (let recent = editor.Find<RecentProjectsSettings>())
				{
					outStore.Section<RecentProjectsSettings>().CopyFrom(recent);
					mMigrated = true;
				}
			}
			else
				GlobalLog(.Warning, "Projects: {} did not read; the recent projects start empty", mEditorSettingsPath);
		}
		return Save(outStore);
	}

	/// The store written whole, through a temporary file moved over the old one.
	public Result<void, ErrorCode> Save(Settings store)
	{
		let buffer = scope MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		if (store.Save(buffer, factory) case .Err(let error))
			return .Err(error);
		if (!ProjectBuild.MakeDirectories(PathParent(mPath, .. scope .())))
			return .Err(.Internal);
		return WriteFileAtomic(mPath, buffer.Bytes);
	}

	/// A store file read against this library's own types: a section of any other passes through.
	private static Result<void, ErrorCode> Read(StringView path, Settings outStore)
	{
		let stream = scope FileStream(path, .Read);
		if (!stream.IsValid)
			return .Err(.NotFound);
		let factory = XmlSerializerFactory();
		defer delete factory;
		let types = scope SerializableRegistry();
		EditorProjectsSerializables.RegisterAll(types);
		return outStore.Load(stream, factory, types);
	}
}
