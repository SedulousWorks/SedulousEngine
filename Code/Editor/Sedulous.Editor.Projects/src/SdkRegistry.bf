using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;
using Sedulous.Editor.Projects;
using internal Sedulous.Editor.Project;

namespace Sedulous.Editor.Project;

/// One SDK the registry lists, as SdkRegistry.ReadListed read it.
class ListedSdk
{
	/// Its root, absolute.
	public String Root = new .() ~ delete _;
	/// The manager installed it into its own folder, which it may delete.
	public bool Managed;
	/// What it says of itself; null when its folder is gone or no longer an SDK.
	public SdkInfo Info ~ delete _;
}

/// The SDKs this user has, and the one each project is pinned to: <user-data>/Sedulous/sdks.xml, a
/// settings store holding SdkRegistrySettings, in a file of its own so that a project manager and
/// the editors it starts, of any version, share it.
///
/// Nothing is kept between calls: each read reads the file, and each change reads it again just
/// before it writes (whole, through a temporary file moved over it), so a change made by another
/// process meanwhile is kept, and only a true race loses the other's last change. Each SDK it lists
/// is read again (SdkInfo.Read) when it is used: one whose folder is gone or no longer an SDK is
/// missing, not an error.
class SdkRegistry
{
	public const String cFileName = "sdks.xml";
	/// Under the user data folder: where the manager installs SDKs, each in <display>-<platform>.
	public const String cManagedDir = "SDKs";

	private String mPath = new .() ~ delete _;

	/// The registry kept in the file at `path` (DefaultPath for the user's own).
	public this(StringView path)
	{
		mPath.Set(path);
	}

	public StringView Path => mPath;

	/// The user's registry file, <user-data>/Sedulous/sdks.xml.
	public static void DefaultPath(String outPath)
	{
		PathJoin(GetUserDataDirectory(.. scope .()), cFileName, outPath);
	}

	/// Where the manager installs SDKs, <user-data>/Sedulous/SDKs.
	public static void ManagedDirectory(String outPath)
	{
		PathJoin(GetUserDataDirectory(.. scope .()), cManagedDir, outPath);
	}

	/// The file read into `outStore`, whose SdkRegistrySettings section is the registry; a file not
	/// there yet is an empty registry. Its sections resolve against this library's own types, so a
	/// host need not have registered them; one it does not know passes through a later save.
	public Result<void, ErrorCode> Load(Settings outStore)
	{
		if (!FileExists(mPath))
			return .Ok;
		let stream = scope FileStream(mPath, .Read);
		if (!stream.IsValid)
			return .Err(.NotFound);
		let factory = XmlSerializerFactory();
		defer delete factory;
		let types = scope SerializableRegistry();
		EditorProjectsSerializables.RegisterAll(types);
		return outStore.Load(stream, factory, types);
	}

	/// Reads the file, lets `change` change the registry, and writes it back. Refused, the file left
	/// as it is, when it does not read (a damaged registry is not replaced by an empty one) or
	/// cannot be written.
	public Result<void, ErrorCode> Change(delegate void(SdkRegistrySettings registry) change)
	{
		let store = scope Settings();
		if (Load(store) case .Err(let error))
			return .Err(error);
		change(store.Section<SdkRegistrySettings>());
		let buffer = scope MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		if (store.Save(buffer, factory) case .Err(let saveError))
			return .Err(saveError);
		if (!ProjectBuild.MakeDirectories(PathParent(mPath, .. scope .())))
			return .Err(.Internal);
		return WriteFileAtomic(mPath, buffer.Bytes);
	}

	/// Lists the SDK at `root` (made absolute), or marks one listed already as `managed` or not.
	/// InvalidArgument when `root` is no SDK (ProjectBuild.IsSdk).
	public Result<void, ErrorCode> Register(StringView root, bool managed = false)
	{
		let absolute = ProjectBuild.Absolute(root, .. scope .());
		if (!ProjectBuild.IsSdk(absolute))
			return .Err(.InvalidArgument);
		let installed = managed;
		return Change(scope [&](registry) =>
			{
				var sdk = registry.Find(absolute);
				if (sdk == null)
				{
					sdk = new RegisteredSdk();
					sdk.Root.Set(absolute);
					registry.Sdks.Add(sdk);
				}
				sdk.Managed = installed;
			});
	}

