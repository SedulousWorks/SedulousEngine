using System;
using Sedulous.Core.IO;
using Sedulous.VFS;

namespace Samples.Common;

/// The data root, for samples that are not applications and so have no host to ask.
///
/// A DefaultApplication sample takes DataRoot and DataPath from the base class instead: the
/// application resolves the root once at Configure and everything below reads relative to it.
/// This is for the few places that run before or outside one.
static class SampleContent
{
	/// The layout under the root, spelled here once for the samples that share it.
	public const String cAssetRoot = "Assets";
	public const String cAudioDir = "Assets/audio/playground";
	public const String cRobotoFont = "Assets/fonts/roboto/Roboto-Regular.ttf";

	/// The data root, discovered once and kept. Empty when there is none, which every caller
	/// treats as "that content is absent" rather than as a failure.
	public static StringView Root
	{
		get
		{
			if (!sResolved)
			{
				FindDataRoot(sRoot);
				sResolved = true;
			}
			return sRoot;
		}
	}

	private static String sRoot = new .() ~ delete _;
	private static bool sResolved = false;

	/// A root relative path as an absolute one, or false when this checkout has no data.
	public static bool FindFile(StringView relative, String outPath)
	{
		DataPath(Root, relative, outPath);
		if (!Root.IsEmpty && FileExists(outPath))
			return true;
		outPath.Clear();
		return false;
	}

	public static bool FindDirectory(StringView relative, String outPath)
	{
		DataPath(Root, relative, outPath);
		if (!Root.IsEmpty && DirectoryExists(outPath))
			return true;
		outPath.Clear();
		return false;
	}
}
