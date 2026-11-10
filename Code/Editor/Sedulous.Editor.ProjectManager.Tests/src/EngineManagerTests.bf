using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.VFS;
using Sedulous.GUI;
using Sedulous.Http.Client;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Editor.Projects;
using Sedulous.Editor.ProjectManager;
using Sedulous.Editor.App;
using Sedulous.Editor.Look.TestSupport;
using Sedulous.Editor.Projects.TestSupport;

namespace Sedulous.Editor.ProjectManager.Tests;

/// The engines side by side (EngineManager) over fixture engines, a registry and a recent list of
/// their own, and a loopback server standing in for the releases: the engines listed, each with how
/// it was listed and the projects that open with it; what the releases offer for this platform; an
/// install checked against its digest, unpacked into the managed folder and listed; a wrong digest
/// or an archive that holds no engine keeping nothing; Remove naming the projects first, deleting an
/// installed engine's folder and only unlisting any other; and the toolchain an engine names
/// installed from its release, with Emscripten written into its settings.
class EngineManagerTests
{
	/// The version, label and toolchain the fixture engine (Data/Tests/Zip/sdk.zip) says it is.
	private const String cOfferedVersion = "0.2.0";
	private const String cOfferedDisplay = "0.2.0-beta";
	private const String cPin = "fixture-pin";

	private class Bench
	{
		public String Root = new .() ~ delete _;
		/// Where engines and toolchains are installed.
		public String Sdks = new .() ~ delete _;
		public String Toolchains = new .() ~ delete _;
		public SdkRegistry Registry ~ delete _;
		public Settings Store = new .() ~ delete _;
		public ProjectManagerController Projects ~ delete _;
		public ToolchainProbe Probe = new .() ~ delete _;
		public NativeHttpClient Client = new .(null) ~ delete _;
		public LoopbackFiles Server = new .() ~ delete _;
		/// The fixture engine's and toolchain's zips.
		public List<uint8> SdkZip = new .() ~ delete _;
		public List<uint8> ToolchainZip = new .() ~ delete _;

		public this(StringView leaf)
		{
			PathJoin(GetCurrentDirectory(.. scope .()), leaf, Root);
			RemoveDirectoryRecursive(Root);
			Test.Assert(CreateDirectory(Root));
			PathJoin(Root, "SDKs", Sdks);
			PathJoin(Root, "Toolchains", Toolchains);
			Registry = new .(PathJoin(Root, "sdks.xml", .. scope .()));
			Projects = new .(Store);
			let zips = PathJoin(FindDataRoot(.. scope .()), "Tests/Zip", .. scope .());
			Test.Assert(ReadFile(PathJoin(zips, "sdk.zip", .. scope .()), SdkZip) case .Ok);
			Test.Assert(ReadFile(PathJoin(zips, "toolchain.zip", .. scope .()), ToolchainZip) case .Ok);
			// The toolchain check's surroundings: no BeefBuild of the user's, a linker and an archiver.
			let tools = PathJoin(Root, "tools", .. scope .());
			for (let tool in StringView[2]("c++", "ar"))
				ProjectBuildBed.Write(tools, BuildLayout.ExecutableName(tool, .. scope .()), "#!tool\n");
			Probe.SearchPath.Set(tools);
			PathJoin(Root, "home", Probe.Home);
			Probe.Toolchains.Set(Toolchains);
		}

		public ~this()
		{
			RemoveDirectoryRecursive(Root);
		}

		/// An engine manager over the bench, the engine at `own` its own; the releases on loopback,
		/// each file of a release at /<tag>/<file>.
		public EngineManager Make(StringView own = default)
		{
			let config = new EngineManagerConfig();
			let client = Client;
			let server = Server;
			config.Http = new [=client] () => client;
			let list = server.Url("/releases.json", .. new .());
			config.ReleasesUrl = new [=list] (outUrl) => { outUrl.Set(list); } ~ delete list;
			config.AssetUrl = new [=server] (tag, file, published, outUrl) => { server.Url(scope $"/{tag}/{file}", outUrl); };
			config.SdksDirectory.Set(Sdks);
			config.ToolchainsDirectory.Set(Toolchains);
			config.OwnSdk.Set(own);
			config.Probe = Probe;
			return new EngineManager(config, Registry, Projects);
		}

