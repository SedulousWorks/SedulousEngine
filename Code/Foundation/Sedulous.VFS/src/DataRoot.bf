using System;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;

namespace Sedulous.VFS;

/// Finds the data root: the directory holding runtime assets, identified by a marker file.
///
/// Discovery is anchored at the EXECUTABLE, then falls back to the working directory. The
/// working directory is unreliable on its own, since an application launched from a menu
/// or a desktop entry inherits whatever directory the launcher was in.
///
/// One runtime-discovered root replaces per-asset compile-time paths and behaves the same
/// in a source checkout and a shipped build. Mounting it is two lines:
///
///     let dataFs = scope NativeFileSystem(FindDataRoot(.. scope String()));
///     vfs.Mount("data", dataFs);
static
{
	/// The file that marks a directory as a data root.
	public const String cDataRootMarker = ".dataroot";

	public static bool IsDataRoot(StringView directory)
	{
		return FileExists(PathJoin(directory, cDataRootMarker, .. scope String()));
	}

	/// Walks up from a directory, returning the first "<ancestor>/Data" that is a data
	/// root, or leaving the output empty.
	///
	/// The first iteration also covers "<startDirectory>/Data", which is the relocated
	/// distribution case where Data sits beside the executable.
	public static void FindDataRootFrom(StringView startDirectory, String outPath)
	{
		outPath.Clear();

		let directory = scope String(startDirectory);
		while (!directory.IsEmpty)
		{
			let candidate = PathJoin(directory, "Data", .. scope:: String());
			if (IsDataRoot(candidate))
			{
				outPath.Set(candidate);
				return;
			}

			let parent = PathParent(directory);
			if (parent.Length == directory.Length)
				break; // a root that is its own parent
			directory.Set(parent);
		}
	}

	/// The data root, or empty when there is none. Searched from the executable's
	/// directory first, then the working directory.
	public static void FindDataRoot(String outPath)
	{
		FindDataRootFrom(GetExecutableDirectory(.. scope String()), outPath);
		if (!outPath.IsEmpty)
			return;

		FindDataRootFrom(GetCurrentDirectory(.. scope String()), outPath);
		if (!outPath.IsEmpty)
			return;

		// Loud, not silent. A caller that falls back to build-machine paths otherwise
		// leaves a user with a botched extraction staring at missing assets and no clue.
		// Naming what was searched makes the fix self-service: put Data beside the exe.
		GlobalLog(.Warning,
			"VFS: no data root found. Searched up from the executable directory '{}' and the working directory '{}' for a Data/{} marker.",
			GetExecutableDirectory(.. scope String()), GetCurrentDirectory(.. scope String()), cDataRootMarker);
	}

	/// Joins a data-root-relative path onto a root. An empty root gives back the relative
	/// path unchanged, so a caller can pass FindDataRoot straight through and keep a
	/// fallback for the empty case.
	public static void DataPath(StringView dataRoot, StringView relative, String outPath)
	{
		if (dataRoot.IsEmpty)
		{
			outPath.Set(relative);
			return;
		}
		PathJoin(dataRoot, relative, outPath);
	}
}
