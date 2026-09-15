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

			let parent = PathParent(directory, .. scope:: String());
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

		// Loud, not silent, and an ERROR rather than a warning: there is no compile time
		// fallback, so a botched extraction otherwise surfaces as unexplained missing assets.
		// Naming what was searched makes the fix self-service.
		GlobalLog(.Error,
			"VFS: no data root found. Searched up from the executable directory '{}' and the working directory '{}' for a Data/{} marker. Put Data beside the executable, or pass {} <dir>.",
			GetExecutableDirectory(.. scope String()), GetCurrentDirectory(.. scope String()),
			cDataRootMarker, cDataRootArgument);
	}

	/// The command line override every entry point honours.
	public const String cDataRootArgument = "--data-root";

	/// The override from a command line, or empty when it is absent or given without a value.
	///
	/// Both spellings, because a launcher writes one and a person types the other.
	public static void DataRootFromArguments(Span<String> arguments, String outPath)
	{
		outPath.Clear();

		for (int i < arguments.Length)
		{
			let argument = arguments[i];
			if (argument == cDataRootArgument)
			{
				if (i + 1 < arguments.Length)
					outPath.Set(arguments[i + 1]);
				return;
			}

			if (argument.StartsWith(scope $"{cDataRootArgument}="))
			{
				outPath.Set(argument.Substring(cDataRootArgument.Length + 1));
				return;
			}
		}
	}

	/// The data root: an explicit override where there is one, otherwise the discovery walk.
	///
	/// The override is VALIDATED. A directory without the marker is refused rather than used,
	/// because a mistyped path that silently becomes the root fails later and further away,
	/// on the first asset that is not where it should be.
	public static void ResolveDataRoot(StringView overrideDirectory, String outPath)
	{
		outPath.Clear();

		if (!overrideDirectory.IsEmpty)
		{
			if (IsDataRoot(overrideDirectory))
			{
				outPath.Set(overrideDirectory);
				return;
			}

			GlobalLog(.Error, "VFS: {} '{}' is not a data root, since it holds no {} marker.",
				cDataRootArgument, overrideDirectory, cDataRootMarker);
			return;
		}

		FindDataRoot(outPath);
	}

	/// The entry point form: the override from the command line, else the discovery walk.
	public static void ResolveDataRoot(Span<String> arguments, String outPath)
	{
		ResolveDataRoot(DataRootFromArguments(arguments, .. scope String()), outPath);
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
