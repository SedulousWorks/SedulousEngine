using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Engine.Project;

namespace Sedulous.Engine.Project.Tests;

/// The manifest a project and a distribution are both described by.
///
/// The [Serializable] generator walks the declaration, so what is on the wire follows from
/// the field ORDER and NAMES. These pin both, because a rename or a reorder would change
/// the document silently.
class ProjectManifestTests
{
	private const String kScratch = "scratch_engine_project";

	private static void FreshScratch()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
	}

	/// Sorted last, so the manifests these cases write do not survive the run. A suite that
	/// leaves them behind is a suite whose output gets committed by accident.
	[Test]
	public static void ZzCleanup()
	{
		RemoveDirectoryRecursive(kScratch);
	}

	/// A copy goes through the settings' own serialization, so it carries every field, the
	/// ones added after it was written too: the two manifests are the same document.
	[Test]
	public static void ACopyCarriesEverySetting()
	{
		FreshScratch();

		let from = scope ProjectSettings();
		from.Name.Set("Demo");
		from.DefaultSceneId = .(0x11223344, 0x5566, 0x7788, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00);
		from.DefaultScene.Set("Scenes/Main");
		from.LoadingDocumentId = .(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
		from.RenderMsaaSamples = 4;
		from.UiFontIds.Add(.(9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9));
		from.RenderWidth = 1280;
		from.RenderHeight = 800;
		from.RenderFit = .Crop;
		from.WindowMode = .Fullscreen;
		from.WindowResizable = false;

		let to = scope ProjectSettings();
		Test.Assert(ProjectManifest.Copy(from, to) case .Ok);
		Test.Assert((to.LoadingDocumentId == from.LoadingDocumentId) && (to.RenderMsaaSamples == 4));
		Test.Assert((to.UiFontIds.Count == 1) && (to.RenderFit == .Crop) && (to.WindowMode == .Fullscreen) && !to.WindowResizable);

		// Field by field, whatever fields there are: both saved, the documents the same.
		let fs = scope NativeFileSystem(kScratch);
		Test.Assert(ProjectManifest.Save(fs, from, "from.xml") case .Ok);
		Test.Assert(ProjectManifest.Save(fs, to, "to.xml") case .Ok);
		let fromText = File.ReadAllText(scope $"{kScratch}/from.xml", .. scope .());
		let toText = File.ReadAllText(scope $"{kScratch}/to.xml", .. scope .());
		Test.Assert(!fromText.IsEmpty && (fromText == toText), "the copy is the same document");
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

	/// The other UI fonts round trip, and a manifest saved before they existed (no
	/// uiFontIds key) still loads, with none: every project saved until now is one.
	[Test]
	public static void TheUiFontsRoundTripAndAnOlderManifestStillLoads()
	{
		FreshScratch();
		let fs = scope NativeFileSystem(kScratch);

		let written = scope ProjectSettings();
		written.Name.Set("Fonts");
		let title = Guid.Create();
		let mono = Guid.Create();
		written.UiFontIds.Add(title);
		written.UiFontIds.Add(mono);
		Test.Assert(ProjectManifest.Save(fs, written) case .Ok);
		{
			let read = scope ProjectSettings();
			Test.Assert(ProjectManifest.Load(fs, read) case .Ok);
			Test.Assert((read.UiFontIds.Count == 2) && (read.UiFontIds[0] == title) && (read.UiFontIds[1] == mono));
		}

		// The same manifest as an older engine wrote it: no uiFontIds element at all.
		let path = scope $"{kScratch}/{ProjectLayout.ManifestFile}";
		let text = scope String();
		Test.Assert(File.ReadAllText(path, text) case .Ok);
		let start = text.IndexOf("<array name=\"uiFontIds\"");
		Test.Assert(start >= 0, text);
		let end = text.IndexOf("</array>", start) + "</array>".Length;
		text.Remove(start, end - start);
		Test.Assert(File.WriteAllText(path, text) case .Ok);
		{
			let read = scope ProjectSettings();
			Test.Assert(ProjectManifest.Load(fs, read) case .Ok, "an older manifest loads");
			Test.Assert((read.Name == "Fonts") && read.UiFontIds.IsEmpty);
		}
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
