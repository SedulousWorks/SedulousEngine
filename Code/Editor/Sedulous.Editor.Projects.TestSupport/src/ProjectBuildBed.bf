using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Projects.TestSupport;

/// An SDK with the files the build reads (the startup libraries, the stock editor's, web
/// player's and MCP host's projects) and a data root, a second SDK, and a project with the
/// game's package in Code/ (an Engine and an Editor part) and a project-local package in
/// Plugins/Lantern (an Engine, a Pipeline and a Tooling part). The build service's tests
/// (ProjectBuildServiceTests) build over it too.
public class ProjectBuildBed
{
	private const String cRoot = "scratch_project_build";
	/// The engine's own stock web player and MCP host projects, whose configs the web player and
	/// the tools take over: a change to them shows here.
	private const String cStockWeb = Compiler.ReadText("../../Engine/Sedulous.Engine.Player.Web/BeefProj.toml");
	private const String cStockTools = Compiler.ReadText("../../Tools/Sedulous.Tools.Mcp/BeefProj.toml");

	public String Root = new .() ~ delete _;
	public String Sdk = new .() ~ delete _;
	public String OtherSdk = new .() ~ delete _;
	public String ProjectDir = new .() ~ delete _;
	public ProjectSettings Settings = new .() ~ delete _;

	public this()
	{
		RemoveDirectoryRecursive(cRoot);
		let cwd = GetCurrentDirectory(.. scope .());
		PathJoin(cwd, cRoot, Root);
		PathJoin(Root, "sdk", Sdk);
		PathJoin(Root, "other sdk", OtherSdk);
		PathJoin(Root, "Native Game", ProjectDir);
		WriteSdk(Sdk);
		WriteSdk(OtherSdk);

		Settings.Name.Set("Native Game");
		AddPackage("nativegame", "Code", scope StringView[]("Engine", "Editor"));
		Write(ProjectDir, "Code/NativeGame/BeefProj.toml", "");
		Write(ProjectDir, "Code/NativeGame.Editor/BeefProj.toml", "");
		AddPackage("lantern", "Plugins/Lantern", scope StringView[]("Engine", "Pipeline", "Tooling"));
		Write(ProjectDir, "Plugins/Lantern/Lantern.Engine/BeefProj.toml", "");
		Write(ProjectDir, "Plugins/Lantern/Lantern.Pipeline/BeefProj.toml", "");
		Write(ProjectDir, "Plugins/Lantern/Lantern.Tooling/BeefProj.toml", "");
	}

	public ~this()
	{
		RemoveDirectoryRecursive(cRoot);
	}

	/// A package's manifest of `kinds` at `path` in the project, and the project's entry for it.
	private void AddPackage(StringView id, StringView path, Span<StringView> kinds)
	{
		let entry = new EnabledPlugin();
		entry.Id.Set(id);
		entry.Path.Set(path);
		Settings.Plugins.Add(entry);
		let manifest = scope PluginManifest();
		manifest.Id.Set(id);
		manifest.Name.Set(id);
		manifest.Version.Set("0.1.0");
		manifest.EngineVersion.Set("0.1");
		for (let kind in kinds)
		{
			let part = new PluginManifestPart();
			part.Kind.Set(kind);
			manifest.Parts.Add(part);
		}
		let xml = scope String();
		Test.Assert(manifest.Write(xml) case .Ok);
		Write(ProjectDir, scope $"{path}/Plugin.xml", xml);
	}

	/// An SDK at `sdk` with the files the build reads (ProjectBuild.IsSdk's startup libraries, the
	/// stock projects Generate reads) and a data root, and `info` as its sdk.json when given (none:
	/// a checkout's layout).
	public static void WriteSdk(StringView sdk, StringView info = default)
	{
		Write(sdk, "Code/Tools/Sedulous.Tools.Editor/BeefProj.toml",
			"FileVersion = 1\n\n[Project]\nName = \"Sedulous.Tools.Editor\"\n\n[Configs.Debug.Linux64]\nPostBuildCmds = [\"CopyToTarget(\\\"$(WorkspaceDir)/../Bin/Naga/bin/linux-x86_64/naga\\\")\"]\n");
		Write(sdk, ProjectBuild.cStockWebProject, cStockWeb);
		Write(sdk, ProjectBuild.cStockToolsProject, cStockTools);
		for (let library in StringView[6]("Code/Editor/Sedulous.Editor.Main", "Code/Engine/Sedulous.Engine.Player.DesktopMain",
			"Code/Engine/Sedulous.Engine.Player.WebMain", "Code/Editor/Sedulous.Editor.McpMain", "Code/Editor/Sedulous.Editor.CookMain",
			"Code/Editor/Sedulous.Editor.ExportMain"))
			Write(sdk, scope $"{library}/BeefProj.toml", "");
		MakeDirectories(PathJoin(sdk, "Data", .. scope .()));
		if (!info.IsEmpty)
			Write(sdk, SdkInfo.cInfoFile, info);
	}

	public static void Write(StringView dir, StringView relative, StringView text)
	{
		let path = PathJoin(dir, relative, .. scope .());
		MakeDirectories(PathParent(path, .. scope .()));
		Test.Assert(WriteFile(path, .((uint8*)text.Ptr, text.Length)) case .Ok);
	}

	public static void MakeDirectories(StringView dir)
	{
		if (DirectoryExists(dir))
			return;
		MakeDirectories(PathParent(dir, .. scope .()));
		CreateDirectory(dir);
	}

	/// A file of the project's workspace (Code/).
	public void Read(StringView relative, String outText)
	{
		let bytes = scope List<uint8>();
		let path = PathJoin(ProjectBuild.Directory(ProjectDir, .. scope .()), relative, .. scope .());
		Test.Assert(ReadFile(path, bytes) case .Ok, path);
		outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
	}

	/// Writes a file of the project's workspace (Code/).
	public void WriteCode(StringView relative, StringView text)
	{
		Write(ProjectBuild.Directory(ProjectDir, .. scope .()), relative, text);
	}

	/// A fake Beef install under the bed: BeefBuild at `exe` (relative to the bed's root), the
	/// BeefConfig.toml beside it naming `libraries` (none: no config), and corlib at `corlib`
	/// (relative to the root; empty: none). Its BeefBuild's path.
	public static void FakeInstall(ProjectBuildBed bed, StringView exe, StringView libraries, StringView corlib, String outBeefBuild)
	{
		let file = BuildLayout.ExecutableName(exe, .. scope .());
		Write(bed.Root, file, "#!beefbuild\n");
		if (!libraries.IsEmpty)
		{
			let dir = PathParent(file, .. scope .());
			Write(bed.Root, scope $"{dir}/BeefConfig.toml", scope $"Version = 1\nUnversionedLibDirs = [{libraries}]\n");
		}
		if (!corlib.IsEmpty)
			Write(bed.Root, scope $"{corlib}/BeefProj.toml", "FileVersion = 1\n");
		PathJoin(bed.Root, file, outBeefBuild);
	}

	/// An Emscripten folder with emcc in it, for the fake installs; its path.
	public static void FakeEmscripten(ProjectBuildBed bed, StringView name, String outPath)
	{
		PathJoin(bed.Root, name, outPath);
		Write(outPath, BuildLayout.ExecutableName(ProjectBuild.cEmccPath, .. scope .()), "#!emcc\n");
	}
}
