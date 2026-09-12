using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Engine.Project;

namespace Sedulous.Engine.Project.Tests;

/// The manifest a project and a distribution are both described by.
///
/// Raptor writes the field list out by hand in Serialize; here the [Serializable] generator
/// walks the declaration, so what is on the wire follows from the field ORDER and NAMES.
/// These pin both, because a rename or a reorder would change the document silently.
class ProjectManifestTests
{
	private const String kScratch = "scratch_engine_project";

	private static void FreshScratch()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
	}

	[Test]
	public static void AManifestRoundTripsThroughTheDefaultFileName()
	{
		FreshScratch();

		let written = scope ProjectSettings();
		written.Name.Set("Demo");
		written.DefaultSceneId = .(0x11223344, 0x5566, 0x7788, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00);
		written.DefaultScene.Set("Scenes/Main");
		written.StartupScript.Set("Scripts/Game");
		written.NativeModule.Set("demo_native");
		written.RenderMsaaSamples = 4;

		{
			let fs = scope NativeFileSystem(kScratch);
			Test.Assert(ProjectManifest.Save(fs, written) case .Ok);
		}

		let read = scope ProjectSettings();
		let fs = scope NativeFileSystem(kScratch);
		Test.Assert(ProjectManifest.Load(fs, read) case .Ok);

		Test.Assert(read.Name == "Demo");
		Test.Assert(read.DefaultSceneId == written.DefaultSceneId);
		Test.Assert(read.DefaultScene == "Scenes/Main");
		Test.Assert(read.StartupScript == "Scripts/Game");
		Test.Assert(read.NativeModule == "demo_native");
		Test.Assert(read.RenderMsaaSamples == 4);
	}

	/// Every save re-stamps the engine that wrote it, so a launcher can route on it.
	[Test]
	public static void SavingStampsTheEngineVersion()
	{
		FreshScratch();

		let written = scope ProjectSettings();
		written.EngineVersion.Set("0.0.0-stale");

		let fs = scope NativeFileSystem(kScratch);
		Test.Assert(ProjectManifest.Save(fs, written) case .Ok);
		Test.Assert(written.EngineVersion == EngineVersion.String, "re-stamped in place");

		let read = scope ProjectSettings();
		Test.Assert(ProjectManifest.Load(fs, read) case .Ok);
		Test.Assert(read.EngineVersion == EngineVersion.String);
	}

	/// A distribution manifest is the same payload under another name, which is the whole
	/// reason the file name is a parameter.
	[Test]
	public static void TheDistributionManifestIsTheSamePayload()
	{
		FreshScratch();

		let written = scope ProjectSettings();
		written.Name.Set("Shipped");
		written.RenderMsaaSamples = 2;

		let fs = scope NativeFileSystem(kScratch);
		Test.Assert(ProjectManifest.Save(fs, written, ProjectLayout.DistManifestFile) case .Ok);
		Test.Assert(fs.Exists(ProjectLayout.DistManifestFile));
		Test.Assert(!fs.Exists(ProjectLayout.ManifestFile), "the default name was not used");

		let read = scope ProjectSettings();
		Test.Assert(ProjectManifest.Load(fs, read, ProjectLayout.DistManifestFile) case .Ok);
		Test.Assert(read.Name == "Shipped");
		Test.Assert(read.RenderMsaaSamples == 2);
	}

	/// An absent manifest is NotFound rather than a blank one, so a caller can tell the
	/// difference between a project with defaults and no project at all.
	[Test]
	public static void AMissingManifestIsNotFound()
	{
		FreshScratch();

		let fs = scope NativeFileSystem(kScratch);
		let read = scope ProjectSettings();
		Test.Assert(ProjectManifest.Load(fs, read) case .Err(.NotFound));
	}
}
