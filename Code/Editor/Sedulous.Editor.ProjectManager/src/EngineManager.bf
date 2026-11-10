using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Http;
using Sedulous.Http.Client;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;
using internal Sedulous.Editor.Project;

namespace Sedulous.Editor.ProjectManager;

/// How a listed engine came to be listed, which says what Remove does with it.
enum EngineKind
{
	/// The manager installed it into its own folder: Remove deletes the folder.
	Installed,
	/// A folder the user listed (an engine unpacked by hand): Remove only unlists it.
	Folder,
	/// A source checkout (no sdk.json): Remove only unlists it.
	Checkout
}

/// An engine the SDK registry lists, as the Engines page shows it.
class InstalledEngine
{
	/// Its root, absolute.
	public String Root = new .() ~ delete _;
	/// What it says of itself; null when it is missing (its folder gone, or no longer an engine).
	public SdkInfo Info ~ delete _;
	public EngineKind Kind;
	/// The engine the manager runs from, which it does not remove.
	public bool Own;
	/// The projects that open with it (pinned to it, or given it for their stamp), by name, and their
	/// folders in the same order.
	public List<String> Projects = new .() ~ DeleteContainerAndItems!(_);
	public List<String> ProjectPaths = new .() ~ DeleteContainerAndItems!(_);

	public bool Missing => Info == null;

	/// How the page names it: "Engine 0.2.0-beta", or its folder's name when it is missing.
	public void Name(String outName)
	{
		if (Info != null)
			outName.AppendF("Engine {}", Info.Display);
		else
			PathFilename(Root, outName);
	}

	/// The word for `kind`, as the page and a project's menu say it.
	public static StringView KindName(EngineKind kind)
	{
		if (kind == .Installed)
			return "installed";
		return (kind == .Folder) ? "folder" : "checkout";
	}
}

/// What an EngineManager works over; empty paths are the user's own (ResolveUserPaths).
class EngineManagerConfig
{
	/// The client releases are fetched with, made on first use; null: none, and nothing is fetched.
	/// Owned.
	public delegate IHttpClient() Http ~ delete _;
	/// Where the list of releases is read; null: GitHub's list of the engine repository's releases.
	/// Owned.
	public delegate void(String outUrl) ReleasesUrl ~ delete _;
	/// Where the file `file` of the release tagged `tag` is fetched from, given the URL the releases
	/// list published for it (empty when it gave none); null: that URL, else the release's download
	/// URL. Owned.
	public delegate void(StringView tag, StringView file, StringView published, String outUrl) AssetUrl ~ delete _;
	/// Where engines are installed, each in <display>-<platform> (SdkRegistry.ManagedDirectory).
	public String SdksDirectory = new .() ~ delete _;
	/// Where toolchains are installed, each in the folder its pin names (<user-data>/Sedulous/Toolchains).
	public String ToolchainsDirectory = new .() ~ delete _;
	/// The engine the manager runs from, which is never removed; empty: none.
	public String OwnSdk = new .() ~ delete _;
	/// What the toolchain check reads of its surroundings, BORROWED; null: this process's.
	public ToolchainProbe Probe = null;

	public void ResolveUserPaths()
	{
		if (SdksDirectory.IsEmpty)
			SdkRegistry.ManagedDirectory(SdksDirectory);
		if (ToolchainsDirectory.IsEmpty)
			PathJoin(GetUserDataDirectory(.. scope .()), ProjectBuild.cToolchainsDir, ToolchainsDirectory);
	}
}

/// The engines side by side, for the project manager's Engines and Toolchain pages:
/// - the engines the SDK registry lists (ReadInstalled), each with how it was listed and the
///   projects that open with it;
/// - the engines the releases offer for this platform (FetchAvailable: the releases list, then
///   each release's index), fetched when asked, never on a timer, the last answer kept;
/// - Install, the engine's zip downloaded, checked against the index's SHA-256 and unpacked with
///   its files' modes into the managed folder, then listed; a failed, refused or cancelled install
///   keeps nothing;
/// - Add Folder (a checkout, or an engine unpacked by hand) and Remove (an installed engine's folder
///   deleted, any other only unlisted; the pins to it taken away);
/// - the toolchain check over an engine, the toolchain its pin names installed from the release's
///   index the same way, and Emscripten's folder written into that toolchain's settings.
/// Downloads run inside the HTTP client's Pump, which the caller drives; Tick settles the ones that
/// ended. What it has to say goes to Message, counted by MessageSerial; a change a page shows
/// counts ChangeSerial.
class EngineManager
{
	/// Where a list stands.
	public enum ListState : uint8
	{
		NotFetched,
		Fetching,
		Loaded,
		/// The releases were not reached, or answered with nothing readable: AvailableError says why.
		Failed,
	}

