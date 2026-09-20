using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Editor.Core;

/// Where the Beef build puts things, for the tools that ship them. A workspace builds into
/// Code/build/<Config>_<Platform>/<Project>/, every executable in its own directory with the
/// shared libraries CopyToDependents placed beside it; the web player lands in its project's
/// dist/ as an .html with its .js and .wasm. Raptor's CMake layout, Bin/<Config>/<Platform>-
/// <Compiler> with a build emitted runtime-libs list, maps onto this: the player directory
/// is a sibling of the tool's, and the sidecars are the shared libraries found beside the
/// player.
static class BuildLayout
{
	public const String cPlayerBaseName = "Sedulous.Engine.Player.Desktop";
	public const String cWebPlayerBaseName = "Sedulous.Engine.Player.Web";
	/// The template id prefix, Raptor's CMake baked TEMPLATE_ID_PREFIX.
	public const String cTemplateIdPrefix = "sedulous";
	public const String cCompilerName = "Beef";
	/// The platform tag of the web build, Raptor's; the Beef directory says wasm32.
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

	/// The build config this binary was made with, from its defines.
	public static StringView BuildConfigName
	{
		get
		{
#if BF_TEST
			return "Test";
#elif BF_DEBUG
			return "Debug";
#else
			return "Release";
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

	/// The desktop player's directory beside a tool's: <build>/<Config>_<Platform>/<Player>.
	public static void PlayerDirectoryBeside(StringView toolDir, String outDir)
	{
		PathJoin(PathParent(toolDir, .. scope .()), cPlayerBaseName, outDir);
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
		if ((config != "Debug") && (config != "Release") && (config != "Test"))
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
				if (name.EndsWith(".so") || name.EndsWith(".dll") || name.EndsWith(".dylib"))
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
				if (name.EndsWith(".js") || name.EndsWith(".wasm") || name.EndsWith(".data"))
					outNames.Add(new String(name));
			});
		outNames.Sort(scope (a, b) => a <=> b);
	}
}
