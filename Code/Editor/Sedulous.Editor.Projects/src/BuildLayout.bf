using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Editor.Project;

/// Where the Beef build puts things, for the tools that ship them. A workspace builds into
/// <build>/<Config>_<Platform>/<Project>/, every executable in its own directory with the
/// shared libraries CopyToDependents placed beside it; the web player is an .html with its .js
/// and .wasm. What ships beside a player is the shared libraries found beside it.
static class BuildLayout
{
	/// The engine's logo the web page's loading card shows, staged beside the page.
	public const String cWebLogoName = "sedulous-logo.svg";
	/// The licences of the third-party components a binary carries, which their notices must go
	/// with: beside every player and editor as they build (Dependencies/THIRD-PARTY-NOTICES.txt),
	/// and so shipped beside every exported player.
	public const String cThirdPartyNotices = "THIRD-PARTY-NOTICES.txt";
	/// The platform tag of the web build; the Beef directory says wasm32.
	public const String cWebPlatform = "Web";

	public static StringView HostPlatformName
	{
		get
		{
#if BF_PLATFORM_WINDOWS
			return "Win64";
#elif BF_PLATFORM_MACOS
			return "macOS";
#else
			return "Linux64";
#endif
		}
	}

	/// The executable's file name for a base name on the host.
	public static void ExecutableName(StringView baseName, String outName)
	{
		outName.Set(baseName);
#if BF_PLATFORM_WINDOWS
		outName.Append(".exe");
#endif
	}

	/// "<Config>_<Platform>" read off a build directory, <build>/<Config>_<Platform>/<Project>:
	/// the parent's name splits at the underscore. Both left empty for any other directory,
	/// so the caller's defaults survive.
	public static void ParseBuildDirectory(StringView dir, String outConfig, String outPlatform)
	{
		let trimmed = scope String(dir);
		while (trimmed.EndsWith("/") || trimmed.EndsWith("\\"))
			trimmed.RemoveFromEnd(1);
		if (trimmed.IsEmpty)
			return;
		let parent = PathParent(trimmed, .. scope .());
		let name = PathFilename(parent, .. scope .());
		let underscore = name.IndexOf('_');
		if (underscore <= 0)
			return;
		// Only a real "<Config>_<Platform>" pair: any other underscored directory is not a
		// build directory, and the caller's defaults survive.
		let config = name.Substring(0, underscore);
		let platform = name.Substring(underscore + 1);
		if ((config != "Debug") && (config != "Release") && (config != "ShippingRelease") && (config != "Test"))
			return;
		if ((platform != "Linux64") && (platform != "Win64") && (platform != "macOS") && (platform != "wasm32"))
			return;
		outConfig.Set(config);
		outPlatform.Set((platform == "wasm32") ? cWebPlatform : platform);
	}

	/// The shared libraries beside a player: its runtime sidecars.
	public static void CollectSharedLibraries(StringView directory, List<String> outNames)
	{
		ListDirectory(directory, scope [&](name, isDirectory) =>
			{
				if (isDirectory)
					return;
				// A versioned ".so.0" too: a bundle that carries its own SDL carries it by soname.
				if (name.EndsWith(".so") || name.Contains(".so.") || name.EndsWith(".dll") || name.EndsWith(".dylib"))
					outNames.Add(new String(name));
			});
		outNames.Sort(scope (a, b) => a <=> b);
	}

	/// The web player's parts beside its page: the .js and .wasm, and anything else shipped
	/// in dist beside the page.
	public static void CollectWebParts(StringView directory, StringView pageName, List<String> outNames)
	{
		ListDirectory(directory, scope [&](name, isDirectory) =>
			{
				if (isDirectory || (name == pageName))
					return;
				// serve.py and the engine's logo (the loading card's): what the build stages beside
				// the page, which an export ships.
				if (name.EndsWith(".js") || name.EndsWith(".wasm") || name.EndsWith(".data") || (name == "serve.py") || (name == cWebLogoName)
					|| (name == cThirdPartyNotices))
					outNames.Add(new String(name));
			});
		outNames.Sort(scope (a, b) => a <=> b);
	}
}