	/// An engine's install under way.
	private class SdkInstall
	{
		public AvailableEngine Engine = new .() ~ delete _;
		/// Deleted, it cancels itself and deletes what it wrote.
		public ReleaseDownload Download ~ delete _;
	}

	/// A toolchain's install under way: its release's index fetched first, then its zip.
	private class ToolchainInstall
	{
		public String Pin = new .() ~ delete _;
		/// The display of the engine whose release names it.
		public String Display = new .() ~ delete _;
		public String Target = new .() ~ delete _;
		public uint64 IndexRequest = 0;
		/// Null while the index is fetched.
		public ReleaseDownload Download ~ delete _;
	}

	private EngineManagerConfig mConfig ~ delete _;
	/// BORROWED, both.
	private SdkRegistry mRegistry;
	private ProjectManagerController mProjects;
	/// BORROWED, made on first use through the config.
	private IHttpClient mClient = null;
	private List<InstalledEngine> mInstalled = new .() ~ DeleteContainerAndItems!(_);
	private List<AvailableEngine> mAvailable = new .() ~ DeleteContainerAndItems!(_);
	private List<EngineRelease> mReleases = new .() ~ DeleteContainerAndItems!(_);
	private ListState mAvailableState = .NotFetched;
	private String mAvailableError = new .() ~ delete _;
	private uint64 mListRequest = 0;
	private List<uint64> mIndexRequests = new .() ~ delete _;
	private int mPendingIndexes = 0;
	/// Each holds its download's callbacks, so it goes before the client.
	private List<SdkInstall> mInstalls = new .() ~ DeleteContainerAndItems!(_);
	private ToolchainInstall mToolchain = null ~ delete _;
	private String mMessage = new .() ~ delete _;
	private bool mMessageProblem = false;
	private int mMessageSerial = 0;
	private int mChangeSerial = 0;

	/// TAKES OWNERSHIP of `config` (its empty paths become the user's); `registry` and `projects`
	/// (the recent list, for the projects that open with each engine; null: none) are borrowed.
	public this(EngineManagerConfig config, SdkRegistry registry, ProjectManagerController projects)
	{
		mConfig = config;
		mConfig.ResolveUserPaths();
		mRegistry = registry;
		mProjects = projects;
	}

	public ~this()
	{
		// The requests that would answer into this are dropped; the downloads cancel themselves as
		// they go, each deleting what it wrote.
		if (mClient != null)
		{
			if (mListRequest != 0)
				mClient.Cancel(mListRequest);
			for (let id in mIndexRequests)
				mClient.Cancel(id);
			if ((mToolchain != null) && (mToolchain.IndexRequest != 0))
				mClient.Cancel(mToolchain.IndexRequest);
		}
	}

	/// The listed engines as ReadInstalled last read them, in the list's order.
	public List<InstalledEngine> Installed => mInstalled;
	/// The engines the releases offer, newest first, as FetchAvailable last found them.
	public List<AvailableEngine> Available => mAvailable;
	public ListState AvailableState => mAvailableState;
	public StringView AvailableError => mAvailableError;
	public StringView SdksDirectory => mConfig.SdksDirectory;
	public StringView ToolchainsDirectory => mConfig.ToolchainsDirectory;
	/// What it said last, whether that is a problem, and how many times it has spoken.
	public StringView Message => mMessage;
	public bool MessageIsProblem => mMessageProblem;
	public int MessageSerial => mMessageSerial;
	/// Counts each change of what the pages show.
	public int ChangeSerial => mChangeSerial;

