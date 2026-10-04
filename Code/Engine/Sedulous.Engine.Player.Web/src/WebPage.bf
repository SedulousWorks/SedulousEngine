using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;

namespace Sedulous.Engine.Player.Web;

/// The browser storage behind the user data directory: the calls into player.js, linked with
/// --js-library.
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

}
