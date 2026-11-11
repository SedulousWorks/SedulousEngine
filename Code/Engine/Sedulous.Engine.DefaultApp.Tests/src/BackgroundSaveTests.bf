using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.GameInstance;

namespace Sedulous.Engine.DefaultApp.Tests;

/// A phone may end an app in the background without asking, so what each run's game saved is
/// written on the way there rather than only as the run ends.
class BackgroundSaveTests
{
	[Test]
	public static void GoingToTheBackgroundWritesWhatEachRunsGameSaved()
	{
		let scratch = "scratch_defaultapp_background";
		RemoveDirectoryRecursive(scratch);
		defer RemoveDirectoryRecursive(scratch);
		let path = PathJoin(scratch, "save.xml", .. scope String());

		let host = scope StubHost();
		let app = scope DefaultApplication();
		app.Configure(host);
		host.Subsystems.Startup();
		app.OnStartup(host);

		let save = app.Instance.Saves;
		app.Instance.SetSaveFile(path);
		save.Values.SetInt("stars", 3);
		save.MarkChanged();
		Test.Assert(!FileExists(path), "the run is still going: nothing written yet");

		app.OnEnterBackground(host);
		Test.Assert(FileExists(path));
		Test.Assert(!save.HasChanges);
		let reread = scope RunSave();
		reread.Open(path);
		Test.Assert(reread.Values.GetInt("stars", 0) == 3);

		host.Subsystems.Shutdown();
		app.OnShutdown(host);
		host.Subsystems.Dispose();
	}
}
