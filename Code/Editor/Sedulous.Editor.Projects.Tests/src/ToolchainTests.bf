using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Editor.Project;
using Sedulous.Editor.Projects.TestSupport;

namespace Sedulous.Editor.Projects.Tests;

/// The toolchain check over fake installs and a PATH of fake tools: BeefBuild and what it says of
/// itself against the SDK's pin, the linker and the archiver looked for as BeefBuild looks, the
/// managed toolchain of a pin, and Emscripten's folder written into the managed toolchain's
/// settings. Nothing runs a real BeefBuild: -version goes through a fake runner.
class ToolchainTests
{
	typealias Bed = ProjectBuildBed;

#if BF_PLATFORM_WINDOWS
	private const String cSeparator = ";";
#else
	private const String cSeparator = ":";
#endif

	/// A folder under the bed holding an empty file for each of `tools` (with the host's executable
	/// suffix), for a PATH; its path.
	private static void Tools(Bed bed, StringView name, Span<StringView> tools, String outDir)
	{
		PathJoin(bed.Root, name, outDir);
		Bed.MakeDirectories(outDir);
		for (let tool in tools)
			Bed.Write(outDir, BuildLayout.ExecutableName(tool, .. scope .()), "#!tool\n");
	}

	/// A probe over `searchPath`, with no BEEFBUILD, the bed's own HOME and toolchains folder, and
	/// fallbacks that are not there.
	private static void Probe(Bed bed, StringView searchPath, BuildRunner runner, ToolchainProbe outProbe)
	{
		outProbe.SearchPath.Set(searchPath);
		PathJoin(bed.Root, "home", outProbe.Home);
		PathJoin(bed.Root, "toolchains", outProbe.Toolchains);
		PathJoin(bed.Root, "no such/c++", outProbe.LinkerFallback);
		PathJoin(bed.Root, "no such/ar", outProbe.ArchiverFallback);
		outProbe.Runner = runner;
	}

#if !BF_PLATFORM_WINDOWS
	/// The linker and the archiver BeefBuild looks for on Linux; Windows has no archiver line.
	[Test]
	public static void TheCheckFindsBeefBuildItsVersionTheLinkerAndTheArchiver()
	{
		let bed = scope Bed();
		let installed = Bed.FakeInstall(bed, "installed/bin/BeefBuild", "'../BeefLibs'", "installed/BeefLibs/corlib", .. scope .());
		let source = Bed.FakeInstall(bed, "beef/IDE/dist/BeefBuild", "\"../../BeefLibs\"", "beef/BeefLibs/corlib", .. scope .());
		let clang = Tools(bed, "clang", scope StringView[]("clang++", "llvm-ar"), .. scope .());
		let gnu = Tools(bed, "gnu", scope StringView[]("c++", "ar"), .. scope .());
		let empty = Tools(bed, "empty", default, .. scope .());
		String said = "BeefBuild 0.43.6";
		int runs = 0;
		int exitCode = 0;
		BuildRunner runner = scope [&](executable, arguments, onLine, cancelled) =>
			{
				runs++;
				Test.Assert((arguments.Length == 1) && (arguments[0] == "-version"));
				onLine("");
				if (!said.IsEmpty)
				{
					onLine(scope $"  {said}  ");
					onLine("not the version");
				}
				return .Ok(exitCode);
			};
		let sdk = scope SdkInfo();
		sdk.Beef.Set("0.43.6");
		let probe = scope ToolchainProbe();
		let report = scope ToolchainReport();
		let installedDir = PathParent(installed, .. scope .());

		// Everything there: BeefBuild from PATH, saying the SDK's pin, clang++ and llvm-ar first.
		Probe(bed, scope $"{installedDir}{cSeparator}{clang}{cSeparator}{gnu}", runner, probe);
		Toolchain.Check(sdk, report, probe);
		Test.Assert(runs == 1);
		Test.Assert(report.Lines.Count == 4);
		Test.Assert((report.Get(.BeefBuild).State == .Ok) && (report.BeefBuild == installed) && !report.Managed);
		Test.Assert(report.Get(.BeefBuild).Found == scope $"{installed} (BeefBuild 0.43.6)", report.Get(.BeefBuild).Found);
		Test.Assert(report.Get(.Linker).Found == PathJoin(clang, BuildLayout.ExecutableName("clang++", .. scope .()), .. scope .()));
		Test.Assert(report.Get(.Archiver).Found == PathJoin(clang, BuildLayout.ExecutableName("llvm-ar", .. scope .()), .. scope .()));
		Test.Assert((report.Get(.Emscripten).State == .Missing) && report.Get(.Emscripten).Detail.Contains("Only a web export needs it"));
		Test.Assert(report.CanBuild && !report.CanBuildWeb, "Emscripten is a web export's alone");

		// Without clang: c++ and ar.
		Probe(bed, scope $"{installedDir}{cSeparator}{gnu}", runner, probe);
		Toolchain.Check(sdk, report, probe);
		Test.Assert(report.Get(.Linker).Found == PathJoin(gnu, BuildLayout.ExecutableName("c++", .. scope .()), .. scope .()));
		Test.Assert(report.Get(.Archiver).Found == PathJoin(gnu, BuildLayout.ExecutableName("ar", .. scope .()), .. scope .()));
		Test.Assert(report.CanBuild);

		// Neither on PATH: missing, saying what to install, unless the system's fallback is there.
		Probe(bed, scope $"{installedDir}{cSeparator}{empty}", runner, probe);
		Toolchain.Check(sdk, report, probe);
		Test.Assert((report.Get(.Linker).State == .Missing) && report.Get(.Linker).Detail.Contains("install clang"));
		Test.Assert((report.Get(.Archiver).State == .Missing) && report.Get(.Archiver).Detail.Contains("install binutils"));
		Test.Assert(report.Get(.Linker).Found.IsEmpty && !report.CanBuild);
		let fallback = PathJoin(gnu, BuildLayout.ExecutableName("c++", .. scope .()), .. scope .());
		probe.LinkerFallback.Set(fallback);
		probe.ArchiverFallback.Set(PathJoin(gnu, BuildLayout.ExecutableName("ar", .. scope .()), .. scope .()));
		Toolchain.Check(sdk, report, probe);
		Test.Assert((report.Get(.Linker).State == .Ok) && (report.Get(.Linker).Found == fallback));
		Test.Assert((report.Get(.Archiver).State == .Ok) && report.CanBuild);

		// Another toolchain than the SDK's pin warns, and builds.
		said = "BeefBuild 0.44.0";
		Toolchain.Check(sdk, report, probe);
		Test.Assert(report.Get(.BeefBuild).State == .Warning);
		Test.Assert(report.Get(.BeefBuild).Detail.Contains("built with Beef 0.43.6") && report.Get(.BeefBuild).Detail.Contains("'BeefBuild 0.44.0'"), report.Get(.BeefBuild).Detail);
		Test.Assert(report.CanBuild);
		sdk.Beef.Clear();
		Toolchain.Check(sdk, report, probe);
		Test.Assert(report.Get(.BeefBuild).State == .Ok, "an SDK with no pin takes any");

		// One that fails -version, or says nothing, is a warning too.
		exitCode = 1;
		Toolchain.Check(sdk, report, probe);
		Test.Assert((report.Get(.BeefBuild).State == .Warning) && report.Get(.BeefBuild).Detail.Contains("did not say its version"));
		Test.Assert(report.Get(.BeefBuild).Found == installed);
		exitCode = 0;
		said = "";
		let version = scope String();
		Test.Assert(!Toolchain.BeefBuildVersion(installed, runner, version) && version.IsEmpty);
		said = "BeefBuild 0.43.6";
		Test.Assert(Toolchain.BeefBuildVersion(installed, runner, version) && (version == "BeefBuild 0.43.6"));

		// BEEFBUILD wins over PATH, a source build's layout as well as an install's.
		probe.BeefBuildVariable.Set(source);
		Toolchain.Check(sdk, report, probe);
		Test.Assert((report.Get(.BeefBuild).State == .Ok) && (report.BeefBuild == source));

		// No BeefBuild at all: nothing runs, and Emscripten cannot be looked for.
		probe.BeefBuildVariable.Clear();
		Probe(bed, empty, runner, probe);
		runs = 0;
		Toolchain.Check(sdk, report, probe);
		Test.Assert(runs == 0);
		Test.Assert((report.Get(.BeefBuild).State == .Missing) && report.Get(.BeefBuild).Detail.Contains("BeefBuild not found"));
		Test.Assert(report.BeefBuild.IsEmpty && (report.Get(.Emscripten).State == .Missing) && !report.CanBuild);
	}
#endif