	/// The listed engine at `root`, as ReadInstalled last read it; null when none is.
	public InstalledEngine Find(StringView root)
	{
		let absolute = ProjectBuild.Absolute(root, .. scope .());
		for (let engine in mInstalled)
			if (engine.Root == absolute)
				return engine;
		return null;
	}

	/// The registry read again into Installed: each engine with how it was listed and the projects
	/// that open with it.
	public void ReadInstalled()
	{
		ClearAndDeleteItems!(mInstalled);
		mChangeSerial++;
		let listed = scope List<ListedSdk>();
		defer { ClearAndDeleteItems!(listed); }
		if (!mRegistry.ReadListed(listed))
		{
			Say(scope $"The list of engines, {mRegistry.Path}, does not read: it is left as it is.", true);
			return;
		}
		let own = ProjectBuild.Absolute(mConfig.OwnSdk, .. scope .());
		for (let entry in listed)
		{
			let engine = new InstalledEngine();
			engine.Root.Set(entry.Root);
			engine.Info = entry.Info;
			entry.Info = null; // the engine's now
			if ((engine.Info != null) && engine.Info.IsCheckout)
				engine.Kind = .Checkout;
			else
				engine.Kind = (entry.Managed && IsUnder(engine.Root, mConfig.SdksDirectory)) ? EngineKind.Installed : EngineKind.Folder;
			engine.Own = !own.IsEmpty && (engine.Root == own);
			FindProjects(engine);
			mInstalled.Add(engine);
		}
	}

	/// Whether an engine of `engine`'s version, label and platform is listed (installed, or an
	/// unpacked one listed as a folder).
	public bool IsInstalled(AvailableEngine engine)
	{
		for (let installed in mInstalled)
		{
			if ((installed.Info != null) && !installed.Info.IsCheckout && (installed.Info.Display == engine.Display)
				&& (installed.Info.Platform == engine.Platform))
				return true;
		}
		return false;
	}

	/// The engine at `folder` (a checkout, or an engine unpacked by hand) listed, as it was listed
	/// already when it is. False, with why in `outWhy`, when it is no engine.
	public bool AddFolder(StringView folder, String outWhy)
	{
		let root = ProjectBuild.Absolute(folder, .. scope .());
		let info = scope SdkInfo();
		if (SdkInfo.Read(root, info) case .Err)
		{
			outWhy.AppendF("{} is not an engine: an engine's folder holds Code/ with the engine's libraries (a checkout, or an engine unpacked).", root);
			return false;
		}
		if (mRegistry.Adopt(root) case .Err(let error))
		{
			outWhy.AppendF("The engine could not be listed in {} ({}).", mRegistry.Path, error);
			return false;
		}
		Say(scope $"Engine {info.Display} at {root} is listed.", false);
		ReadInstalled();
		return true;
	}

	/// What Remove asks before it removes the engine at `root`: what happens to its folder, and the
	/// projects that open with it by name. False when it is not listed.
	public bool RemovalQuestion(StringView root, String outTitle, String outBody)
	{
		let engine = Find(root);
		if (engine == null)
			return false;
		let name = engine.Name(.. scope .());
		outTitle.AppendF("Remove {}?", name);
		if (engine.Kind == .Installed)
			outBody.AppendF("Its folder, {}, is deleted.", engine.Root);
		else
			outBody.AppendF("{} is taken off the list; its files are not touched.", engine.Root);
		if (engine.Projects.IsEmpty)
		{
			outBody.Append(" No project you have listed opens with it.");
			return true;
		}
		outBody.Append((engine.Projects.Count == 1) ? " This project opens with it: " : " These projects open with it: ");
		for (let project in engine.Projects)
			outBody.AppendF("{}{}", (@project.Index == 0) ? "" : ", ", project);
		outBody.Append((engine.Projects.Count == 1) ? ". It will open with another engine of its version, or ask for one."
			: ". They will open with another engine of their version, or ask for one.");
		return true;
	}

