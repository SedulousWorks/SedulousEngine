using System;
using System.Collections;
using Sedulous.Json;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.ProjectManager;

/// An engine SDK a release offers for this platform, as the release's index (sdk-<platform>.json)
/// gives it.
class AvailableEngine
{
	/// The release's tag ("v0.2.0-beta").
	public String Tag = new .() ~ delete _;
	/// "major.minor.patch", what a project's stamp is compared with.
	public String Version = new .() ~ delete _;
	public String Label = new .() ~ delete _;
	/// Version with its label, as a person reads it.
	public String Display = new .() ~ delete _;
	public String Platform = new .() ~ delete _;
	/// The SDK's zip in the release, its digest (64 lowercase hex digits), its bytes and what it
	/// unpacks to.
	public String Archive = new .() ~ delete _;
	public String Sha256 = new .() ~ delete _;
	public uint64 Size;
	public uint64 UnpackedSize;
	/// The toolchain it was built with (its sdk.json's beef); empty: it names none.
	public String Beef = new .() ~ delete _;
	/// The toolchain's zip, its digest and bytes; empty: the index offers none.
	public String ToolchainArchive = new .() ~ delete _;
	public String ToolchainSha256 = new .() ~ delete _;
	public uint64 ToolchainSize;
	/// The release (tag) whose files carry the toolchain's zip: an earlier one when the toolchain
	/// did not change with this release; empty: this one.
	public String ToolchainRelease = new .() ~ delete _;
	/// Where the SDK's zip is fetched from, set by whoever listed it.
	public String ArchiveUrl = new .() ~ delete _;

	public void CopyFrom(AvailableEngine other)
	{
		Tag.Set(other.Tag);
		Version.Set(other.Version);
		Label.Set(other.Label);
		Display.Set(other.Display);
		Platform.Set(other.Platform);
		Archive.Set(other.Archive);
		Sha256.Set(other.Sha256);
		Size = other.Size;
		UnpackedSize = other.UnpackedSize;
		Beef.Set(other.Beef);
		ToolchainArchive.Set(other.ToolchainArchive);
		ToolchainSha256.Set(other.ToolchainSha256);
		ToolchainSize = other.ToolchainSize;
		ToolchainRelease.Set(other.ToolchainRelease);
		ArchiveUrl.Set(other.ArchiveUrl);
	}
}

/// A file attached to a release: its name, where it is downloaded from, and its bytes.
class ReleaseAsset
{
	public String Name = new .() ~ delete _;
	public String Url = new .() ~ delete _;
	public uint64 Size;
}

/// One release of the engine's repository, as the releases list gives it.
class EngineRelease
{
	public String Tag = new .() ~ delete _;
	public bool PreRelease;
	public List<ReleaseAsset> Assets = new .() ~ DeleteContainerAndItems!(_);

	/// The asset named `name`; null when the release has none.
	public ReleaseAsset Find(StringView name)
	{
		for (let asset in Assets)
			if (asset.Name == name)
				return asset;
		return null;
	}
}

/// The engine's releases as the project manager reads them: GitHub's list of the repository's
/// releases (ReleaseRepository), and in each release that has an engine for this platform its
/// index, sdk-<platform>.json, written by the SDK's packer:
///
///     {"version": "0.2.0", "label": "beta", "display": "0.2.0-beta", "platform": "Linux64",
///      "archive": "sedulous-sdk-0.2.0-beta-linux64.zip", "sha256": "<64 hex digits>",
///      "size": 1234, "unpackedSize": 5678, "beef": "<toolchain pin>",
///      "toolchain": {"archive": "beef-<pin>-linux64.zip", "sha256": "<64 hex digits>",
///                    "size": 1234, "release": "v0.1.0"}}
///
/// The toolchain's release is the one whose files carry its zip, absent when it is this one: a
/// release whose toolchain did not change does not carry it again.
static class EngineReleases
{
	/// The index's name for this platform ("sdk-linux64.json").
	public static void IndexFile(String outName)
	{
		let platform = scope String(BuildLayout.HostPlatformName);
		platform.ToLower();
		outName.AppendF("sdk-{}.json", platform);
	}

	/// GitHub's list of the engine repository's releases, newest first.
	public static void DefaultReleasesUrl(String outUrl)
	{
		outUrl.AppendF("https://api.github.com/repos/{}/releases", EngineVersion.ReleaseRepository);
	}

	/// Where `file` of the release tagged `tag` is downloaded from.
	public static void DownloadUrl(StringView tag, StringView file, String outUrl)
	{
		outUrl.AppendF("https://github.com/{}/releases/download/{}/{}", EngineVersion.ReleaseRepository, tag, file);
	}