	[Test]
	public static void TheManagedBeefBuildIsTheOneOfTheSdksPin()
	{
		let bed = scope Bed();
		let toolchains = PathJoin(bed.Root, "toolchains", .. scope .());
		let path = scope String();
		Test.Assert(!ProjectBuild.ManagedBeefBuildIn(toolchains, "nightly-2026-11-01", path));
		let exe = BuildLayout.ExecutableName("BeefBuild", .. scope .());
		Test.Assert(path == PathJoin(toolchains, scope $"nightly-2026-11-01/bin/{exe}", .. scope .()), path);
		for (let bad in StringView[?]("", ".", "..", "../up", "a/b", "a\\b"))
			Test.Assert(!ProjectBuild.ManagedBeefBuildIn(toolchains, bad, path) && path.IsEmpty, scope String(bad));

		// Installed: the packed layout, corlib reached from bin through ../BeefLibs.
		let managed = Bed.FakeInstall(bed, "toolchains/nightly-2026-11-01/bin/BeefBuild", "\"../BeefLibs\"", "toolchains/nightly-2026-11-01/BeefLibs/corlib", .. scope .());
		Test.Assert(ProjectBuild.ManagedBeefBuildIn(toolchains, "nightly-2026-11-01", path) && (path == managed), path);

		// Asked last, after BEEFBUILD and PATH; a pin with no install is named among those tried.
		let found = scope String();
		let error = scope String();
		Test.Assert(ProjectBuild.FindBeefBuildFrom("", "", found, error, managed) && (found == managed), error);
		let onPath = Bed.FakeInstall(bed, "installed/bin/BeefBuild", "'../BeefLibs'", "installed/BeefLibs/corlib", .. scope .());
		Test.Assert(ProjectBuild.FindBeefBuildFrom("", PathParent(onPath, .. scope .()), found, error, managed) && (found == onPath));
		let other = PathJoin(toolchains, "other/bin/BeefBuild", .. scope .());
		Test.Assert(!ProjectBuild.FindBeefBuildFrom("", "", found, error..Clear(), other));
		Test.Assert(error.Contains(scope $"the managed install '{other}': no such file"), error);

		// The check takes the SDK's pin's, and says it is the managed one.
		BuildRunner runner = scope (executable, arguments, onLine, cancelled) =>
			{
				onLine("BeefBuild 0.43.6");
				return .Ok(0);
			};
		let probe = scope ToolchainProbe();
		probe.Toolchains.Set(toolchains);
		probe.Runner = runner;
		let sdk = scope SdkInfo();
		sdk.Beef.Set("nightly-2026-11-01");
		let report = scope ToolchainReport();
		Toolchain.Check(sdk, report, probe);
		Test.Assert((report.BeefBuild == managed) && report.Managed);
		Test.Assert(report.Get(.BeefBuild).State == .Warning, "a toolchain whose -version does not name its pin");
		sdk.Beef.Set("nightly-2026-12-01");
		Toolchain.Check(sdk, report, probe);
		Test.Assert((report.Get(.BeefBuild).State == .Missing) && report.Get(.BeefBuild).Detail.Contains("built with Beef nightly-2026-12-01"));
	}