		/// A packed engine at `root` of `version` and `label`, naming the toolchain `beef`.
		public static void PackedEngine(StringView root, StringView version, StringView label, StringView beef = default)
		{
			let display = scope String(version);
			if (!label.IsEmpty)
				display.AppendF("-{}", label);
			let info = scope String();
			info.AppendF("{{\"version\": \"{}\", \"label\": \"{}\", \"display\": \"{}\", \"buildNumber\": 1, \"platform\": \"{}\", \"beef\": \"{}\"}}\n", version,
				label, display, BuildLayout.HostPlatformName, beef);
			ProjectBuildBed.WriteSdk(root, info);
		}

		/// A checkout at `root` of `version`, labelled dev: no sdk.json, its version file instead.
		public static void Checkout(StringView root, StringView version)
		{
			ProjectBuildBed.WriteSdk(root);
			let source = scope String();
			source.AppendF("static class EngineVersion\n{{\n\tpublic const String String = \"{}\";\n\tpublic const String Label = \"dev\";\n}}\n", version);
			ProjectBuildBed.Write(root, SdkInfo.cVersionFile, source);
		}

		/// A project at `dir` named `name`, stamped `stamp`, on the recent list.
		public void AddProject(StringView dir, StringView name, StringView stamp)
		{
			let manifest = scope String();
			manifest.AppendF("<root>\n\t<object>\n\t\t<string name=\"name\">{}</string>\n\t\t<string name=\"engineVersion\">{}</string>\n\t</object>\n</root>\n", name,
				stamp);
			ProjectBuildBed.Write(dir, ProjectLayout.ManifestFile, manifest);
			ProjectRegistry.TouchRecentProject(Store, dir, name, stamp);
		}

		/// The release v0.2.0-beta on loopback, offering the fixture engine with the digest
		/// `digest` (empty: the zip's own) for the archive `archive` (the fixture engine's zip unless
		/// told otherwise), and the toolchain from release v0.1.0; and a release with no engine, and
		/// a draft.
		public void Release(StringView digest = default, Span<uint8> archive = default)
		{
			let index = EngineReleases.IndexFile(.. scope .());
			let zipName = scope $"sedulous-sdk-{cOfferedDisplay}-test.zip";
			let toolchainName = scope $"beef-{cPin}-test.zip";
			let releases = scope String();
			releases.AppendF("""
				[{{"tag_name": "v{0}", "draft": false, "prerelease": true,
				  "assets": [{{"name": "{1}", "browser_download_url": "", "size": 300}},
				             {{"name": "{2}", "browser_download_url": "", "size": {3}}}]}},
				 {{"tag_name": "v0.1.0", "draft": false, "prerelease": false,
				  "assets": [{{"name": "samples.json", "browser_download_url": "", "size": 10}}]}},
				 {{"tag_name": "v0.3.0", "draft": true, "assets": [{{"name": "{1}", "browser_download_url": "", "size": 300}}]}}]
				""", cOfferedDisplay, index, zipName, SdkZip.Count);
			Server.Serve("/releases.json", releases);
			let sha = scope String(digest);
			let served = (archive.Length > 0) ? archive : Span<uint8>(SdkZip.Ptr, SdkZip.Count);
			if (sha.IsEmpty)
				Sha256.Of(served).ToHex(sha);
			let toolchainSha = Sha256.Of(ToolchainZip).ToHex(.. scope .());
			let indexText = scope String();
			indexText.AppendF("""
				{{"version": "{0}", "label": "beta", "display": "{1}", "platform": "{2}",
				 "archive": "{3}", "sha256": "{4}", "size": {5}, "unpackedSize": 4096, "beef": "{6}",
				 "toolchain": {{"archive": "{7}", "sha256": "{8}", "size": {9}, "release": "v0.1.0"}}}}
				""", cOfferedVersion, cOfferedDisplay, BuildLayout.HostPlatformName, zipName, sha, served.Length, cPin, toolchainName, toolchainSha,
				ToolchainZip.Count);
			Server.Serve(scope $"/v{cOfferedDisplay}/{index}", indexText);
			Server.Serve(scope $"/v{cOfferedDisplay}/{zipName}", served);
			Server.Serve(scope $"/v0.1.0/{toolchainName}", ToolchainZip);
		}