	/// The releases list (GitHub's JSON) into `outReleases` (each new, the caller's), drafts passed
	/// by. False with `outError`, said for a person, when it is not a list of releases.
	public static bool ParseReleases(StringView json, List<EngineRelease> outReleases, String outError)
	{
		let parsed = scope JsonParseResult();
		JsonParser.Parse(json, parsed);
		if (!parsed.Ok || !parsed.Value.IsArray)
		{
			outError.Set("the list of releases could not be read");
			return false;
		}
		for (int i < parsed.Value.Count)
		{
			let item = parsed.Value.At(i);
			if (!item.IsObject || Flag(item, "draft"))
				continue;
			let tag = Text(item, "tag_name");
			if (tag.IsEmpty)
				continue;
			let release = new EngineRelease();
			release.Tag.Set(tag);
			release.PreRelease = Flag(item, "prerelease");
			let assets = item.Get("assets");
			for (int a < ((assets != null) ? assets.Count : 0))
			{
				let file = assets.At(a);
				if ((file == null) || !file.IsObject || !SampleCatalog.PlainName(Text(file, "name")))
					continue;
				let asset = new ReleaseAsset();
				asset.Name.Set(Text(file, "name"));
				asset.Url.Set(Text(file, "browser_download_url"));
				asset.Size = (uint64)Math.Max((int64)0, Number(file, "size"));
				release.Assets.Add(asset);
			}
			outReleases.Add(release);
		}
		return true;
	}

	/// A release's index into `outEngine` (its tag and URL left as they are). False with `outError`
	/// when it is not one: a version that is not "major.minor.patch", an archive that is not a plain
	/// name or a digest that is not 64 digits refuses it; a toolchain with either refuses the whole.
	public static bool ParseIndex(StringView json, AvailableEngine outEngine, String outError)
	{
		let parsed = scope JsonParseResult();
		JsonParser.Parse(json, parsed);
		if (!parsed.Ok || !parsed.Value.IsObject)
		{
			outError.Set("the release's engine index could not be read");
			return false;
		}
		let index = parsed.Value;
		outEngine.Version.Set(Text(index, "version"));
		outEngine.Label.Set(Text(index, "label"));
		outEngine.Display.Set(Text(index, "display"));
		outEngine.Platform.Set(Text(index, "platform"));
		outEngine.Archive.Set(Text(index, "archive"));
		outEngine.Sha256.Set(Text(index, "sha256"));
		outEngine.Size = (uint64)Math.Max((int64)0, Number(index, "size"));
		outEngine.UnpackedSize = (uint64)Math.Max((int64)0, Number(index, "unpackedSize"));
		outEngine.Beef.Set(Text(index, "beef"));
		if (outEngine.Display.IsEmpty)
		{
			outEngine.Display.Set(outEngine.Version);
			if (!outEngine.Label.IsEmpty)
				outEngine.Display.AppendF("-{}", outEngine.Label);
		}
		if (!ProjectRegistry.ParseEngineVersion(outEngine.Version, ?) || !SampleCatalog.PlainName(outEngine.Archive)
			|| (outEngine.Sha256.Length != 64) || !SampleCatalog.PlainName(outEngine.Display))
		{
			outError.Set("the release's engine index names an engine this manager cannot fetch");
			return false;
		}
		let toolchain = index.Get("toolchain");
		if ((toolchain != null) && toolchain.IsObject)
		{
			outEngine.ToolchainArchive.Set(Text(toolchain, "archive"));
			outEngine.ToolchainSha256.Set(Text(toolchain, "sha256"));
			outEngine.ToolchainSize = (uint64)Math.Max((int64)0, Number(toolchain, "size"));
			outEngine.ToolchainRelease.Set(Text(toolchain, "release"));
			if (!SampleCatalog.PlainName(outEngine.ToolchainArchive) || (outEngine.ToolchainSha256.Length != 64)
				|| (!outEngine.ToolchainRelease.IsEmpty && !SampleCatalog.PlainName(outEngine.ToolchainRelease)))
			{
				outError.Set("the release's engine index names a toolchain this manager cannot fetch");
				return false;
			}
		}
		return true;
	}

	/// Whether `a` is listed before `b`: the higher version, then, of one version, a final release
	/// before a pre-release before a dev build.
	public static bool Newer(AvailableEngine a, AvailableEngine b)
	{
		uint32[3] versionA;
		uint32[3] versionB;
		let readsA = ProjectRegistry.ParseEngineVersion(a.Version, out versionA);
		let readsB = ProjectRegistry.ParseEngineVersion(b.Version, out versionB);
		if (readsA != readsB)
			return readsA;
		for (int i < 3)
		{
			if (versionA[i] != versionB[i])
				return versionA[i] > versionB[i];
		}
		return Rank(a.Label) > Rank(b.Label);
	}

	/// A final release 2, a pre-release 1, a dev build 0.
	private static int Rank(StringView label) => label.IsEmpty ? 2 : ((label == SdkInfo.cDevLabel) ? 0 : 1);

	/// The text of `key` in `item`; empty when it has no string there. Borrowed from `item`.
	private static StringView Text(JsonValue item, StringView key)
	{
		let value = item.Get(key);
		return (value != null) ? value.AsString() : StringView();
	}

	private static int64 Number(JsonValue item, StringView key)
	{
		let value = item.Get(key);
		return (value != null) ? value.AsInt() : 0;
	}

	private static bool Flag(JsonValue item, StringView key)
	{
		let value = item.Get(key);
		return (value != null) && value.AsBool();
	}
}