	/// Lists the SDK at `root` (made absolute) unless it is listed already, which keeps how it was
	/// listed: a project manager registering the SDK it sits in, which may be one it installed.
	/// InvalidArgument when `root` is no SDK.
	public Result<void, ErrorCode> Adopt(StringView root)
	{
		let absolute = ProjectBuild.Absolute(root, .. scope .());
		if (!ProjectBuild.IsSdk(absolute))
			return .Err(.InvalidArgument);
		return Change(scope [&](registry) =>
			{
				if (registry.Find(absolute) != null)
					return;
				let sdk = new RegisteredSdk();
				sdk.Root.Set(absolute);
				registry.Sdks.Add(sdk);
			});
	}

	/// Records `executable` (made absolute) as the project manager that ran last.
	public Result<void, ErrorCode> RecordManager(StringView executable)
	{
		let absolute = ProjectBuild.Absolute(executable, .. scope .());
		return Change(scope [&](registry) => { registry.ManagerPath.Set(absolute); });
	}

	/// The project manager that ran last into `outPath`, whether or not it is still there; false
	/// when none is recorded or the file does not read.
	public bool ManagerPath(String outPath)
	{
		outPath.Clear();
		let store = scope Settings();
		if (Load(store) case .Err)
			return false;
		outPath.Set(store.Section<SdkRegistrySettings>().ManagerPath);
		return !outPath.IsEmpty;
	}

	/// Takes the SDK at `root` off the list; its folder is not touched, and pins to it stay (an SDK
	/// pinned and gone is missing, as an unlisted one is not looked for). True when it was listed.
	public Result<bool, ErrorCode> Unregister(StringView root)
	{
		let absolute = ProjectBuild.Absolute(root, .. scope .());
		bool removed = false;
		let changed = Change(scope [&](registry) =>
			{
				let sdk = registry.Find(absolute);
				if (sdk == null)
					return;
				registry.Sdks.Remove(sdk);
				delete sdk;
				removed = true;
			});
		if (changed case .Err(let error))
			return .Err(error);
		return .Ok(removed);
	}

	/// Pins the project at `projectDir` to the SDK at `sdkRoot`, both made absolute: the SDK it
	/// builds against ahead of any of its version (FindSdk).
	public Result<void, ErrorCode> Pin(StringView projectDir, StringView sdkRoot)
	{
		let project = ProjectBuild.Absolute(projectDir, .. scope .());
		let sdk = ProjectBuild.Absolute(sdkRoot, .. scope .());
		return Change(scope [&](registry) =>
			{
				var pin = registry.FindPin(project);
				if (pin == null)
				{
					pin = new SdkPin();
					pin.Project.Set(project);
					registry.Pins.Add(pin);
				}
				pin.Sdk.Set(sdk);
			});
	}

	/// Takes the pin of the project at `projectDir` away. True when it had one.
	public Result<bool, ErrorCode> Unpin(StringView projectDir)
	{
		let project = ProjectBuild.Absolute(projectDir, .. scope .());
		bool removed = false;
		let changed = Change(scope [&](registry) =>
			{
				let pin = registry.FindPin(project);
				if (pin == null)
					return;
				registry.Pins.Remove(pin);
				delete pin;
				removed = true;
			});
		if (changed case .Err(let error))
			return .Err(error);
		return .Ok(removed);
	}

	/// The root the project at `projectDir` is pinned to into `outSdk`, whether or not it is still an
	/// SDK; false when it has no pin or the file does not read.
	public bool PinOf(StringView projectDir, String outSdk)
	{
		outSdk.Clear();
		let store = scope Settings();
		if (Load(store) case .Err)
			return false;
		let pin = store.Section<SdkRegistrySettings>().FindPin(ProjectBuild.Absolute(projectDir, .. scope .()));
		if (pin == null)
			return false;
		outSdk.Set(pin.Sdk);
		return true;
	}

	/// Each listed SDK, read again: those that read into `outSdks` (new, the caller's), the roots of
	/// those that do not (gone, or no longer an SDK) into `outMissing` (new, the caller's), each in
	/// the list's order. False when the file does not read.
	public bool ReadSdks(List<SdkInfo> outSdks, List<String> outMissing)
	{
		let store = scope Settings();
		if (Load(store) case .Err)
			return false;
		for (let sdk in store.Section<SdkRegistrySettings>().Sdks)
		{
			let info = new SdkInfo();
			if (SdkInfo.Read(sdk.Root, info) case .Ok)
				outSdks.Add(info);
			else
			{
				delete info;
				outMissing.Add(new .(sdk.Root));
			}
		}
		return true;
	}

