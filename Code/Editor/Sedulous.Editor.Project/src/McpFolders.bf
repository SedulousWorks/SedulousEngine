using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Project;
using Sedulous.Settings;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;

namespace Sedulous.Editor.Project;

/// One answer: whether the user lets MCP tools reach `Folder` for the project at `Project` (both
/// absolute and normalised).
[Serializable(1)]
class McpFolderAnswer
{
	public String Project = new .() ~ delete _;
	public String Folder = new .() ~ delete _;
	public bool Allowed = false;
}

/// The user's answers on the folders outside a project its MCP tools may reach, one per project
/// and folder: a settings section of <user-data>/mcp-folders.xml.
[Serializable(1)]
class McpFolderAnswers
{
	public List<McpFolderAnswer> Answers = new .() ~ DeleteContainerAndItems!(_);

	/// The answer for `folder` of `project`, or null when the user has given none. BORROWED.
	public McpFolderAnswer Find(StringView project, StringView folder)
	{
		for (let answer in Answers)
		{
			if ((answer.Project == project) && (answer.Folder == folder))
				return answer;
		}
		return null;
	}

	/// Records the user's answer for `folder` of `project`, replacing an earlier one.
	public void Record(StringView project, StringView folder, bool allowed)
	{
		if (let answer = Find(project, folder))
		{
			answer.Allowed = allowed;
			return;
		}
		let answer = new McpFolderAnswer();
		answer.Project.Set(project);
		answer.Folder.Set(folder);
		answer.Allowed = allowed;
		Answers.Add(answer);
	}
}

/// A project's listed folders split by the user's answers: those approved, and those not yet
/// answered (a folder the user refused is in neither).
class McpFolderStanding
{
	public List<String> Approved = new .() ~ DeleteContainerAndItems!(_);
	public List<String> Unanswered = new .() ~ DeleteContainerAndItems!(_);
}

/// A project may list folders outside it that its MCP tools work in (ProjectSettings.McpFolders, a
/// game's sources beside it as "../Game"). The list grants nothing by itself: a project is a file
/// anyone can hand the user, and opening it must not widen what an agent may read and write. A
/// host lets its tools reach a listed folder only once the user has approved that folder for that
/// project. The answers, yes or no, are the user's, kept in their data (mcp-folders.xml), never in
/// the project; the editor asks for a folder not yet answered, and a headless host, with no one to
/// ask, applies only the approved ones.
static class McpFolders
{
	/// The file in the user's data folder that holds the answers.
	public const String cFileName = "mcp-folders.xml";

	/// Reads the answers from `root`'s cFileName into `store`; none when the file is not there.
	/// Against a registry of this library's own sections, so a host that registered none (the
	/// headless one) still reads the answers rather than keeping them verbatim.
	public static Result<void, ErrorCode> Load(IFileSystem root, Settings store)
	{
		let stream = root.Open(cFileName, .Read);
		if (stream == null)
			return .Ok;
		defer delete stream;
		let factory = XmlSerializerFactory();
		defer delete factory;
		let registry = scope SerializableRegistry();
		EditorProjectSerializables.RegisterAll(registry);
		return store.Load(stream, factory, registry);
	}

	/// Writes `store` to `root`'s cFileName.
	public static Result<void, ErrorCode> Save(IFileSystem root, Settings store)
	{
		let writable = root as IWritableFileSystem;
		if (writable == null)
			return .Err(.NotSupported);
		let buffer = scope MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		if (store.Save(buffer, factory) case .Err(let error))
			return .Err(error);
		return writable.Save(cFileName, buffer.Bytes);
	}

	/// `directory` made absolute against the working directory and normalised, as the answers
	/// name a project.
	public static void ProjectKey(StringView directory, String outKey)
	{
		if (PathIsAbsolute(directory))
		{
			PathNormalizeLexically(directory, outKey);
			return;
		}
		let joined = PathJoin(GetCurrentDirectory(.. scope .()), directory, .. scope .());
		PathNormalizeLexically(joined, outKey);
	}

	/// A project's listed folders, made absolute against its folder and normalised, as the answers
	/// and the path checks name them, appended. Empty entries are skipped.
	public static void Resolve(StringView projectDirectory, ProjectSettings settings, List<String> outFolders)
	{
		let project = ProjectKey(projectDirectory, .. scope .());
		for (let folder in settings.McpFolders)
		{
			if (folder.IsEmpty)
				continue;
			// An absolute entry stands as it is; a relative one is the project's.
			let joined = PathIsAbsolute(folder) ? scope String(folder) : PathJoin(project, folder, .. scope .());
			outFolders.Add(PathNormalizeLexically(joined, .. new String()));
		}
	}

	/// The project's listed folders split by `answers` into `outStanding`.
	public static void Stand(McpFolderAnswers answers, StringView projectDirectory, ProjectSettings settings, McpFolderStanding outStanding)
	{
		let project = ProjectKey(projectDirectory, .. scope .());
		let listed = scope List<String>();
		defer { ClearAndDeleteItems!(listed); }
		Resolve(projectDirectory, settings, listed);
		for (let folder in listed)
		{
			let answer = answers.Find(project, folder);
			if (answer == null)
				outStanding.Unanswered.Add(new String(folder));
			else if (answer.Allowed)
				outStanding.Approved.Add(new String(folder));
		}
	}

	/// Stand over the answers kept in `answersDirectory` (the user's data folder; a test's own).
	/// With no file there, every listed folder is unanswered.
	public static void Stand(StringView answersDirectory, StringView projectDirectory, ProjectSettings settings, McpFolderStanding outStanding)
	{
		let root = scope NativeFileSystem(answersDirectory);
		let store = scope Settings();
		if (Load(root, store) case .Err)
		{
			// Whatever it read before it failed is not trusted: no folder is approved.
			GlobalLog(.Warning, "Editor: {} does not read; no folder outside the project is approved", cFileName);
			Stand(scope McpFolderAnswers(), projectDirectory, settings, outStanding);
			return;
		}
		Stand(store.Section<McpFolderAnswers>(), projectDirectory, settings, outStanding);
	}
}
