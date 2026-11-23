using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;

namespace Sedulous.Mcp;

/// The folders a tool may read or write a file in by a path an agent gives it: the open
/// project and the folders outside it the user approved for it, the user's data folder, the
/// temp folder, and folders the user named (the host's start folder, --allow-path, the editor's
/// --mcp-allow-path and MCP allowedFolders). A path anywhere else is
/// refused, so an agent cannot be led to write over, or read, a file the user never put in
/// its reach. Paths are compared by their text (PathNormalizeLexically): a link inside an
/// allowed folder can still lead out of it.
class McpPathPolicy
{
	private String mProject = new .() ~ delete _;
	private List<String> mFolders = new .() ~ DeleteContainerAndItems!(_);
	private List<String> mProjectFolders = new .() ~ DeleteContainerAndItems!(_);

	/// The open project's folder, absolute and normalised; empty when none is open.
	public StringView Project => mProject;
	/// How many folders are allowed beside the project.
	public int FolderCount => mFolders.Count;

	/// The open project's folder, empty when none is open, and the folders outside it the user
	/// approved for it (they go with it when another opens).
	public void SetProject(StringView folder, Span<String> projectFolders = default)
	{
		mProject.Clear();
		if (!folder.IsEmpty)
			Resolve(folder, mProject);
		ClearAndDeleteItems!(mProjectFolders);
		for (let extra in projectFolders)
		{
			if (!extra.IsEmpty)
				mProjectFolders.Add(Resolve(extra, .. new String()));
		}
	}

	/// The folders outside the open project the user approved for it, absolute and normalised.
	public Span<String> ProjectFolders => mProjectFolders;

	/// Allows `folder` and everything under it; empty is ignored, and a folder already allowed is
	/// not listed twice.
	public void AddFolder(StringView folder)
	{
		if (folder.IsEmpty)
			return;
		let resolved = Resolve(folder, .. scope String());
		for (let known in mFolders)
		{
			if (known == resolved)
				return;
		}
		mFolders.Add(new String(resolved));
	}

	/// The user's data folder and the temp folder.
	public void AddStandardFolders()
	{
		AddFolder(GetUserDataDirectory(.. scope .()));
		let temp = scope String();
		if (System.IO.Path.GetTempPath(temp) case .Ok)
			AddFolder(temp);
	}

	/// Whether `path` is inside an allowed folder: if so `outResolved` holds it made absolute
	/// (against the working directory) and normalised; if not `outError` gets a message naming
	/// the folders that are allowed and how the user allows another.
	public bool Check(StringView path, String outResolved, String outError)
	{
		outResolved.Clear();
		if (path.IsEmpty)
		{
			outError.Append("no path given");
			return false;
		}
		Resolve(path, outResolved);
		if (!mProject.IsEmpty && PathIsInside(outResolved, mProject))
			return true;
		for (let folder in mProjectFolders)
		{
			if (PathIsInside(outResolved, folder))
				return true;
		}
		for (let folder in mFolders)
		{
			if (PathIsInside(outResolved, folder))
				return true;
		}
		outResolved.Clear();
		outError.AppendF("'{}' is outside the folders this host allows (", path);
		var first = true;
		if (!mProject.IsEmpty)
		{
			outError.Append(mProject);
			first = false;
		}
		for (let folder in mProjectFolders)
		{
			if (!first)
				outError.Append(", ");
			outError.Append(folder);
			first = false;
		}
		for (let folder in mFolders)
		{
			if (!first)
				outError.Append(", ");
			outError.Append(folder);
			first = false;
		}
		if (first)
			outError.Append("none");
		outError.Append("); the user can allow a folder (Sedulous.Tools.Mcp --allow-path <dir>, the editor's --mcp-allow-path or its MCP allowedFolders setting, or the project's mcpFolders once the user approves them in the editor)");
		return false;
	}

	/// Check for an optional path argument: true with `outResolved` empty when `arguments` has
	/// none (or an empty one, so the tool keeps its default), true with it resolved when it is
	/// allowed, false with the refusal in `outError` otherwise.
	public bool CheckArgument(JsonValue arguments, StringView key, String outResolved, String outError)
	{
		outResolved.Clear();
		let given = (arguments != null) ? arguments.Get(key) : null;
		if ((given == null) || given.AsString().IsEmpty)
			return true;
		return Check(given.AsString(), outResolved, outError);
	}

	/// `path` made absolute against the working directory and normalised by its text.
	private static void Resolve(StringView path, String outPath)
	{
		if (PathIsAbsolute(path))
		{
			PathNormalizeLexically(path, outPath);
			return;
		}
		let joined = PathJoin(GetCurrentDirectory(.. scope .()), path, .. scope .());
		PathNormalizeLexically(joined, outPath);
	}
}