		/// Frames until `done` says so: the server, the client, then the manager's Tick.
		public void Run(EngineManager engines, delegate bool() done)
		{
			for (int i < 10000)
			{
				Server.Pump();
				Client.Pump();
				engines.Tick();
				if (done())
					return;
				Thread.Sleep(1);
			}
			Test.FatalError("it did not end");
		}

		/// The engine the releases offer, fetched.
		public AvailableEngine Offered(EngineManager engines)
		{
			engines.FetchAvailable();
			Run(engines, scope () => engines.AvailableState != .Fetching);
			Test.Assert(engines.AvailableState == .Loaded, scope String(engines.AvailableError));
			Test.Assert(engines.Available.Count == 1, "one release offers an engine");
			return engines.Available[0];
		}
	}

	/// The engines listed, in the list's order, each with how it was listed (one installed into the
	/// managed folder, a checkout, a folder added by hand, one gone), the one the manager runs from
	/// marked; the projects that open with each, by pin or by their stamp; a folder that holds no
	/// engine refused. Then what the releases offer for this platform: a release with no engine and a
	/// draft passed by, the one with an engine read from its index.
	[Test]
	public static void TheEnginesListedWithHowEachWasListedTheProjectsThatOpenWithThemAndWhatTheReleasesOffer()
	{
		let bench = scope Bench("scratch_engines_list");
		let installed = PathJoin(bench.Sdks, "0.1.0-Linux64", .. scope .());
		Bench.PackedEngine(installed, "0.1.0", "");
		let checkout = PathJoin(bench.Root, "checkout", .. scope .());
		Bench.Checkout(checkout, "0.1.0");
		let unpacked = PathJoin(bench.Root, "unpacked", .. scope .());
		Bench.PackedEngine(unpacked, "0.0.9", "");
		let gone = PathJoin(bench.Root, "gone", .. scope .());
		Bench.PackedEngine(gone, "0.0.8", "");
		Test.Assert(bench.Registry.Register(installed, true) case .Ok);
		Test.Assert(bench.Registry.Register(checkout) case .Ok);
		Test.Assert(bench.Registry.Register(gone) case .Ok);
		RemoveDirectoryRecursive(gone);
		// Harbour is pinned to the checkout; Tide, stamped 0.1.0, is given the packed engine of its
		// version before the checkout.
		let harbour = PathJoin(bench.Root, "Harbour", .. scope .());
		let tide = PathJoin(bench.Root, "Tide", .. scope .());
		bench.AddProject(harbour, "Harbour", "0.1.0");
		bench.AddProject(tide, "Tide", "0.1.0");
		Test.Assert(bench.Registry.Pin(harbour, checkout) case .Ok);

		let engines = bench.Make(checkout);
		defer delete engines;
		engines.ReadInstalled();
		let listed = engines.Installed;
		Test.Assert(listed.Count == 3);
		Test.Assert((listed[0].Root == installed) && (listed[0].Kind == .Installed) && !listed[0].Own && (listed[0].Info.Display == "0.1.0"));
		Test.Assert((listed[0].Projects.Count == 1) && (listed[0].Projects[0] == "Tide"), "by its stamp");
		Test.Assert((listed[1].Root == checkout) && (listed[1].Kind == .Checkout) && listed[1].Own);
		Test.Assert((listed[1].Projects.Count == 1) && (listed[1].Projects[0] == "Harbour") && (listed[1].ProjectPaths[0] == harbour), "by its pin");
		Test.Assert((listed[2].Root == gone) && listed[2].Missing && listed[2].Projects.IsEmpty);
		Test.Assert(listed[2].Name(.. scope .()) == "gone");
		Test.Assert(listed[0].Name(.. scope .()) == "Engine 0.1.0");

		let why = scope String();
		Test.Assert(!engines.AddFolder(bench.Root, why) && why.Contains("is not an engine"), why);
		Test.Assert(engines.AddFolder(scope $"{unpacked}/", why..Clear()), why);
		let added = engines.Find(unpacked);
		Test.Assert((added != null) && (added.Kind == .Folder) && (added.Info.Display == "0.0.9"));
		Test.Assert(engines.Message == scope $"Engine 0.0.9 at {unpacked} is listed.", scope String(engines.Message));

		bench.Release();
		let offered = bench.Offered(engines);
		Test.Assert((offered.Tag == scope $"v{cOfferedDisplay}") && (offered.Version == cOfferedVersion) && (offered.Display == cOfferedDisplay));
		Test.Assert((offered.Label == "beta") && (offered.Platform == BuildLayout.HostPlatformName) && (offered.Beef == cPin));
		Test.Assert((offered.Size == (uint64)bench.SdkZip.Count) && (offered.UnpackedSize == 4096));
		Test.Assert((offered.ToolchainRelease == "v0.1.0") && (offered.ToolchainSize == (uint64)bench.ToolchainZip.Count));
		let url = bench.Server.Url(scope $"/v{cOfferedDisplay}/{offered.Archive}", .. scope .());
		Test.Assert(offered.ArchiveUrl == url, offered.ArchiveUrl);
		Test.Assert(!engines.IsInstalled(offered));
	}

