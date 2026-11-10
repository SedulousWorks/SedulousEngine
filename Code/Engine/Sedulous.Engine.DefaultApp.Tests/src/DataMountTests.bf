using System;
using Sedulous.Core;
using Sedulous.Engine.DefaultApp;
using Sedulous.VFS;

namespace Sedulous.Engine.DefaultApp.Tests;

/// The engine data's mount: found by the data root's discovery walk, or handed over by a host
/// whose data is not a folder (an Android app's, in its APK), in which case no root is resolved.
class DataMountTests
{
	[Test]
	public static void AMountTheHostGivesIsTheDataMountAndNoRootIsResolved()
	{
		let root = FindDataRoot(.. scope String());
		Test.Assert(!root.IsEmpty);
		let mount = new NativeFileSystem(root);

		let host = scope StubHost();
		let app = scope DefaultApplication();
		// A data root asked for too is never resolved: the mount wins.
		app.SetDataRoot(root);
		app.SetDataFileSystem(mount); // the app owns it from here
		app.Configure(host);
		Test.Assert(app.DataFileSystem === mount);
		Test.Assert(app.DataRoot.IsEmpty);

		host.Subsystems.Startup();
		app.OnStartup(host);
		host.Subsystems.Shutdown();
		app.OnShutdown(host);
		host.Subsystems.Dispose();
	}

	[Test]
	public static void WithoutOneTheRootIsFoundAndMounted()
	{
		let host = scope StubHost();
		let app = scope DefaultApplication();
		app.Configure(host);
		Test.Assert(app.DataFileSystem is NativeFileSystem);
		Test.Assert(!app.DataRoot.IsEmpty);
		Test.Assert(app.DataFileSystem.Exists(".dataroot"));

		host.Subsystems.Startup();
		app.OnStartup(host);
		host.Subsystems.Shutdown();
		app.OnShutdown(host);
		host.Subsystems.Dispose();
	}
}