	/// Removes the listed engine at `root`: an installed one's folder deleted, any other only
	/// unlisted, and the pins to it taken away. False, with why in `outWhy`, when it is not listed,
	/// it is the engine this manager runs from, it is being installed, or its folder cannot be
	/// deleted (it then stays listed).
	public bool Remove(StringView root, String outWhy)
	{
		ReadInstalled();
		let engine = Find(root);
		if (engine == null)
		{
			outWhy.Set("That engine is not listed.");
			return false;
		}
		if (engine.Own)
		{
			outWhy.Set("This manager runs from that engine: remove it from another engine's manager.");
			return false;
		}
		let name = engine.Name(.. scope .());
		let folder = scope String(engine.Root);
		let installed = engine.Kind == .Installed;
		for (let install in mInstalls)
		{
			if (install.Download.Target == folder)
			{
				outWhy.AppendF("{} is being installed: cancel it instead.", name);
				return false;
			}
		}
		if (installed)
		{
			RemoveDirectoryRecursive(folder);
			if (DirectoryExists(folder))
			{
				outWhy.AppendF("{}'s folder, {}, could not be deleted (is a file in it open?): it stays listed.", name, folder);
				return false;
			}
		}
		if (mRegistry.Unregister(folder) case .Err(let error))
		{
			outWhy.AppendF("{} could not be taken off the list in {} ({}).", name, mRegistry.Path, error);
			ReadInstalled();
			return false;
		}
		if (mRegistry.UnpinAll(folder) case .Err(let unpinError))
			GlobalLog(.Warning, "Engines: the pins to {} could not be taken away in {} ({})", folder, mRegistry.Path, unpinError);
		if (installed)
			Say(scope $"{name} was removed, and its folder deleted.", false);
		else
			Say(scope $"{name} was taken off the list; its files are untouched.", false);
		ReadInstalled();
		return true;
	}

	/// The releases list fetched, then each release's index for this platform: Available once all
	/// have answered (a release whose index does not read is passed by, and logged).
	public void FetchAvailable()
	{
		let client = Client();
		CancelFetches();
		ClearAndDeleteItems!(mAvailable);
		ClearAndDeleteItems!(mReleases);
		mAvailableError.Clear();
		mChangeSerial++;
		if (client == null)
		{
			mAvailableState = .Failed;
			mAvailableError.Set("this manager has no network client");
			return;
		}
		mAvailableState = .Fetching;
		let url = scope String();
		if (mConfig.ReleasesUrl != null)
			mConfig.ReleasesUrl(url);
		else
			EngineReleases.DefaultReleasesUrl(url);
		let request = HttpClientRequest.Get(url);
		request.Headers.Add(new HttpHeader("Accept", "application/vnd.github+json"));
		request.MaxResponseBytes = 8 * 1024 * 1024;
		mListRequest = client.Send(request, new (response) => { OnReleases(response); });
	}

	/// The download of the engine `display`'s install under way; null for none.
	public ReleaseDownload InstallOf(StringView display)
	{
		for (let install in mInstalls)
			if (install.Engine.Display == display)
				return install.Download;
		return null;
	}

	/// Installs `engine` into <SdksDirectory>/<display>-<platform>: its zip downloaded, checked and
	/// unpacked, then the engine read (it must say the index's version) and listed as installed.
	/// Tick settles it. False, with why in `outWhy`, when it cannot start: no client, one under way
	/// already, or something at that folder already.
	public bool Install(AvailableEngine engine, String outWhy)
	{
		let client = Client();
		if (client == null)
		{
			outWhy.Set("This manager has no network client.");
			return false;
		}
		if (InstallOf(engine.Display) != null)
		{
			outWhy.AppendF("Engine {} is being installed already.", engine.Display);
			return false;
		}
		let folder = scope $"{engine.Display}-{engine.Platform}";
		if (!SampleCatalog.PlainName(folder))
		{
			outWhy.AppendF("Engine {} names a folder this manager cannot make ({}).", engine.Display, folder);
			return false;
		}
		let target = PathJoin(mConfig.SdksDirectory, folder, .. scope .());
		if (Occupied(target))
		{
			outWhy.AppendF("{} is there already: remove it first, or list it with Add Folder.", target);
			return false;
		}
		if (!ProjectBuild.MakeDirectories(mConfig.SdksDirectory))
		{
			outWhy.AppendF("{} could not be made.", mConfig.SdksDirectory);
			return false;
		}
		let install = new SdkInstall();
		install.Engine.CopyFrom(engine);
		install.Download = new ReleaseDownload(client, engine.ArchiveUrl, engine.Sha256, engine.Size, target);
		mInstalls.Add(install);
		install.Download.Start();
		Say(scope $"Installing engine {engine.Display}...", false);
		mChangeSerial++;
		return true;
	}