	/// Install: the engine's zip downloaded, its digest checked, unpacked into the managed folder
	/// (<display>-<platform>) and listed as installed; it is then installed for the list of what is
	/// offered, and a second install finds its folder taken.
	[Test]
	public static void AVerifiedInstallUnpacksTheEngineIntoTheManagedFolderAndListsIt()
	{
		let bench = scope Bench("scratch_engines_install");
		bench.Release();
		let engines = bench.Make();
		defer delete engines;
		let offered = bench.Offered(engines);
		let why = scope String();
		Test.Assert(engines.Install(offered, why), why);
		Test.Assert(engines.InstallOf(cOfferedDisplay) != null);
		Test.Assert(!engines.Install(offered, why..Clear()) && why.Contains("being installed"), why);
		bench.Run(engines, scope () => engines.InstallOf(cOfferedDisplay) == null);

		let target = PathJoin(bench.Sdks, scope $"{cOfferedDisplay}-{BuildLayout.HostPlatformName}", .. scope .());
		Test.Assert(!engines.MessageIsProblem && (engines.Message == scope $"Engine {cOfferedDisplay} is installed, in {target}."), scope String(engines.Message));
		let info = scope SdkInfo();
		Test.Assert(SdkInfo.Read(target, info) case .Ok);
		Test.Assert((info.Display == cOfferedDisplay) && (info.Beef == cPin));
		Test.Assert(FileExists(PathJoin(target, "ProjectManager/Sedulous.Tools.ProjectManager", .. scope .())));
		let listed = engines.Find(target);
		Test.Assert((listed != null) && (listed.Kind == .Installed));
		Test.Assert(engines.IsInstalled(offered));
		Test.Assert(!engines.Install(offered, why..Clear()) && why.Contains("is there already"), why);
	}