	/// Each listed SDK in the list's order into `outListed` (each new, the caller's): its root, how it
	/// was listed, and what it says of itself read again (null when it is gone or no longer an SDK).
	/// False when the file does not read.
	public bool ReadListed(List<ListedSdk> outListed)
	{
		let store = scope Settings();
		if (Load(store) case .Err)
			return false;
		for (let sdk in store.Section<SdkRegistrySettings>().Sdks)
		{
			let listed = new ListedSdk();
			listed.Root.Set(sdk.Root);
			listed.Managed = sdk.Managed;
			let info = new SdkInfo();
			if (SdkInfo.Read(sdk.Root, info) case .Ok)
				listed.Info = info;
			else
				delete info;
			outListed.Add(listed);
		}
		return true;
	}

	/// The folders of the projects pinned to the SDK at `sdkRoot` (made absolute), in the order they
	/// were pinned, into `outProjects` (each new, the caller's). False when the file does not read.
	public bool PinnedTo(StringView sdkRoot, List<String> outProjects)
	{
		let store = scope Settings();
		if (Load(store) case .Err)
			return false;
		let sdk = ProjectBuild.Absolute(sdkRoot, .. scope .());
		for (let pin in store.Section<SdkRegistrySettings>().Pins)
		{
			if (pin.Sdk == sdk)
				outProjects.Add(new .(pin.Project));
		}
		return true;
	}

	/// Takes away every pin to the SDK at `sdkRoot` (made absolute): the projects then open with an
	/// SDK of their version, or ask for one. How many there were.
	public Result<int, ErrorCode> UnpinAll(StringView sdkRoot)
	{
		let sdk = ProjectBuild.Absolute(sdkRoot, .. scope .());
		int removed = 0;
		let changed = Change(scope [&](registry) =>
			{
				for (int i = registry.Pins.Count - 1; i >= 0; i--)
				{
					let pin = registry.Pins[i];
					if (pin.Sdk != sdk)
						continue;
					registry.Pins.RemoveAt(i);
					delete pin;
					removed++;
				}
			});
		if (changed case .Err(let error))
			return .Err(error);
		return .Ok(removed);
	}

	/// The SDK the registry gives the project at `projectDir`, stamped `stamp`, into `outSdk`: its
	/// pin while the pinned root is still an SDK, else the preferred (Prefer) of the listed SDKs
	/// whose version is `stamp`. False when it gives none: no pin and no stamp, or none of that
	/// version.
	public bool Pick(StringView projectDir, StringView stamp, String outSdk)
	{
		outSdk.Clear();
		let pinned = scope String();
		if (!projectDir.IsEmpty && PinOf(projectDir, pinned) && ProjectBuild.IsSdk(pinned))
		{
			outSdk.Set(pinned);
			return true;
		}
		if (stamp.IsEmpty)
			return false;
		let sdks = scope List<SdkInfo>();
		defer { ClearAndDeleteItems!(sdks); }
		let missing = scope List<String>();
		defer { ClearAndDeleteItems!(missing); }
		if (!ReadSdks(sdks, missing))
			return false;
		SdkInfo best = null;
		for (let sdk in sdks)
		{
			if ((sdk.Version == stamp) && ((best == null) || Prefer(sdk, best)))
				best = sdk;
		}
		if (best == null)
			return false;
		outSdk.Set(best.Root);
		return true;
	}

	/// Whether `a` is preferred to `b`, two SDKs of one version: a packed SDK before a checkout;
	/// then a final release before a pre-release before a dev build; then the higher build number.
	/// Neither is preferred when all three are equal, so the first listed wins a tie.
	public static bool Prefer(SdkInfo a, SdkInfo b)
	{
		if (a.IsCheckout != b.IsCheckout)
			return !a.IsCheckout;
		if (a.Release != b.Release)
			return (int)a.Release > (int)b.Release;
		return a.BuildNumber > b.BuildNumber;
	}
}
