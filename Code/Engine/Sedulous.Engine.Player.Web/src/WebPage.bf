using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;

namespace Sedulous.Engine.Player.Web;

/// What the player tells the page, and the browser storage behind the user data directory:
/// the calls into player.js, linked with --js-library.
static class WebPage
{
	[CLink, CallingConvention(.Cdecl)]
	private static extern void sedulous_mount_user_data(char8* path);
	[CLink, CallingConvention(.Cdecl)]
	private static extern int32 sedulous_user_data_loaded();
	[CLink, CallingConvention(.Cdecl)]
	private static extern int32 sedulous_user_data_persistent();
	[CLink, CallingConvention(.Cdecl)]
	private static extern void sedulous_persist_user_data();
	[CLink, CallingConvention(.Cdecl)]
	private static extern void sedulous_page_game_running();
	[CLink, CallingConvention(.Cdecl)]
	private static extern void sedulous_page_game_ended(int32 started);
	[CLink, CallingConvention(.Cdecl)]
	private static extern int32 sedulous_page_wants_input_trace();
	[CLink, CallingConvention(.Cdecl)]
	private static extern int32 sedulous_page_wants_profiler_overlay();
	[CLink, CallingConvention(.Cdecl)]
	private static extern void emscripten_sleep(uint32 milliseconds);

	/// Saves outlive the page: the user data directory (where a game's save and the user's
	/// settings live) is mounted over the browser's IndexedDB, and what the page stored there
	/// before is loaded into it, before the game starts reading it. Writers then push changes
	/// back with PersistUserData. Synchronous under ASYNCIFY, as the fetches are.
	public static void MountUserData()
	{
		let directory = scope String();
		GetUserDataDirectory(directory);
		CreateDirectory(directory);
		sedulous_mount_user_data(directory.CStr());
		while (sedulous_user_data_loaded() == 0)
			emscripten_sleep(10);
		UserDataPersister = => sedulous_persist_user_data;
		GlobalLog(.Information, "Player: user data at '{}' ({})", directory,
			(sedulous_user_data_persistent() != 0) ? "kept in the browser's storage" : "in memory for this page");
	}

	/// `?trace` in the page's address turns on the input trace (SEDULOUS_INPUT_TRACE): the input
	/// path logs what it receives, which the page shows in a panel over the game (shell.html), so
	/// a phone can show what it sends. Before the app starts, so before anything reads it.
	public static void ApplyInputTrace()
	{
		if (sedulous_page_wants_input_trace() != 0)
			Environment.SetEnvironmentVariable("SEDULOUS_INPUT_TRACE", "1").IgnoreError();
	}

	/// `?profile-overlay` in the page's address: the profiler overlay from the start, as the
	/// desktop player's --profile-overlay.
	public static bool WantsProfilerOverlay => sedulous_page_wants_profiler_overlay() != 0;

	/// The game is running: the page's loading card can go.
	public static void GameRunning() => sedulous_page_game_running();

	/// The game has stopped; `started` says whether it ever ran (a quit) or could not start.
	public static void GameEnded(bool started) => sedulous_page_game_ended(started ? 1 : 0);
}