	/// A zip whose digest is not the index's is refused, and an archive with the right digest that
	/// holds no engine is refused once unpacked: either way nothing is kept, neither the folder nor
	/// the download beside it, and nothing is listed.
	[Test]
	public static void ABadDigestOrAnArchiveWithNoEngineIsRefusedAndLeavesNothing()
	{
		let bench = scope Bench("scratch_engines_refused");
		let target = PathJoin(bench.Sdks, scope $"{cOfferedDisplay}-{BuildLayout.HostPlatformName}", .. scope .());
		let partial = PathJoin(bench.Sdks, scope $".{cOfferedDisplay}-{BuildLayout.HostPlatformName}.download", .. scope .());
		bench.Release("0000000000000000000000000000000000000000000000000000000000000000");
		{
			let engines = bench.Make();
			defer delete engines;
			let offered = bench.Offered(engines);
			let why = scope String();
			Test.Assert(engines.Install(offered, why), why);
			bench.Run(engines, scope () => engines.InstallOf(cOfferedDisplay) == null);
			Test.Assert(engines.MessageIsProblem && engines.Message.Contains("checksum"), scope String(engines.Message));
			Test.Assert(!DirectoryExists(target) && !FileExists(partial), "nothing kept");
			Test.Assert(engines.Installed.IsEmpty, "nothing listed");
		}

		// The toolchain's zip, with its own digest: it unpacks, and is no engine.
		let other = scope Bench("scratch_engines_refused_other");
		let otherTarget = PathJoin(other.Sdks, scope $"{cOfferedDisplay}-{BuildLayout.HostPlatformName}", .. scope .());
		other.Release(default, other.ToolchainZip);
		let engines = other.Make();
		defer delete engines;
		let offered = other.Offered(engines);
		let why = scope String();
		Test.Assert(engines.Install(offered, why), why);
		other.Run(engines, scope () => engines.InstallOf(cOfferedDisplay) == null);
		Test.Assert(engines.MessageIsProblem && engines.Message.Contains("holds no engine"), scope String(engines.Message));
		Test.Assert(!DirectoryExists(otherTarget), "nothing kept");
		Test.Assert(engines.Installed.IsEmpty, "nothing listed");
	}