	/// Stops the install of engine `display`: nothing it wrote is kept (Tick says so).
	public void CancelInstall(StringView display)
	{
		if (let download = InstallOf(display))
			download.Cancel();
	}

	/// Once a frame, after the client's Pump: the installs that ended settled (listed, or why not
	/// said, with nothing kept).
	public void Tick()
	{
		for (int i = mInstalls.Count - 1; i >= 0; i--)
		{
			let install = mInstalls[i];
			if (install.Download.State == .Downloading)
				continue;
			mInstalls.RemoveAt(i);
			Settle(install);
			delete install;
		}
		if ((mToolchain != null) && (mToolchain.Download != null) && (mToolchain.Download.State != .Downloading))
		{
			SettleToolchain(mToolchain);
			DeleteAndNullify!(mToolchain);
		}
	}

	/// The toolchain over the engine `sdk`, into `outReport` (Toolchain.Check over the config's
	/// probe).
	public void CheckToolchain(SdkInfo sdk, ToolchainReport outReport)
	{
		Toolchain.Check(sdk, outReport, mConfig.Probe);
	}

	/// Whether the toolchain `pin` names is installed (its BeefBuild where the managed install
	/// keeps it).
	public bool HasToolchain(StringView pin)
	{
		let beefBuild = scope String();
		return ProjectBuild.ManagedBeefBuildIn(mConfig.ToolchainsDirectory, pin, beefBuild);
	}

	/// A toolchain's install under way (its index fetched, or its zip downloaded).
	public bool InstallingToolchain => mToolchain != null;
	/// The download of the toolchain under way; null while its index is fetched, or with none.
	public ReleaseDownload ToolchainDownload => (mToolchain != null) ? mToolchain.Download : null;

	/// Installs the toolchain the engine `sdk` names (its pin) into <ToolchainsDirectory>/<pin>: the
	/// index of the engine's release read for the toolchain's zip and digest, then the zip
	/// downloaded, checked and unpacked; it must hold BeefBuild with corlib. Tick settles it. False,
	/// with why in `outWhy`, when it cannot start: the engine names none, it is there already, one
	/// is under way, or no client.
	public bool InstallToolchain(SdkInfo sdk, String outWhy)
	{
		if (sdk.Beef.IsEmpty)
		{
			outWhy.AppendF("Engine {} names no toolchain (a checkout builds with your own Beef): put BeefBuild on PATH, or set {}.", sdk.Display,
				ProjectBuild.cBeefBuildVariable);
			return false;
		}
		if (!SampleCatalog.PlainName(sdk.Beef))
		{
			outWhy.AppendF("Engine {} names a toolchain this manager cannot install ({}).", sdk.Display, sdk.Beef);
			return false;
		}
		if (HasToolchain(sdk.Beef))
		{
			outWhy.AppendF("The toolchain {} is installed already.", sdk.Beef);
			return false;
		}
		if (mToolchain != null)
		{
			outWhy.Set("A toolchain is being installed already.");
			return false;
		}
		let client = Client();
		if (client == null)
		{
			outWhy.Set("This manager has no network client.");
			return false;
		}
		let target = PathJoin(mConfig.ToolchainsDirectory, sdk.Beef, .. scope .());
		if (Occupied(target))
		{
			outWhy.AppendF("{} is there, without a BeefBuild: remove it first.", target);
			return false;
		}
		let install = new ToolchainInstall();
		install.Pin.Set(sdk.Beef);
		install.Display.Set(sdk.Display);
		install.Target.Set(target);
		mToolchain = install;
		let index = EngineReleases.IndexFile(.. scope .());
		let url = AssetUrl(scope $"v{sdk.Display}", index, "", .. scope .());
		let request = HttpClientRequest.Get(url);
		request.MaxResponseBytes = 1024 * 1024;
		install.IndexRequest = client.Send(request, new (response) => { OnToolchainIndex(response); });
		Say(scope $"Installing the toolchain {sdk.Beef}...", false);
		mChangeSerial++;
		return true;
	}

