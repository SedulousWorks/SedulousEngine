using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;

namespace Sedulous.Engine.Player.Web;

/// Pulling the player's dist files out of the serving folder and into the browser's in memory
/// filesystem.
///
/// WHY THE PLAYER FETCHES AT ALL, when the web samples do not: a sample bakes its data into
/// the package with emcc's --preload-file, because it knows at LINK time exactly what it
/// needs. The player is one generic binary that runs whichever game is served beside it, so
/// its Content.pak cannot be baked in. It fetches instead, and skips anything a build did
/// manage to preload.
///
/// Synchronous, which only works because the link enables ASYNCIFY: emscripten_wget yields to
/// the browser while the request runs and resumes here when it lands. Without that flag these
/// calls hang the page.
static class WebDist
{
#if BF_PLATFORM_WASM
	/// Returns int32, not void: emscripten.h declares it void but libhtml5.a defines it
	/// returning i32, and wasm-ld warns on the mismatch.
	[CLink, CallingConvention(.Cdecl)]
	private static extern int32 emscripten_wget(char8* url, char8* file);
#endif

	/// Fetches `name` from the serving folder to the same name locally.
	///
	/// A file that is already there was preloaded into the package, so this leaves it alone:
	/// that is what lets one entry point serve both a preloaded bundle and a fetched dist.
	public static void Fetch(StringView name)
	{
		if (FileExists(name))
			return;

		FetchAs(name, name);

		if (!FileExists(name))
		{
			GlobalLog(.Error, "Player: could not fetch '{}' from the serving folder. Is it "
				+ "next to the player page?", name);
		}
	}

	/// Fetches `source` and saves it locally as `destination`, answering whether it arrived.
	///
	/// The rename is the point: it lets a variant file be mounted under the name the loader
	/// already opens, so nothing downstream has to know a variant was chosen.
	public static bool FetchAs(StringView source, StringView destination)
	{
#if BF_PLATFORM_WASM
		emscripten_wget(source.ToScopeCStr!(), destination.ToScopeCStr!());
#endif
		return FileExists(destination);
	}
}
