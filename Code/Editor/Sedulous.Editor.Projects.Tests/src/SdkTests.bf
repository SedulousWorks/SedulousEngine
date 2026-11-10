using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Editor.Projects;
using Sedulous.Editor.Projects.TestSupport;
using internal Sedulous.Editor.Project;

namespace Sedulous.Editor.Projects.Tests;

/// Engine SDKs: what one says of itself (sdk.json, else a checkout's version file), the registry of
/// them and the projects' pins (sdks.xml), the order FindSdk asks its four sources in, and the
/// project's build going stale when the SDK under it changes.
class SdkTests
{
	typealias Bed = ProjectBuildBed;

	/// A scratch folder under the current one, emptied.
	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
	}

	/// An sdk.json as the packer writes it.
	private static void Info(StringView version, StringView label, uint32 buildNumber, String outJson)
	{
		let display = scope String(version);
		if (!label.IsEmpty)
			display.AppendF("-{}", label);
		outJson.AppendF("{{\n  \"version\": \"{}\",\n  \"label\": \"{}\",\n  \"display\": \"{}\",\n  \"buildNumber\": {},\n", version, label, display, buildNumber);
		outJson.Append("  \"platform\": \"Linux64\",\n  \"beef\": \"nightly-2026-11-01\",\n  \"created\": \"2026-11-10T12:00:00Z\"\n}\n");
	}

	/// A checkout's version file at `version` with `label`.
	private static void VersionFile(StringView version, StringView label, String outSource)
	{
		outSource.AppendF("static class EngineVersion\n{{\n\tpublic const uint32 Major = 0;\n\tpublic const String String = \"{}\";\n", version);
		outSource.AppendF("\tpublic const String Label = \"{}\";\n\tpublic const String Display = \"{}-{}\";\n", label, version, label);
		outSource.Append("\tpublic const uint32 BuildNumber = 0;\n}\n");
	}

	/// A checkout at `root`: an SDK without sdk.json, its version in its version file.
	private static void Checkout(StringView root, StringView version)
	{
		Bed.WriteSdk(root);
		Bed.Write(root, SdkInfo.cVersionFile, VersionFile(version, "dev", .. scope .()));
	}

	/// A project at `dir` whose manifest's header names `stamp` (empty: none).
	private static void WriteProject(StringView dir, StringView stamp)
	{
		let text = scope String("<root>\n\t<object>\n\t\t<string name=\"name\">Game</string>\n");
		if (!stamp.IsEmpty)
			text.AppendF("\t\t<string name=\"engineVersion\">{}</string>\n", stamp);
		text.Append("\t</object>\n</root>\n");
		Bed.Write(dir, ProjectLayout.ManifestFile, text);
	}

	[Test]
	public static void AnSdkSaysItsVersionFromSdkJsonElseFromTheCheckoutsVersionFile()
	{
		let root = Scratch("scratch_sdk_info", .. scope .());
		defer RemoveDirectoryRecursive(root);
		let info = scope SdkInfo();

		let packed = PathJoin(root, "packed", .. scope .());
		Bed.WriteSdk(packed, Info("0.2.0", "beta", 7, .. scope .()));
		Test.Assert(SdkInfo.Read(scope $"{packed}/", info) case .Ok);
		Test.Assert(info.Root == packed, info.Root);
		Test.Assert((info.Version == "0.2.0") && (info.Label == "beta") && (info.Display == "0.2.0-beta") && (info.BuildNumber == 7));
		Test.Assert((info.Platform == "Linux64") && (info.Beef == "nightly-2026-11-01") && (info.Created == "2026-11-10T12:00:00Z"));
		Test.Assert(!info.IsCheckout && !SdkInfo.IsCheckoutAt(packed));
		Test.Assert(info.Release == .PreRelease);

		// A display it lacks is composed; members it does not know, nested ones too, are passed by.
		Bed.Write(packed, SdkInfo.cInfoFile, "{\"version\":\"0.3.1\",\"label\":\"\",\"files\":{\"a\":[1,{\"b\":\"}\"}]},\"buildNumber\":0,\"signed\":true}");
		Test.Assert(SdkInfo.Read(packed, info) case .Ok);
		Test.Assert((info.Display == "0.3.1") && (info.Release == .Final) && info.Beef.IsEmpty);
		Bed.Write(packed, SdkInfo.cInfoFile, "{\"version\": \"0.2.0\", \"label\": \"dev\", \"beef\": \"fork \\\"working\\\" \\u0041\\/b\\\\c\"}");
		Test.Assert(SdkInfo.Read(packed, info) case .Ok);
		Test.Assert((info.Release == .Dev) && (info.Beef == "fork \"working\" A/b\\c"), info.Beef);

		// What does not give a version is refused.
		for (let bad in StringView[?]("", "[]", "{\"label\":\"beta\"}", "{\"version\":\"0.2\"}", "{\"version\":\"0.2.0\",\"buildNumber\":\"x\"}",
			"{\"version\":\"0.2.0\"", "{\"version\":\"0.2.0\"} trailing", "{\"version\" \"0.2.0\"}"))
		{
			Bed.Write(packed, SdkInfo.cInfoFile, bad);
			Test.Assert(SdkInfo.Read(packed, info) case .Err(.InvalidArgument), scope String(bad));
			Test.Assert(info.Root.IsEmpty && info.Version.IsEmpty, "nothing is kept from a read that failed");
		}

		// A checkout: no sdk.json, its version file read.
		let checkout = PathJoin(root, "checkout", .. scope .());
		Bed.WriteSdk(checkout);
		Test.Assert(SdkInfo.IsCheckoutAt(checkout));
		Test.Assert(SdkInfo.Read(checkout, info) case .Err(.NotFound), "no version file");
		Bed.Write(checkout, SdkInfo.cVersionFile, VersionFile("0.4.0", "dev", .. scope .()));
		Test.Assert(SdkInfo.Read(checkout, info) case .Ok);
		Test.Assert(info.IsCheckout && (info.Version == "0.4.0") && (info.Display == "0.4.0-dev") && (info.Release == .Dev));
		Test.Assert((info.Platform == BuildLayout.HostPlatformName) && info.Beef.IsEmpty);
		Test.Assert(SdkInfo.Read(PathJoin(root, "nothing", .. scope .()), info) case .Err(.NotFound), "no SDK there");

		// The engine's own version file reads as its constants.
		let own = scope SdkInfo();
		Test.Assert(SdkInfo.ParseVersionFile(Compiler.ReadText("../../Engine/Sedulous.Engine.Project/src/EngineVersion.bf"), own) case .Ok);
		Test.Assert((own.Version == EngineVersion.String) && (own.Label == EngineVersion.Label) && (own.Display == EngineVersion.Display));
		Test.Assert(own.BuildNumber == EngineVersion.BuildNumber);
	}

	[Test]
	public static void FindSdkAsksTheVariableTheRegistryTheDataRootThenTheCheckoutAbove()
	{
		let root = Scratch("scratch_sdk_order", .. scope .());
		defer RemoveDirectoryRecursive(root);
		let checkout = PathJoin(root, "checkout", .. scope .());
		Checkout(checkout, "0.2.0");
		let project = PathJoin(checkout, "Games/Game", .. scope .());
		WriteProject(project, "0.2.0");
		let editorSdk = PathJoin(root, "editor sdk", .. scope .());
		Bed.WriteSdk(editorSdk, Info("0.1.0", "", 1, .. scope .()));
		let dataRoot = PathJoin(editorSdk, "Data", .. scope .());
		let registered = PathJoin(root, "registered", .. scope .());
		Bed.WriteSdk(registered, Info("0.2.0", "", 1, .. scope .()));
		let named = PathJoin(root, "named", .. scope .());
		Bed.WriteSdk(named, Info("0.1.0", "", 1, .. scope .()));
		let registry = scope SdkRegistry(PathJoin(root, "sdks.xml", .. scope .()));
		Test.Assert(registry.Register(registered) case .Ok);
		let empty = scope SdkRegistry(PathJoin(root, "none.xml", .. scope .()));

		let found = scope String();
		Test.Assert(ProjectBuild.FindSdkFrom(named, registry, dataRoot, project, found) && (found == named), "1. the variable");
		Test.Assert(ProjectBuild.FindSdkFrom("", registry, dataRoot, project, found) && (found == registered), "2. the registry");
		Test.Assert(ProjectBuild.FindSdkFrom("", empty, dataRoot, project, found) && (found == editorSdk), "3. the data root's parent");
		Test.Assert(ProjectBuild.FindSdkFrom("", null, dataRoot, project, found) && (found == editorSdk), "no registry");
		Test.Assert(ProjectBuild.FindSdkFrom("", empty, "", project, found) && (found == checkout), "4. the checkout above the project");
		Test.Assert(ProjectBuild.FindSdkFrom("", empty, "", scope $"{project}/", found) && (found == checkout), "a trailing slash too");

		// The registry gives only an SDK of the project's version.
		WriteProject(project, "0.3.0");
		Test.Assert(ProjectBuild.FindSdkFrom("", registry, dataRoot, project, found) && (found == editorSdk), found);
		WriteProject(project, "");
		Test.Assert(ProjectBuild.FindSdkFrom("", registry, dataRoot, project, found) && (found == editorSdk), "no stamp, no pin: no match");
		// A pin needs no stamp.
		Test.Assert(registry.Pin(project, named) case .Ok);
		Test.Assert(ProjectBuild.FindSdkFrom("", registry, dataRoot, project, found) && (found == named), found);
	}

	[Test]
	public static void APinBeatsAVersionMatchAndAFinalBeatsABetaADevBuildAndACheckout()
	{
		let root = Scratch("scratch_sdk_pick", .. scope .());
		defer RemoveDirectoryRecursive(root);
		let registry = scope SdkRegistry(PathJoin(root, "sdks.xml", .. scope .()));
		let checkout = PathJoin(root, "checkout", .. scope .());
		Checkout(checkout, "0.2.0");
		let dev = PathJoin(root, "dev", .. scope .());
		Bed.WriteSdk(dev, Info("0.2.0", "dev", 9, .. scope .()));
		let beta = PathJoin(root, "beta", .. scope .());
		Bed.WriteSdk(beta, Info("0.2.0", "beta", 5, .. scope .()));
		let final1 = PathJoin(root, "final 1", .. scope .());
		Bed.WriteSdk(final1, Info("0.2.0", "", 1, .. scope .()));
		let final3 = PathJoin(root, "final 3", .. scope .());
		Bed.WriteSdk(final3, Info("0.2.0", "", 3, .. scope .()));
		let older = PathJoin(root, "older", .. scope .());
		Bed.WriteSdk(older, Info("0.1.0", "", 4, .. scope .()));
		for (let sdk in StringView[6](checkout, older, dev, final1, beta, final3))
			Test.Assert(registry.Register(sdk) case .Ok);
		Test.Assert(registry.Register(root) case .Err(.InvalidArgument), "not an SDK");

		let project = PathJoin(root, "Game", .. scope .());
		let picked = scope String();
		Test.Assert(registry.Pick(project, "0.2.0", picked) && (picked == final3), "the higher build of two finals");
		Test.Assert(registry.Unregister(final3) case .Ok(true));
		Test.Assert(registry.Unregister(final3) case .Ok(false), "listed no more");
		Test.Assert(registry.Pick(project, "0.2.0", picked) && (picked == final1));
		Test.Assert(registry.Unregister(final1) case .Ok(true));
		Test.Assert(registry.Pick(project, "0.2.0", picked) && (picked == beta), "a beta before a dev build");
		Test.Assert(registry.Unregister(beta) case .Ok(true));
		Test.Assert(registry.Pick(project, "0.2.0", picked) && (picked == dev), "a dev build before a checkout");
		Test.Assert(registry.Pick(project, "0.1.0", picked) && (picked == older));
		Test.Assert(!registry.Pick(project, "0.9.0", picked) && picked.IsEmpty, "none of that version");
		Test.Assert(!registry.Pick(project, "", picked), "no stamp");

		// A pin wins over every match, while it is an SDK.
		Test.Assert(registry.Pin(project, checkout) case .Ok);
		Test.Assert(registry.PinOf(scope $"{project}/", picked) && (picked == checkout));
		Test.Assert(registry.Pick(project, "0.2.0", picked) && (picked == checkout));
		Test.Assert(registry.Pick(project, "", picked) && (picked == checkout), "with no stamp too");
		Test.Assert(registry.Pin(project, older) case .Ok);
		Test.Assert(registry.Pick(project, "0.2.0", picked) && (picked == older), "a pin to another version is the user's upgrade or downgrade");
		RemoveDirectoryRecursive(older);
		Test.Assert(registry.Pick(project, "0.2.0", picked) && (picked == dev), "a pin to a gone SDK is passed by");
		Test.Assert(registry.Unpin(project) case .Ok(true));
		Test.Assert(registry.Unpin(project) case .Ok(false));
		Test.Assert(!registry.PinOf(project, picked));

		// What the list holds, the gone SDK among it as missing.
		let sdks = scope List<SdkInfo>();
		defer { ClearAndDeleteItems!(sdks); }
		let missing = scope List<String>();
		defer { ClearAndDeleteItems!(missing); }
		Test.Assert(registry.ReadSdks(sdks, missing));
		Test.Assert((sdks.Count == 2) && (sdks[0].Root == checkout) && (sdks[1].Root == dev));
		Test.Assert((missing.Count == 1) && (missing[0] == older));

		// The order itself.
		let a = scope SdkInfo();
		let b = scope SdkInfo();
		Test.Assert(SdkInfo.Read(dev, a) case .Ok);
		Test.Assert(SdkInfo.Read(checkout, b) case .Ok);
		Test.Assert(SdkRegistry.Prefer(a, b) && !SdkRegistry.Prefer(b, a), "a dev build before a checkout of the same release");
		b.CopyFrom(a);
		Test.Assert(!SdkRegistry.Prefer(a, b) && !SdkRegistry.Prefer(b, a), "a tie prefers neither");
		b.BuildNumber = a.BuildNumber + 1;
		Test.Assert(SdkRegistry.Prefer(b, a));
		b.Label.Set("beta");
		Test.Assert(SdkRegistry.Prefer(b, a) && (b.Release == .PreRelease));
		a.Label.Clear();
		Test.Assert(SdkRegistry.Prefer(a, b), "a final whatever the build numbers");
	}

	[Test]
	public static void TheRegistryIsReadAgainBeforeEachWriteAndPassesByWhatALaterOneAdds()
	{
		let root = Scratch("scratch_sdk_registry", .. scope .());
		defer RemoveDirectoryRecursive(root);
		let file = PathJoin(root, "Sedulous/sdks.xml", .. scope .());
		let one = PathJoin(root, "one", .. scope .());
		Bed.WriteSdk(one, Info("0.1.0", "", 1, .. scope .()));
		let two = PathJoin(root, "two", .. scope .());
		Bed.WriteSdk(two, Info("0.1.0", "", 2, .. scope .()));

		// Two processes' registries over one file: each change keeps the other's.
		let first = scope SdkRegistry(file);
		let second = scope SdkRegistry(file);
		let store = scope Settings();
		Test.Assert(first.Load(store) case .Ok, "a file not there yet is an empty registry");
		Test.Assert(store.Section<SdkRegistrySettings>().Sdks.IsEmpty);
		Test.Assert(first.Register(one, true) case .Ok);
		Test.Assert(FileExists(file), "its folder made");
		Test.Assert(second.Register(two) case .Ok);
		Test.Assert(first.Pin(PathJoin(root, "Game", .. scope .()), one) case .Ok);
		Test.Assert(second.Register(one) case .Ok, "listed again: marked as a folder, not twice");
		let reread = scope Settings();
		Test.Assert(first.Load(reread) case .Ok);
		let registry = reread.Section<SdkRegistrySettings>();
		Test.Assert(registry.Sdks.Count == 2);
		Test.Assert((registry.Sdks[0].Root == one) && !registry.Sdks[0].Managed);
		Test.Assert(registry.Sdks[1].Root == two);
		Test.Assert((registry.Pins.Count == 1) && (registry.Pins[0].Sdk == one));

		// A field a later version adds is passed by on read, and the rest still reads.
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(file, bytes) case .Ok);
		let text = scope String(StringView((char8*)bytes.Ptr, bytes.Count));
		let rootKey = "<string name=\"root\">";
		Test.Assert(text.Contains(rootKey), text);
		text.Replace(rootKey, scope $"<string name=\"fromLater\">x</string>{rootKey}");
		text.Replace("<bool name=\"managed\">", "<u32 name=\"alsoLater\">3</u32><bool name=\"managed\">");
		Test.Assert(WriteFile(file, .((uint8*)text.Ptr, text.Length)) case .Ok);
		let later = scope Settings();
		Test.Assert(first.Load(later) case .Ok);
		Test.Assert(later.Section<SdkRegistrySettings>().Sdks.Count == 2);
		Test.Assert(later.Section<SdkRegistrySettings>().Sdks[1].Root == two);
		let pinned = scope String();
		Test.Assert(first.PinOf(PathJoin(root, "Game", .. scope .()), pinned) && (pinned == one));

		// A damaged registry is not written over.
		let damaged = "<root><array name=\"sections\" count=\"1\"><object>";
		Test.Assert(WriteFile(file, .((uint8*)damaged.Ptr, damaged.Length)) case .Ok);
		Test.Assert(first.Register(two) case .Err);
		Test.Assert(ReadFile(file, bytes..Clear()) case .Ok);
		Test.Assert(StringView((char8*)bytes.Ptr, bytes.Count) == damaged);
		Test.Assert(!first.PinOf(PathJoin(root, "Game", .. scope .()), pinned));
	}

	[Test]
	public static void GenerateRecordsTheSdkAndTheBuildIsStaleWhenTheSdkChanges()
	{
		let bed = scope Bed();
		let first = PathJoin(bed.Root, "first sdk", .. scope .());
		Bed.WriteSdk(first, Info("0.1.0", "", 1, .. scope .()));
		let second = PathJoin(bed.Root, "second sdk", .. scope .());
		Bed.WriteSdk(second, Info("0.2.0", "beta", 1, .. scope .()));
		let error = scope String();
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, first, error) case .Ok, error);
		Test.Assert(bed.Read(".generated/sdk.txt", .. scope .()) == scope $"{first}\n0.1.0\n");

		System.Threading.Thread.Sleep(50);
		let editor = ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", true, "Debug", .. scope .());
		Bed.Write(bed.ProjectDir, editor.Substring(bed.ProjectDir.Length + 1), "#!editor\n");
		Test.Assert(!ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"));
		Test.Assert(!ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug", first), "built over the SDK found now");
		Test.Assert(!ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug", scope $"{first}/"));
		Test.Assert(ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug", second), "another SDK");

		// The same folder updated to another version.
		Bed.Write(first, SdkInfo.cInfoFile, Info("0.1.1", "", 1, .. scope .()));
		Test.Assert(ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug", first), "the SDK was updated in place");
		Test.Assert(!ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"), "its sources alone say nothing of it");

		// Generated over the second, the build is fresh over it.
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, second, error) case .Ok, error);
		Test.Assert(!ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug", second));
		Test.Assert(ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug", first));
		// With no record the SDK it was built over is not known.
		Test.Assert(DeleteFile(PathJoin(bed.ProjectDir, "Code/.generated/sdk.txt", .. scope .())));
		Test.Assert(ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug", second));

		// Over a checkout (the bed's SDK has no sdk.json) a build is always due: its sources change
		// where the project's cannot see.
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Sdk, error) case .Ok, error);
		Test.Assert(bed.Read(".generated/sdk.txt", .. scope .()) == scope $"{bed.Sdk}\n\n", "a checkout whose version does not read");
		Test.Assert(ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug", bed.Sdk));
		Test.Assert(!ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"));
	}

	/// One SDK reached two ways (a data root's `Code/..`, a path with `.` in it) is one entry:
	/// a path is made absolute and its `.` and `..` segments collapsed before it is listed.
	[Test]
	public static void AnSdkReachedThroughDotDotIsListedOnce()
	{
		Test.Assert(ProjectBuild.Collapse("/a/b/../c/./d/", .. scope .()) == "/a/c/d");
		Test.Assert(ProjectBuild.Collapse("/a/..", .. scope .()) == "/");
		Test.Assert(ProjectBuild.Collapse("/..", .. scope .()) == "/", "a .. at the root stays there");

		let root = Scratch("scratch_sdk_dotdot", .. scope .());
		defer RemoveDirectoryRecursive(root);
		let sdk = PathJoin(root, "sdk", .. scope .());
		Bed.WriteSdk(sdk, Info("0.1.0", "", 1, .. scope .()));
		let registry = scope SdkRegistry(PathJoin(root, "Sedulous/sdks.xml", .. scope .()));
		Test.Assert(registry.Register(sdk) case .Ok);
		Test.Assert(registry.Adopt(scope $"{sdk}/Code/../.") case .Ok);
		let store = scope Settings();
		Test.Assert(registry.Load(store) case .Ok);
		let sdks = store.Section<SdkRegistrySettings>().Sdks;
		Test.Assert((sdks.Count == 1) && (sdks[0].Root == sdk), scope $"{sdks.Count} entries");
	}
}
