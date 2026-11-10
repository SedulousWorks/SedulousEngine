using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using internal Sedulous.Editor.Project;

namespace Sedulous.Editor.Project;

/// What a project's build needs besides the SDK, each a line of Toolchain.Check's report.
enum ToolchainNeed
{
	/// BeefBuild, with corlib beside it.
	BeefBuild,
	/// The system linker BeefBuild links executables with.
	Linker,
	/// The archiver BeefBuild makes static libraries with (not on Windows, where the linker does).
	Archiver,
	/// Emscripten, which links the web player: needed by a web export alone.
	Emscripten
}

enum ToolchainState
{
	Ok,
	/// Found, with something worth knowing (a toolchain other than the SDK's).
	Warning,
	Missing
}

/// One need of the toolchain, as found.
class ToolchainLine
{
	public ToolchainNeed Need;
	public ToolchainState State;
	/// What was found: a path; for BeefBuild, also its version.
	public String Found = new .() ~ delete _;
	/// What is wrong or worth knowing, with the fix, said for a person; empty when all is well.
	public String Detail = new .() ~ delete _;
}

/// Toolchain.Check's answer: a line per need, in ToolchainNeed's order.
class ToolchainReport
{
	public List<ToolchainLine> Lines = new .() ~ DeleteContainerAndItems!(_);
	/// The BeefBuild found; empty for none.
	public String BeefBuild = new .() ~ delete _;
	/// The BeefBuild found is the managed toolchain's, whose settings the project manager may
	/// write (ProjectBuild.WriteEmscriptenPath).
	public bool Managed;

	/// The line of `need`; null when the report has none (the archiver on Windows).
	public ToolchainLine Get(ToolchainNeed need)
	{
		for (let line in Lines)
			if (line.Need == need)
				return line;
		return null;
	}

	/// Whether a desktop build can run: nothing missing but Emscripten, which only a web export
	/// needs.
	public bool CanBuild
	{
		get
		{
			for (let line in Lines)
				if ((line.Need != .Emscripten) && (line.State == .Missing))
					return false;
			return true;
		}
	}

	/// Whether a web build can run too.
	public bool CanBuildWeb => CanBuild && (Get(.Emscripten) != null) && (Get(.Emscripten).State != .Missing);

	public void Clear()
	{
		ClearAndDeleteItems!(Lines);
		BeefBuild.Clear();
		Managed = false;
	}

	internal ToolchainLine Add(ToolchainNeed need)
	{
		let line = new ToolchainLine();
		line.Need = need;
		Lines.Add(line);
		return line;
	}
}

/// What Toolchain.Check reads of its surroundings: the process's own (FromProcess), or what a test
/// gives it.
class ToolchainProbe
{
	/// BEEFBUILD; empty for unset.
	public String BeefBuildVariable = new .() ~ delete _;
	/// PATH.
	public String SearchPath = new .() ~ delete _;
	/// HOME, under which a Beef packaged for Linux keeps its settings.
	public String Home = new .() ~ delete _;
	/// Where managed toolchains are installed (<user-data>/Sedulous/Toolchains).
	public String Toolchains = new .() ~ delete _;
	/// The linker BeefBuild falls back to when PATH has none (Linux: /usr/bin/c++).
	public String LinkerFallback = new .() ~ delete _;
	/// The archiver BeefBuild falls back to when PATH has none (Linux: /usr/bin/ar).
	public String ArchiverFallback = new .() ~ delete _;
	/// Runs BeefBuild -version (BORROWED); null: Process.RunStreaming.
	public BuildRunner Runner;

	/// The probe of this process: its environment, the user's toolchains folder and the system's
	/// fallbacks.
	public void FromProcess()
	{
		Read(ProjectBuild.cBeefBuildVariable, BeefBuildVariable);
		Read("PATH", SearchPath);
		Read("HOME", Home);
		PathJoin(GetUserDataDirectory(.. scope .()), ProjectBuild.cToolchainsDir, Toolchains);
#if !BF_PLATFORM_WINDOWS
		LinkerFallback.Set(Toolchain.cLinkerFallback);
		ArchiverFallback.Set(Toolchain.cArchiverFallback);
#endif
	}

	private static void Read(StringView variable, String outValue)
	{
		outValue.Clear();
		if (Environment.GetEnvironmentVariable(variable, outValue) case .Err)
			outValue.Clear();
	}
}

/// The check of what a project's build needs besides the SDK, looked for as BeefBuild looks for
/// each, so what it reports missing is what would fail the build:
/// - BeefBuild (ProjectBuild.FindBeefBuild: BEEFBUILD, PATH, then the managed toolchain of the
///   SDK's pin), with its -version beside the pin (a mismatch warns; it does not refuse);
/// - on Linux, the linker (clang++, else c++, on PATH, else /usr/bin/c++) and the archiver
///   (llvm-ar, else ar, on PATH, else /usr/bin/ar); on Windows, LLVM's lld-link or Visual Studio's
///   link, which BeefBuild finds itself when they are not on PATH;
/// - Emscripten (ProjectBuild.FindEmscripten), for a web export alone.
/// Nothing is installed or changed here; each missing line says what to do.
static class Toolchain
{
	/// BeefBuild's linker when PATH has none, on Linux.
	public const String cLinkerFallback = "/usr/bin/c++";
	/// BeefBuild's archiver when PATH has none, on Linux.
	public const String cArchiverFallback = "/usr/bin/ar";

