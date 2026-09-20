using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Core;

/// An opened project: the manifest, and the source and cooked content databases mounted
/// over its fixed layout.
///
/// The layout is the engine's (ProjectLayout), so the player and the editor cannot
/// disagree about where anything lives; what is here is the editor's and the tools' way
/// in: the manifest read, the generated directories recreated, the two databases scanned.
/// The cooker, the exporter and the headless MCP host open a project through this without
/// an editor around it.
///
/// The project's explicit "Always Export" set is a separate committed sidecar,
/// export_roots.xml, loaded on Open: absent is the empty set, the common case, and a present
/// but unreadable file leaves the set empty rather than blocking the open, so an export then
/// over includes, which is safe, never mis-prunes.
class EditorProject
{
	private String mDirectory = new .() ~ delete _;
	private ProjectSettings mSettings ~ delete _;
	private ExportRootsSet mExportRoots = new .() ~ delete _;
	private NativeFileSystem mContentMount ~ delete _;
	private NativeFileSystem mCookedMount ~ delete _;
	private SerializerFactory mSourceFactory ~ delete _;
	private SerializerFactory mCookedFactory ~ delete _;
	private ContentDatabase mSourceDb ~ delete _;
	private ContentDatabase mCookedDb ~ delete _;

	private static String[5] sDirectories = .(ProjectLayout.ContentDir, ProjectLayout.SourcesDir,
		ProjectLayout.CookedDir, ProjectLayout.EditorDir, ProjectLayout.CacheDir);

	/// Scaffolds a new project at `directory`, created when absent, its PARENT existing:
	/// the manifest and the fixed subdirectories. AlreadyExists when a manifest is there.
	public static Result<void, ErrorCode> Create(StringView directory, StringView name)
	{
		if (!DirectoryExists(directory) && !CreateDirectory(directory))
			return .Err(.NotFound);
		let root = scope NativeFileSystem(directory);
		if (root.Exists(ProjectLayout.ManifestFile))
			return .Err(.AlreadyExists);
		if (!EnsureDirectories(directory))
			return .Err(.Internal);
		let settings = scope ProjectSettings();
		settings.Name.Set(name);
		return ProjectManifest.Save(root, settings);
	}

	/// Opens an existing project: reads the manifest, ensures the fixed subdirectories exist
	/// and mounts and scans both databases. Null when there is no readable manifest; a
	/// present but unreadable one is logged, since the caller's shell may only show a
	/// status line.
	public static EditorProject Open(StringView directory)
	{
		let root = scope NativeFileSystem(directory);
		let settings = new ProjectSettings();
		if (ProjectManifest.Load(root, settings) case .Err)
		{
			delete settings;
			if (root.Exists(ProjectLayout.ManifestFile))
				GlobalLog(.Error, scope $"Project: '{directory}/{ProjectLayout.ManifestFile}' exists but failed to parse (an old or corrupt format?); the project was not opened");
			return null;
		}
		// The generated directories may be missing on a fresh checkout, Cooked, Editor and
		// .cache being ignored by version control: recreated so mounts and state saves
		// always have a target.
		if (!EnsureDirectories(directory))
		{
			delete settings;
			return null;
		}
		if (!settings.EngineVersion.IsEmpty && (settings.EngineVersion != EngineVersion.String))
		{
			// Informational today; a launcher routing projects to their engine version and
			// driving a migration is planned.
			GlobalLog(.Warning, scope $"Project: last saved by engine {settings.EngineVersion}, this is {EngineVersion.String}");
		}
		return new EditorProject(directory, settings);
	}

	private static bool EnsureDirectories(StringView directory)
	{
		for (let dir in sDirectories)
		{
			let path = PathJoin(directory, dir, .. scope .());
			if (!DirectoryExists(path) && !CreateDirectory(path))
				return false;
		}
		return true;
	}

	/// Use Create and Open. Takes the settings the manifest read produced.
	private this(StringView directory, ProjectSettings settings)
	{
		mDirectory.Set(directory);
		mSettings = settings;

		mContentMount = new NativeFileSystem(PathJoin(directory, ProjectLayout.ContentDir, .. scope .()));
		mCookedMount = new NativeFileSystem(PathJoin(directory, ProjectLayout.CookedDir, .. scope .()));
		mSourceFactory = XmlSerializerFactory();
		mCookedFactory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		mSourceDb = new ContentDatabase(mContentMount, mSourceFactory, ProjectLayout.SourceAssetExtension);
		mCookedDb = new ContentDatabase(mCookedMount, mCookedFactory, ProjectLayout.CookedAssetExtension);

		let root = scope NativeFileSystem(directory);
		ExportRootsFile.Load(root, mExportRoots).IgnoreError();
	}

	/// The "Always Export" roots; the export driver seeds from these.
	public ExportRootsSet ExportRoots => mExportRoots;

	/// Persists the export roots to <project>/export_roots.xml; the editor calls this after
	/// a right click "Always Export" toggle.
	public Result<void, ErrorCode> SaveExportRoots()
	{
		let root = scope NativeFileSystem(mDirectory);
		return ExportRootsFile.Save(root, mExportRoots);
	}

	public StringView Name => mSettings.Name;
	public StringView Directory => mDirectory;
	public ProjectSettings Settings => mSettings;

	/// The authored source database, XML envelopes: what the editor edits.
	public ContentDatabase SourceDb => mSourceDb;
	/// The cooked output database, binary envelopes: what the runtime loads.
	public ContentDatabase CookedDb => mCookedDb;

	/// Raw import sources, mounted as the build context's sources at cook time.
	public void SourcesRoot(String outPath) => PathJoin(mDirectory, ProjectLayout.SourcesDir, outPath);
	/// Per user editor state: the dock layout, the open pages.
	public void EditorStateRoot(String outPath) => PathJoin(mDirectory, ProjectLayout.EditorDir, outPath);
	/// Thumbnails and cook hashes.
	public void CacheRoot(String outPath) => PathJoin(mDirectory, ProjectLayout.CacheDir, outPath);

	/// Persists the manifest after the editor changed the settings.
	public Result<void, ErrorCode> SaveSettings()
	{
		let root = scope NativeFileSystem(mDirectory);
		return ProjectManifest.Save(root, mSettings);
	}
}