	/// Stops the toolchain's install: nothing it wrote is kept.
	public void CancelToolchain()
	{
		if (mToolchain == null)
			return;
		if (mToolchain.Download != null)
		{
			mToolchain.Download.Cancel(); // Tick says so
			return;
		}
		if ((mClient != null) && (mToolchain.IndexRequest != 0))
			mClient.Cancel(mToolchain.IndexRequest);
		Say(scope $"The toolchain {mToolchain.Pin}'s install was cancelled; nothing was kept.", false);
		DeleteAndNullify!(mToolchain);
		mChangeSerial++;
	}

	/// Points the toolchain `report` found at Emscripten in `folder` (an emsdk folder): written into
	/// the managed toolchain's own settings. A BeefBuild of the user's own is only told what to set,
	/// since a Beef packaged for the system reads another file. False, with why (or what to set) in
	/// `outWhy`, when nothing was written.
	public bool SetEmscripten(ToolchainReport report, StringView folder, String outWhy)
	{
		if (report.BeefBuild.IsEmpty)
		{
			outWhy.Set("There is no BeefBuild to tell: install the toolchain first.");
			return false;
		}
		let emsdk = ProjectBuild.Absolute(folder, .. scope .());
		let emcc = PathJoin(emsdk, BuildLayout.ExecutableName(ProjectBuild.cEmccPath, .. scope .()), .. scope .());
		if (emsdk.IsEmpty || !FileExists(emcc))
		{
			outWhy.AppendF("{} holds no {}: pick the emsdk folder Emscripten was installed into.", emsdk, ProjectBuild.cEmccPath);
			return false;
		}
		if (!report.Managed)
		{
			outWhy.AppendF("{} is your own Beef: set {} = \"{}\" under [{}] in its {} yourself.", report.BeefBuild, ProjectBuild.cEmscriptenKey, emsdk,
				ProjectBuild.cEmscriptenTable, ProjectBuild.cBeefSettingsFile);
			return false;
		}
		if (ProjectBuild.WriteEmscriptenPath(report.BeefBuild, emsdk) case .Err)
		{
			outWhy.AppendF("The toolchain's {} could not be written.", ProjectBuild.cBeefSettingsFile);
			return false;
		}
		Say(scope $"Web exports find Emscripten in {emsdk} now.", false);
		return true;
	}

	private IHttpClient Client()
	{
		if ((mClient == null) && (mConfig.Http != null))
			mClient = mConfig.Http();
		return mClient;
	}

	/// Where `file` of the release tagged `tag` is fetched from, `published` being the URL the
	/// releases list gave for it (empty: none).
	private void AssetUrl(StringView tag, StringView file, StringView published, String outUrl)
	{
		outUrl.Clear();
		if (mConfig.AssetUrl != null)
			mConfig.AssetUrl(tag, file, published, outUrl);
		else if (!published.IsEmpty)
			outUrl.Set(published);
		else
			EngineReleases.DownloadUrl(tag, file, outUrl);
	}

	private void Say(StringView text, bool problem)
	{
		mMessage.Set(text);
		mMessageProblem = problem;
		mMessageSerial++;
		if (problem)
			GlobalLog(.Warning, "Engines: {}", text);
		else
			GlobalLog(.Information, "Engines: {}", text);
	}

	/// The list's and the indexes' requests under way dropped.
	private void CancelFetches()
	{
		if (mClient == null)
			return;
		if (mListRequest != 0)
			mClient.Cancel(mListRequest);
		mListRequest = 0;
		for (let id in mIndexRequests)
			mClient.Cancel(id);
		mIndexRequests.Clear();
		mPendingIndexes = 0;
	}