	[Test]
	public static void EmscriptensFolderIsWrittenIntoTheManagedToolchainsSettings()
	{
		let bed = scope Bed();
		let managed = Bed.FakeInstall(bed, "toolchains/pin/bin/BeefBuild", "\"../BeefLibs\"", "toolchains/pin/BeefLibs/corlib", .. scope .());
		let emsdk = Bed.FakeEmscripten(bed, "emsdk", .. scope .());
		let home = PathJoin(bed.Root, "home", .. scope .());
		let found = scope String();
		let error = scope String();
		Test.Assert(!ProjectBuild.FindEmscriptenFrom(managed, home, found, error));

		// No settings yet: the file is made, and BeefBuild's reading finds the folder.
		Test.Assert(ProjectBuild.WriteEmscriptenPath(managed, emsdk) case .Ok);
		Test.Assert(ProjectBuild.FindEmscriptenFrom(managed, home, found, error..Clear()) && (found == emsdk), error);

		// Settings there: the old path replaced, every other line and table kept.
		let settings = PathJoin(bed.Root, "toolchains/pin/bin/BeefSettings.toml", .. scope .());
		Bed.Write(bed.Root, "toolchains/pin/bin/BeefSettings.toml",
			"FileVersion = 1\n\n[Wasm]\nEmscriptenPath = \"/old/emsdk\"\nOther = 1\n\n[Wasm.More]\nEmscriptenPath = \"/not/this\"\n\n[RecentFiles]\n");
		let other = Bed.FakeEmscripten(bed, "other emsdk", .. scope .());
		Test.Assert(ProjectBuild.WriteEmscriptenPath(managed, other) case .Ok);
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(settings, bytes) case .Ok);
		let text = scope String(StringView((char8*)bytes.Ptr, bytes.Count));
		Test.Assert(text == scope $"FileVersion = 1\n\n[Wasm]\nEmscriptenPath = \"{other}\"\nOther = 1\n\n[Wasm.More]\nEmscriptenPath = \"/not/this\"\n\n[RecentFiles]\n", text);
		Test.Assert(ProjectBuild.FindEmscriptenFrom(managed, home, found, error..Clear()) && (found == other), error);

