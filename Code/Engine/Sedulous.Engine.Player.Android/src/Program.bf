using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Engine.Player;
using Sedulous.Engine.Player.DesktopMain;
using Sedulous.Engine.Project;
using Sedulous.VFS.Pak;
using Sedulous.VFS.Zip;

namespace Sedulous.Engine.Player.Android;

/// The ANDROID entry for the player: SDL's activity calls SDL_main (native/AndroidMain.c), which
/// calls this through BeefMain.
///
/// The game and the engine's data are read in place from the app's APK (assets/Game and
/// assets/Data; the paks stored uncompressed so they are regions of the file), and the user's data
/// and temporary files go to the app's own storage, which the activity names: `--apk <path>
/// --files <dir> --cache <dir>`. The rest of the arguments go to the player as on the desktop.
/// Without `--apk` (a run on a desktop for a test) it is the desktop player as it is.
class Program
{
	public const String cGameFolder = "assets/Game";
	public const String cDataFolder = "assets/Data";

	public static int Main(String[] args)
	{
		let apk = scope String();
		let files = scope String();
		let cache = scope String();
		let rest = scope List<String>();
		for (int i = 0; i < args.Count; i++)
		{
			if ((i + 1 < args.Count) && (args[i] == "--apk"))
				apk.Set(args[++i]);
			else if ((i + 1 < args.Count) && (args[i] == "--files"))
				files.Set(args[++i]);
			else if ((i + 1 < args.Count) && (args[i] == "--cache"))
				cache.Set(args[++i]);
			else
				rest.Add(args[i]);
		}
		let passed = scope String[rest.Count];
		for (int i < rest.Count)
			passed[i] = rest[i];

		// The user data (saves, settings, profiles) under the app's files folder, and temporary
		// files under its cache: an app has neither HOME nor XDG_DATA_HOME of its own.
		if (!files.IsEmpty)
			Environment.SetEnvironmentVariable("XDG_DATA_HOME", files);
		if (!cache.IsEmpty)
			Environment.SetEnvironmentVariable("TMPDIR", cache);

		if (apk.IsEmpty)
			return DesktopPlayerMain.Run(passed);

		let mounts = scope PlayerMounts();
		if (MountApk(apk, mounts) case .Err)
			return 1;
		return DesktopPlayerMain.Run(passed, mounts);
	}

	/// The game, its content pak and the engine's data, from the APK at `apk`.
	public static Result<void> MountApk(StringView apk, PlayerMounts outMounts)
	{
		let game = new ZipFileSystem(apk, cGameFolder);
		if (!game.IsValid)
		{
			Console.Error.WriteLine(scope $"Player: the APK '{apk}' did not read: {game.Error}");
			delete game;
			return .Err;
		}
		outMounts.Game = game;

		// The pak is stored, not compressed, so it is read as a region of the APK file; a
		// compressed one would be inflated whole into memory on every open.
		if (game.StoredRegion(ProjectLayout.DistContentPak, let offset, let size))
			outMounts.Content = new PakFileSystem(apk, offset, size);
		else if (game.Exists(ProjectLayout.DistContentPak))
			Console.Error.WriteLine("Player: the game's content pak is compressed in the APK; store it uncompressed (noCompress)");

		let data = new ZipFileSystem(apk, cDataFolder);
		if (data.IsValid && (data.EntryCount > 0))
			outMounts.Data = data;
		else
			delete data;
		return .Ok;
	}
}
