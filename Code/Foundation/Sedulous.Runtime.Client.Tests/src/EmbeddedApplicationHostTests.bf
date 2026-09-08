using System;
using Sedulous.Core;
using Sedulous.Graphics;
using Sedulous.Graphics.Null;
using Sedulous.Runtime;
using Sedulous.Shell;
using Sedulous.Shell.Null;

namespace Sedulous.Runtime.Client.Tests;

/// The adapter that lets one application run inside an editor unchanged.
///
/// What it has to get right is the SPLIT: the context is the embedder's own, so the
/// hosted application's subsystems are separate from the editor's, while the shell and
/// the real device are shared, because there is only one of each per process.
class EmbeddedApplicationHostTests
{
	[Test]
	public static void TheEmbeddedHostSplitsTheContextAndSharesTheDevice()
	{
		let shell = scope NullShell();
		Test.Assert(NullGraphics.CreateDevice(2) case .Ok(let device));
		defer delete device;

		let outerApp = scope LifecycleApp();
		let outer = scope ApplicationHost();
		outer.Start(outerApp, shell, device);
		defer outer.Stop();

		let embeddedContext = scope Context();
		let embedded = scope EmbeddedApplicationHost(outer, embeddedContext);

		Test.Assert(embedded.Context === embeddedContext, "the embedded context, not the outer's");
		Test.Assert(embedded.Context !== outer.Context);
		Test.Assert(embedded.Shell === shell, "one shell per process");
		Test.Assert(embedded.Graphics === device, "the REAL device, shared");
	}

	/// No OS window: the embedded application renders into the embedder's viewport
	/// texture. Attaching to a main window has to tolerate null here exactly as it does
	/// headless, and asking for a window is refused rather than half honoured.
	[Test]
	public static void TheEmbeddedHostHasNoWindowsAndRefusesToOpenOne()
	{
		let shell = scope NullShell();
		Test.Assert(NullGraphics.CreateDevice(2) case .Ok(let device));
		defer delete device;

		let outerApp = scope LifecycleApp();
		let outer = scope ApplicationHost();
		outer.Start(outerApp, shell, device);
		defer outer.Stop();

		let embeddedContext = scope Context();
		let embedded = scope EmbeddedApplicationHost(outer, embeddedContext);

		Test.Assert(embedded.MainRenderWindow == null);
		Test.Assert(embedded.OpenWindow(WindowSettings(), RenderWindowDesc()) == null);

		// The outer host's own windows are untouched by the refusal.
		Test.Assert(outer.Windows.Length == 1);
		embedded.CloseWindow(outer.MainRenderWindow);
		Test.Assert(outer.Windows.Length == 1, "closing through the embedded host is a no op");
	}

	/// Exit means "stop the play session", and only the embedder knows what that entails,
	/// so it supplies the meaning. Without a handler the request is reported and dropped
	/// rather than tearing anything down.
	[Test]
	public static void ExitGoesToTheEmbeddersHandler()
	{
		let outer = scope ApplicationHost();
		let outerApp = scope LifecycleApp();
		outer.Start(outerApp);
		defer outer.Stop();

		let embeddedContext = scope Context();
		let embedded = scope EmbeddedApplicationHost(outer, embeddedContext);

		int seenCode = -1;
		// Dropped, not fatal.
		embedded.RequestExit(3);
		Test.Assert(seenCode == -1);

		embedded.SetExitHandler(scope [&](code) => { seenCode = code; });
		embedded.RequestExit(7);
		Test.Assert(seenCode == 7);

		// The outer host is NOT stopped by the embedded application exiting: only the play
		// session was meant to end.
		Test.Assert(outer.IsRunning);
	}
}
