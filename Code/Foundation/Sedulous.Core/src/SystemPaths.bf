using System;
using Sedulous.Core.IO;

namespace Sedulous.Core;

/// The few things about the host a program has to ask for by name.
///
/// Most of Raptor's System module is corlib here: ticks, core counts, page sizes and file
/// primitives all have Beef equivalents, and the executable's directory is already in
/// Core.IO. What is left is the environment lookup and the per-user data directory built
/// on it, which no standard library gives portably.
static
{
	/// The application's folder name under the per-user data directory.
	///
	/// Raptor bakes this in from the build system so the name exists in exactly one place.
	/// There is no such hook here, so it is a constant, which is the same property: one
	/// place to change it.
	public const String UserDataDirectoryName = "Sedulous";

	/// An environment variable's value, or Err when it is unset.
	///
	/// Unset and empty are DIFFERENT: a variable set to nothing is a deliberate statement,
	/// and collapsing the two makes it impossible to say which happened.
	public static Result<void> GetEnvironmentVariable(StringView name, String outValue)
	{
		return Environment.GetEnvironmentVariable(name, outValue);
	}

	/// Where this application's per-user files belong, with its own folder already joined
	/// on.
	///
	/// XDG_DATA_HOME or ~/.local/share on Linux, LOCALAPPDATA on Windows: per user and
	/// machine local. Not the roaming folder on Windows, because a cache or a shader blob
	/// following a user between machines is a slow login rather than a feature.
	///
	/// Falls back to the bare application name when nothing resolves, so the caller always
	/// has a usable relative path rather than an empty string it has to check for.
	public static void GetUserDataDirectory(String outPath, StringView appName = UserDataDirectoryName)
	{
		outPath.Clear();

		let root = scope String();
#if BF_PLATFORM_WINDOWS
		Environment.GetEnvironmentVariable("LOCALAPPDATA", root).IgnoreError();
#else
		if (Environment.GetEnvironmentVariable("XDG_DATA_HOME", root) case .Err)
			root.Clear();
		if (root.IsEmpty)
		{
			let home = scope String();
			if (Environment.GetEnvironmentVariable("HOME", home) case .Ok)
			{
				if (!home.IsEmpty)
					PathJoin(home, ".local/share", root);
			}
		}
#endif

		if (root.IsEmpty)
		{
			outPath.Append(appName);
			return;
		}
		PathJoin(root, appName, outPath);
	}
}