	private void OnReleases(HttpClientResponse response)
	{
		mListRequest = 0;
		mChangeSerial++;
		if (!response.Ok || (response.Status != 200))
		{
			mAvailableState = .Failed;
			if (response.Ok)
				mAvailableError.AppendF("the releases answered {}", response.Status);
			else
				mAvailableError.Append(response.Error);
			return;
		}
		if (!EngineReleases.ParseReleases(response.BodyText, mReleases, mAvailableError))
		{
			mAvailableState = .Failed;
			return;
		}
		let index = EngineReleases.IndexFile(.. scope .());
		for (int i < mReleases.Count)
		{
			let asset = mReleases[i].Find(index);
			if (asset == null)
				continue; // no engine for this platform in it
			let request = HttpClientRequest.Get(AssetUrl(mReleases[i].Tag, index, asset.Url, .. scope .()));
			request.MaxResponseBytes = 1024 * 1024;
			let release = i;
			mPendingIndexes++;
			mIndexRequests.Add(mClient.Send(request, new [=this, =release] (answer) => { OnIndex(release, answer); }));
		}
		if (mPendingIndexes == 0)
			mAvailableState = .Loaded;
	}

	private void OnIndex(int release, HttpClientResponse response)
	{
		mPendingIndexes--;
		if (release < mReleases.Count)
		{
			let tag = mReleases[release].Tag;
			let engine = new AvailableEngine();
			let error = scope String();
			if (!response.Ok)
				error.AppendF("it was not reached: {}", response.Error);
			else if (response.Status != 200)
				error.AppendF("it answered {}", response.Status);
			else if (EngineReleases.ParseIndex(response.BodyText, engine, error))
			{
				engine.Tag.Set(tag);
				let archive = mReleases[release].Find(engine.Archive);
				AssetUrl(tag, engine.Archive, (archive != null) ? StringView(archive.Url) : StringView(), engine.ArchiveUrl);
				mAvailable.Add(engine);
			}
			if (!error.IsEmpty)
			{
				GlobalLog(.Warning, "Engines: release {}'s engine index is passed by: {}", tag, error);
				delete engine;
			}
		}
		if (mPendingIndexes > 0)
			return;
		mIndexRequests.Clear();
		mAvailable.Sort(scope (a, b) => EngineReleases.Newer(a, b) ? -1 : (EngineReleases.Newer(b, a) ? 1 : 0));
		mAvailableState = .Loaded;
		mChangeSerial++;
	}

	/// An engine's install that ended: checked and listed, or why not said, with nothing kept.
	private void Settle(SdkInstall install)
	{
		let engine = install.Engine;
		let download = install.Download;
		let target = scope String(download.Target);
		if (download.State == .Done)
		{
			let info = scope SdkInfo();
			if ((SdkInfo.Read(target, info) case .Err) || (info.Version != engine.Version))
			{
				RemoveDirectoryRecursive(target);
				Say(scope $"Engine {engine.Display}'s download holds no engine of that version: nothing was kept.", true);
			}
			else if (mRegistry.Register(target, true) case .Err(let error))
			{
				RemoveDirectoryRecursive(target);
				Say(scope $"Engine {engine.Display} could not be listed in {mRegistry.Path} ({error}): nothing was kept.", true);
			}
			else
				Say(scope $"Engine {engine.Display} is installed, in {target}.", false);
		}
		else if (download.State == .Failed)
			Say(scope $"Engine {engine.Display} did not install: {download.Error}.", true);
		else
			Say(scope $"Engine {engine.Display}'s install was cancelled; nothing was kept.", false);
		ReadInstalled();
	}