	/// Remove asks first, naming the projects that open with the engine; then an installed engine's
	/// folder is deleted, and the pins to it taken away; a folder added by hand is only taken off the
	/// list, its files kept; the engine the manager runs from is never removed.
	[Test]
	public static void RemoveNamesTheProjectsThatOpenWithItDeletesAnInstalledEnginesFolderAndOnlyUnlistsAFolder()
	{
		let bench = scope Bench("scratch_engines_remove");
		let installed = PathJoin(bench.Sdks, "0.1.0-Linux64", .. scope .());
		Bench.PackedEngine(installed, "0.1.0", "");
		let folder = PathJoin(bench.Root, "unpacked", .. scope .());
		Bench.PackedEngine(folder, "0.0.9", "");
		let own = PathJoin(bench.Root, "own", .. scope .());
		Bench.PackedEngine(own, "0.0.7", "");
		Test.Assert(bench.Registry.Register(installed, true) case .Ok);
		Test.Assert(bench.Registry.Register(folder) case .Ok);
		Test.Assert(bench.Registry.Register(own) case .Ok);
		let harbour = PathJoin(bench.Root, "Harbour", .. scope .());
		let tide = PathJoin(bench.Root, "Tide", .. scope .());
		bench.AddProject(harbour, "Harbour", "0.0.5");
		bench.AddProject(tide, "Tide", "0.0.5");
		Test.Assert(bench.Registry.Pin(harbour, installed) case .Ok);
		Test.Assert(bench.Registry.Pin(tide, installed) case .Ok);

		let engines = bench.Make(own);
		defer delete engines;
		engines.ReadInstalled();
		let title = scope String();
		let body = scope String();
		Test.Assert(engines.RemovalQuestion(installed, title, body));
		Test.Assert(title == "Remove Engine 0.1.0?", title);
		Test.Assert(body.StartsWith(scope $"Its folder, {installed}, is deleted."), body);
		Test.Assert(body.Contains("These projects open with it: Tide, Harbour."), body);
		Test.Assert(engines.RemovalQuestion(folder, title..Clear(), body..Clear()));
		Test.Assert(body == scope $"{folder} is taken off the list; its files are not touched. No project you have listed opens with it.", body);

		let why = scope String();
		Test.Assert(!engines.Remove(own, why) && why.Contains("This manager runs from that engine"), why);
		Test.Assert(engines.Remove(installed, why..Clear()), why);
		Test.Assert(!DirectoryExists(installed), "its folder deleted");
		Test.Assert(engines.Find(installed) == null, "unlisted");
		let pinned = scope String();
		Test.Assert(!bench.Registry.PinOf(harbour, pinned) && !bench.Registry.PinOf(tide, pinned), "the pins to it gone");
		Test.Assert(engines.Message == "Engine 0.1.0 was removed, and its folder deleted.", scope String(engines.Message));

		Test.Assert(engines.Remove(folder, why..Clear()), why);
		Test.Assert(ProjectBuild.IsSdk(folder), "a folder's files are kept");
		Test.Assert(engines.Find(folder) == null);
		Test.Assert((engines.Installed.Count == 1) && (engines.Installed[0].Root == own));
		Test.Assert(!engines.Remove(folder, why..Clear()) && (why == "That engine is not listed."), why);
	}

#if BF_PLATFORM_LINUX
	/// The toolchain an engine names (its pin) is installed from the index of the engine's release,
	/// the zip from the release that carries it, into the managed folder by its pin, where the check
	/// finds it as the managed toolchain; Emscripten's folder is then written into its settings, a
	/// folder with no emcc refused; a BeefBuild of the user's own is only told what to set.
	[Test]
	public static void TheToolchainAnEngineNamesInstallsFromItsReleaseAndEmscriptenIsWrittenIntoIt()
	{
		let bench = scope Bench("scratch_engines_toolchain");
		bench.Release();
		let sdkRoot = PathJoin(bench.Root, "sdk", .. scope .());
		Bench.PackedEngine(sdkRoot, cOfferedVersion, "beta", cPin);
		let sdk = scope SdkInfo();
		Test.Assert(SdkInfo.Read(sdkRoot, sdk) case .Ok);
		bench.Probe.Runner = new (executable, arguments, onLine, cancelled) =>
			{
				onLine(scope $"BeefBuild {cPin}");
				return .Ok(0);
			};
		defer delete bench.Probe.Runner;
		let engines = bench.Make();
		defer delete engines;

		let report = scope ToolchainReport();
		engines.CheckToolchain(sdk, report);
		Test.Assert(report.Get(.BeefBuild).State == .Missing);
		Test.Assert(!engines.HasToolchain(cPin));
		let why = scope String();
		Test.Assert(engines.InstallToolchain(sdk, why), why);
		Test.Assert(engines.InstallingToolchain);
		Test.Assert(!engines.InstallToolchain(sdk, why..Clear()) && (why == "A toolchain is being installed already."), why);
		bench.Run(engines, scope () => !engines.InstallingToolchain);
		Test.Assert(!engines.MessageIsProblem, scope String(engines.Message));
		Test.Assert(engines.HasToolchain(cPin));
		Test.Assert(!engines.InstallToolchain(sdk, why..Clear()) && why.Contains("installed already"), why);

		engines.CheckToolchain(sdk, report);
		let beefBuild = report.Get(.BeefBuild);
		Test.Assert((beefBuild.State == .Ok) && report.Managed, scope String(beefBuild.Detail));
		Test.Assert(report.BeefBuild == PathJoin(bench.Toolchains, scope $"{cPin}/bin/BeefBuild", .. scope .()), report.BeefBuild);
		Test.Assert(report.Get(.Emscripten).State == .Missing);

		let emsdk = PathJoin(bench.Root, "emsdk", .. scope .());
		Test.Assert(!engines.SetEmscripten(report, emsdk, why..Clear()) && why.Contains("holds no"), why);
		ProjectBuildBed.Write(emsdk, ProjectBuild.cEmccPath, "#!emcc\n");
		Test.Assert(engines.SetEmscripten(report, emsdk, why..Clear()), why);
		let found = scope String();
		Test.Assert(ProjectBuild.FindEmscriptenFrom(report.BeefBuild, bench.Probe.Home, found, why..Clear()) && (found == emsdk), why);
		engines.CheckToolchain(sdk, report);
		Test.Assert(report.Get(.Emscripten).State == .Ok);

		report.Managed = false; // the user's own Beef: told what to set, nothing written
		Test.Assert(!engines.SetEmscripten(report, emsdk, why..Clear()) && why.Contains("is your own Beef"), why);
	}
#endif