		// The check finds it now.
		BuildRunner runner = scope (executable, arguments, onLine, cancelled) =>
			{
				onLine("BeefBuild pin");
				return .Ok(0);
			};
		let probe = scope ToolchainProbe();
		probe.Toolchains.Set(PathJoin(bed.Root, "toolchains", .. scope .()));
		probe.Home.Set(home);
		probe.Runner = runner;
		let sdk = scope SdkInfo();
		sdk.Beef.Set("pin");
		let report = scope ToolchainReport();
		Toolchain.Check(sdk, report, probe);
		Test.Assert((report.Get(.Emscripten).State == .Ok) && (report.Get(.Emscripten).Found == other));

		// The table and the key added where there are none; a value's backslashes and quotes escaped
		// so TomlValue reads it back as it was.
		let value = scope String();
		let added = ProjectBuild.SetTomlString("FileVersion = 1\n\n[Options]\nA = 1\n", "Wasm", "EmscriptenPath", "C:\\emsdk \"x\"", .. scope .());
		Test.Assert(added == "FileVersion = 1\n\n[Options]\nA = 1\n\n[Wasm]\nEmscriptenPath = \"C:\\\\emsdk \\\"x\\\"\"\n", added);
		Test.Assert(ProjectBuild.TomlValue(added, "Wasm", "EmscriptenPath", value) && (value == "C:\\emsdk \"x\""), value);
		let inserted = ProjectBuild.SetTomlString("[Wasm]\nOther = 2\n", "Wasm", "EmscriptenPath", "/opt/emsdk", .. scope .());
		Test.Assert(inserted == "[Wasm]\nEmscriptenPath = \"/opt/emsdk\"\nOther = 2\n", inserted);
		Test.Assert(ProjectBuild.SetTomlString("", "Wasm", "EmscriptenPath", "/e", .. scope .()) == "[Wasm]\nEmscriptenPath = \"/e\"\n");
	}
}
