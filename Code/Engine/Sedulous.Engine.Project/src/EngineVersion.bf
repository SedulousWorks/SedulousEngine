using System;

namespace Sedulous.Engine.Project;

/// The engine's own version, stamped into every saved project manifest.
///
/// Distinct from a type's data version: this says which ENGINE authored a project, so a
/// launcher or a migration can route on it.
///
/// Beef has no build-time injection for this, so THIS FILE is the one place: bump it here
/// and nothing else needs touching.
///
/// Two versions: String, the numbers alone, is what every compatibility check compares (a
/// project's manifest, an export template, a plugin's engine check), so a beta's projects and
/// plugins work with the final release; Display, String with the release's Label, is what a
/// person reads (the About box, the startup log, the MCP hosts, the release's tag and the
/// downloads that come from it).
static class EngineVersion
{
	public const uint32 Major = 0;
	public const uint32 Minor = 1;
	public const uint32 Patch = 0;
	public const String String = "0.1.0";
	/// The release's pre-release label ("beta"; empty for a final release).
	public const String Label = "beta";
	/// String with Label ("0.1.0-beta"; String alone with no label). Set beside them: a test
	/// holds the three in step.
	public const String Display = "0.1.0-beta";
	/// The build number of a build handed out, set here by hand before building it; 0 is a local
	/// build.
	public const uint32 BuildNumber = 0;
	/// The engine's name, as the About box says it.
	public const String ProductName = "SedulousEngine";

	/// The GitHub repository (owner/name) whose releases carry what this engine downloads for its
	/// own version, such as the sample games. Kept here beside the version for the same reason.
	public const String ReleaseRepository = "SedulousWorks/SedulousEngine";

	/// Where `file` attached to this engine's own release is downloaded from: release v<version>
	/// of ReleaseRepository, the version with its label (the release's tag, v0.1.0-beta). A build
	/// between releases names a release that may not exist yet.
	public static void ReleaseDownloadUrl(StringView file, String outUrl)
	{
		outUrl.AppendF("https://github.com/{}/releases/download/v{}/{}", ReleaseRepository, Display, file);
	}

	/// How a build names itself to a person, appended: the version, then its build number (or
	/// "local build" for 0) and `stamp` (ExecutableStamp). "0.1.0-beta (build 3, 2026-11-05T15:03:00Z)",
	/// or "0.1.0-beta (local build, 2026-11-05T15:03:00Z)". The startup log and --version write it,
	/// so a report names the exact build.
	public static void BuildIdentity(StringView stamp, uint32 buildNumber, String outText)
	{
		if (buildNumber == 0)
			outText.AppendF("{} (local build, {})", Display, stamp);
		else
			outText.AppendF("{} (build {}, {})", Display, buildNumber, stamp);
	}

	/// This build's identity: BuildIdentity over BuildNumber and the executable's stamp.
	public static void BuildIdentity(String outText)
	{
		BuildIdentity(ExecutableStamp(.. scope .()), BuildNumber, outText);
	}

	/// When the running executable was written (UTC, ISO 8601), appended: what was linked,
	/// whatever was or was not recompiled into it. "unknown" where it cannot be read (a
	/// browser's).
	public static void ExecutableStamp(String outStamp)
	{
#if !BF_PLATFORM_WASM
		let exe = Environment.GetExecutableFilePath(.. scope .());
		if (!exe.IsEmpty && (System.IO.File.GetLastWriteTimeUtc(exe) case .Ok(let time)))
		{
			time.ToString(outStamp, "yyyy-MM-ddTHH:mm:ssZ");
			return;
		}
#endif
		outStamp.Append("unknown");
	}
}