	private void OnToolchainIndex(HttpClientResponse response)
	{
		let install = mToolchain;
		if (install == null)
			return;
		install.IndexRequest = 0;
		mChangeSerial++;
		let engine = scope AvailableEngine();
		let error = scope String();
		if (!response.Ok)
			error.AppendF("the release was not reached: {}", response.Error);
		else if (response.Status == 404)
			error.AppendF("release v{} has no engine index for this platform", install.Display);
		else if (response.Status != 200)
			error.AppendF("the release answered {}", response.Status);
		else if (EngineReleases.ParseIndex(response.BodyText, engine, error)) // else why, in error
		{
			if ((engine.Beef != install.Pin) || engine.ToolchainArchive.IsEmpty)
				error.AppendF("release v{} offers no toolchain {}", install.Display, install.Pin);
			else if (!ProjectBuild.MakeDirectories(mConfig.ToolchainsDirectory))
				error.AppendF("{} could not be made", mConfig.ToolchainsDirectory);
		}
		if (!error.IsEmpty)
		{
			Say(scope $"The toolchain {install.Pin} did not install: {error}.", true);
			DeleteAndNullify!(mToolchain);
			return;
		}
		let tag = scope String();
		if (engine.ToolchainRelease.IsEmpty)
			tag.AppendF("v{}", install.Display);
		else
			tag.Set(engine.ToolchainRelease);
		let url = AssetUrl(tag, engine.ToolchainArchive, "", .. scope .());
		install.Download = new ReleaseDownload(mClient, url, engine.ToolchainSha256, engine.ToolchainSize, install.Target);
		install.Download.Start();
	}

	/// A toolchain's install that ended: checked (BeefBuild with corlib, where the managed install
	/// keeps it), or why not said, with nothing kept.
	private void SettleToolchain(ToolchainInstall install)
	{
		let download = install.Download;
		if (download.State == .Done)
		{
			let beefBuild = scope String();
			let why = scope String();
			if (ProjectBuild.ManagedBeefBuildIn(mConfig.ToolchainsDirectory, install.Pin, beefBuild) && ProjectBuild.HasCorlib(beefBuild, why))
				Say(scope $"The toolchain {install.Pin} is installed, in {install.Target}.", false);
			else
			{
				RemoveDirectoryRecursive(install.Target);
				Say(scope $"The toolchain {install.Pin}'s download holds no BeefBuild with its corlib: nothing was kept.", true);
			}
		}
		else if (download.State == .Failed)
			Say(scope $"The toolchain {install.Pin} did not install: {download.Error}.", true);
		else
			Say(scope $"The toolchain {install.Pin}'s install was cancelled; nothing was kept.", false);
		mChangeSerial++;
	}

	/// The projects that open with `engine` into its lists: each listed project pinned to it, or
	/// given it by the registry for its stamp (SdkRegistry.Pick), then any other project pinned to
	/// it.
	private void FindProjects(InstalledEngine engine)
	{
		let picked = scope String();
		let header = scope ProjectHeader();
		if (mProjects != null)
		{
			for (let entry in mProjects.Entries.Entries)
			{
				bool uses = mRegistry.PinOf(entry.Path, picked) && (picked == engine.Root);
				if (!uses && !engine.Missing && (ProjectHeader.Read(entry.Path, header) case .Ok))
					uses = mRegistry.Pick(entry.Path, header.EngineVersion, picked) && (picked == engine.Root);
				if (uses)
					AddProject(engine, entry.Path, entry.Name);
			}
		}
		let pinned = scope List<String>();
		defer { ClearAndDeleteItems!(pinned); }
		mRegistry.PinnedTo(engine.Root, pinned);
		for (let path in pinned)
			AddProject(engine, path, PathFilename(path, .. scope .()));
	}

	/// `path` among the engine's projects, once, as `name` (its folder's name when empty).
	private static void AddProject(InstalledEngine engine, StringView path, StringView name)
	{
		for (let known in engine.ProjectPaths)
			if (known == path)
				return;
		engine.ProjectPaths.Add(new .(path));
		if (name.IsEmpty)
			engine.Projects.Add(PathFilename(path, .. new .()));
		else
			engine.Projects.Add(new .(name));
	}

	/// Whether `path` is inside `folder` (both absolute).
	private static bool IsUnder(StringView path, StringView folder)
	{
		let parent = ProjectBuild.Absolute(folder, .. scope .());
		return !parent.IsEmpty && (path.Length > parent.Length + 1) && path.StartsWith(parent) && (path[parent.Length] == '/');
	}

	/// Something is at `path`: a file, or a folder that is not empty.
	private static bool Occupied(StringView path)
	{
		if (FileExists(path))
			return true;
		if (!DirectoryExists(path))
			return false;
		bool any = false;
		ListDirectory(path, scope [&](name, isDirectory) => { any = true; });
		return any;
	}
}