	/// The toolchain for building over `sdk` (its pin, sdk.Beef, picks the managed toolchain), into
	/// `outReport`, read from `probe` (null: this process's).
	public static void Check(SdkInfo sdk, ToolchainReport outReport, ToolchainProbe probe = null)
	{
		outReport.Clear();
		let own = scope ToolchainProbe();
		if (probe == null)
			own.FromProcess();
		let probed = (probe != null) ? probe : own;

		let beefBuild = outReport.Add(.BeefBuild);
		let managed = scope String();
		ProjectBuild.ManagedBeefBuildIn(probed.Toolchains, sdk.Beef, managed);
		let why = scope String();
		if (!ProjectBuild.FindBeefBuildFrom(probed.BeefBuildVariable, probed.SearchPath, outReport.BeefBuild, why, managed))
		{
			beefBuild.State = .Missing;
			beefBuild.Detail.Set(why);
			if (!sdk.Beef.IsEmpty)
				beefBuild.Detail.AppendF(". This engine was built with Beef {}: install that toolchain, or set {} to a BeefBuild", sdk.Beef, ProjectBuild.cBeefBuildVariable);
		}
		else
		{
			outReport.Managed = !managed.IsEmpty && (outReport.BeefBuild == managed);
			beefBuild.Found.Set(outReport.BeefBuild);
			let version = scope String();
			if (!BeefBuildVersion(outReport.BeefBuild, probed.Runner, version))
			{
				beefBuild.State = .Warning;
				beefBuild.Detail.AppendF("'{}' did not say its version (-version): it may not be a working BeefBuild", outReport.BeefBuild);
			}
			else
			{
				beefBuild.Found.AppendF(" ({})", version);
				if (!sdk.Beef.IsEmpty && !version.Contains(sdk.Beef))
				{
					beefBuild.State = .Warning;
					beefBuild.Detail.AppendF("this engine was built with Beef {}, and this BeefBuild says '{}': a build may fail on the difference", sdk.Beef, version);
				}
			}
		}

		let linker = outReport.Add(.Linker);
#if BF_PLATFORM_WINDOWS
		if (!FindFirst(probed.SearchPath, scope StringView[]("lld-link", "link"), "", linker.Found))
		{
			linker.State = .Warning;
			linker.Detail.Set("neither lld-link nor link is on PATH; BeefBuild finds Visual Studio's build tools itself: install them (the C++ desktop workload) if a link fails");
		}
#else
		if (!FindFirst(probed.SearchPath, scope StringView[]("clang++", "c++"), probed.LinkerFallback, linker.Found))
		{
			linker.State = .Missing;
			linker.Detail.Set("BeefBuild links with clang++ or c++ on PATH, and there is none: install clang (or g++), from the system's packages");
		}
		let archiver = outReport.Add(.Archiver);
		if (!FindFirst(probed.SearchPath, scope StringView[]("llvm-ar", "ar"), probed.ArchiverFallback, archiver.Found))
		{
			archiver.State = .Missing;
			archiver.Detail.Set("BeefBuild archives with llvm-ar or ar on PATH, and there is none: install binutils (or llvm), from the system's packages");
		}
#endif

		let emscripten = outReport.Add(.Emscripten);
		if (outReport.BeefBuild.IsEmpty)
		{
			emscripten.State = .Missing;
			emscripten.Detail.Set("found through BeefBuild's settings, and there is no BeefBuild");
		}
		else if (!ProjectBuild.FindEmscriptenFrom(outReport.BeefBuild, probed.Home, emscripten.Found, emscripten.Detail))
		{
			emscripten.State = .Missing;
			emscripten.Detail.Append(outReport.Managed ? ". Only a web export needs it: name its folder here and it is written into the toolchain's settings"
				: ". Only a web export needs it");
		}
	}

	/// The first of `names` on `searchPath` (ProjectBuild.FindOnPath), else `fallback` when that is
	/// a file, into `outPath`.
	private static bool FindFirst(StringView searchPath, Span<StringView> names, StringView fallback, String outPath)
	{
		for (let name in names)
		{
			if (ProjectBuild.FindOnPath(searchPath, name, outPath))
				return true;
		}
		if (!fallback.IsEmpty && FileExists(fallback))
		{
			outPath.Set(fallback);
			return true;
		}
		outPath.Clear();
		return false;
	}

	/// What the BeefBuild at `beefBuild` says it is, run with -version through `runner` (null:
	/// Process.RunStreaming): its first line that is not blank, trimmed ("BeefBuild 0.43.6"). False
	/// when it does not start, exits with an error, or says nothing.
	public static bool BeefBuildVersion(StringView beefBuild, BuildRunner runner, String outVersion)
	{
		outVersion.Clear();
		let arguments = scope StringView[]("-version");
		delegate void(StringView line) onLine = scope [&](line) =>
			{
				if (!outVersion.IsEmpty)
					return;
				var trimmed = line;
				trimmed.Trim();
				outVersion.Set(trimmed);
			};
		let result = (runner != null) ? runner(beefBuild, arguments, onLine, null) : Process.RunStreaming(beefBuild, arguments, onLine);
		bool exitedWell = false;
		switch (result)
		{
		case .Ok(let code): exitedWell = code == 0;
		case .Err: exitedWell = false;
		}
		if (!exitedWell)
			outVersion.Clear();
		return !outVersion.IsEmpty;
	}
}