	/// The Engines and Toolchain tabs show with an engine manager alone. Engines lays out a row per
	/// engine listed and says where the releases' list stands (asking, then why it failed);
	/// Toolchain lists the engines that read, the newest picked, with a line per need and Install
	/// for the toolchain it names. A host without one shows neither tab, and Projects stands in.
	[Test]
	public static void TheEnginesAndToolchainTabsShowWithAnEngineManagerAlone()
	{
		let bench = scope Bench("scratch_engines_tabs");
		let installed = PathJoin(bench.Sdks, "0.1.0-Linux64", .. scope .());
		Bench.PackedEngine(installed, "0.1.0", "", cPin);
		let checkout = PathJoin(bench.Root, "checkout", .. scope .());
		Bench.Checkout(checkout, "0.1.0");
		Test.Assert(bench.Registry.Register(checkout) case .Ok);
		Test.Assert(bench.Registry.Register(installed, true) case .Ok);
		let engines = bench.Make();
		defer delete engines;

		let context = new GUIContext();
		let scene = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		defer scene.ReleaseRef();
		scene.Size = .(1280.0f, 800.0f);
		let services = new ProjectManagerServices();
		services.Controller = bench.Projects;
		services.LoadMarkup = new (path) => EditorData.LoadMarkup(path);
		services.EngineManager = engines;
		let view = new ProjectManagerView(services, EditorData.LoadMarkup(ProjectManagerView.cMarkupPath));
		defer delete view;
		scene.AddChild(view.Content);
		let content = view.Content;
		Test.Assert(content.FindElement("manager-tab-engines").Displayed && content.FindElement("manager-tab-toolchain").Displayed);
		Test.Assert(!content.FindElement("manager-engines-page").Displayed, "Projects first");

		view.ShowPage(.Engines);
		Test.Assert((view.Page == .Engines) && content.FindElement("manager-engines-page").Displayed);
		Test.Assert(!content.FindElement("manager-projects-page").Displayed && !content.FindElement("manager-welcome").Displayed);
		Test.Assert(content.FindElement("manager-engines-installed").ChildCount == 2);
		let state = content.FindElement("manager-engines-available-state") as Sedulous.GUI.Label;
		Test.Assert(state.Text == "Asking the releases...", scope String(state.Text));
		bench.Run(engines, scope () => engines.AvailableState != .Fetching); // nothing served: a 404
		view.Tick();
		scene.MutationQueue.Drain();
		Test.Assert(state.Text == "The releases were not reached: the releases answered 404.", scope String(state.Text));

		view.ShowPage(.Toolchain);
		Test.Assert(content.FindElement("manager-toolchain-page").Displayed && !content.FindElement("manager-engines-page").Displayed);
		let picker = content.FindElement("manager-toolchain-engine") as Sedulous.GUI.ComboBox;
		Test.Assert(picker.ItemCount == 2);
		Test.Assert(picker.SelectedIndex == 0, "the packed engine before the checkout of its version");
		Test.Assert(content.FindElement("manager-toolchain-lines").ChildCount == view.ToolchainTab.Report.Lines.Count);
		Test.Assert(view.ToolchainTab.Report.Get(.BeefBuild).State == .Missing);
		let install = content.FindElement("manager-toolchain-install") as Sedulous.GUI.Button;
		Test.Assert(install.Displayed && (install.Text == scope $"Install Toolchain {cPin}"), scope String(install.Text));

		// Without an engine manager: neither tab, and Projects stands in.
		let plain = new ProjectManagerServices();
		plain.Controller = bench.Projects;
		let other = scope ProjectManagerView(plain, EditorData.LoadMarkup(ProjectManagerView.cMarkupPath));
		Test.Assert(!other.Content.FindElement("manager-tab-engines").Displayed && !other.Content.FindElement("manager-tab-toolchain").Displayed);
		other.ShowPage(.Engines);
		Test.Assert(other.Page == .Projects);
		Test.Assert(!other.Content.FindElement("manager-engines-page").Displayed);
	}
}
