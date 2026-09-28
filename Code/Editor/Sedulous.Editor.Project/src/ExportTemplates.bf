using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Core;

/// The template operations: the manifest file, the host synthesis, creating a bundle from a
/// build, importing and removing one, and where the templates root is.
static class ExportTemplates
{
	public const String cManifestFile = "template.xml";
	public const String cRootEnvironmentVariable = "SEDULOUS_TEMPLATES_DIR";

	public static Result<void, ErrorCode> LoadManifest(IFileSystem root, ExportTemplate outTemplate, StringView fileName = cManifestFile)
	{
		if (XmlDocumentFile.Load(root, outTemplate, fileName) case .Err(let error))
			return .Err(error);
		if (outTemplate.Config.IsEmpty)
			outTemplate.Config.Set("Release");
		return .Ok;
	}

	public static Result<void, ErrorCode> SaveManifest(IWritableFileSystem writable, ExportTemplate template, StringView fileName = cManifestFile)
		=> XmlDocumentFile.Save(writable, template, fileName);

	/// The host implicit template from a player directory, the one beside the running tool:
	/// the platform, config and compiler of this build, the player, and the shared libraries
	/// beside it as the sidecars.
	public static void SynthesizeHost(StringView playerDir, ExportTemplate outTemplate)
	{
		outTemplate.Platform.Set(BuildLayout.HostPlatformName);
		outTemplate.Config.Set(BuildLayout.BuildConfigName);
		outTemplate.Compiler.Set(BuildLayout.cCompilerName);
		outTemplate.Id.Set(scope $"host-{outTemplate.Platform}-{outTemplate.Config}");
		outTemplate.Name.Set(scope $"{outTemplate.Platform} {outTemplate.Config} (host build)");
		outTemplate.EngineVersion.Set(EngineVersion.String);
		BuildLayout.ExecutableName(BuildLayout.cPlayerBaseName, outTemplate.PlayerBinary);
		outTemplate.Directory.Set(playerDir);
		outTemplate.IsHost = true;
		ClearAndDeleteItems(outTemplate.Sidecars);
		if (DirectoryExists(playerDir))
			BuildLayout.CollectSharedLibraries(playerDir, outTemplate.Sidecars);
	}

	public static void DefaultRoot(String outPath) => PathJoin(GetUserDataDirectory(.. scope .()), "templates", outPath);

	/// An explicit override, else $SEDULOUS_TEMPLATES_DIR, else <user-data>/templates.
	public static void ResolveRoot(StringView overrideRoot, String outPath)
	{
		if (!overrideRoot.IsEmpty)
		{
			outPath.Set(overrideRoot);
			return;
		}
		let env = scope String();
		if ((Environment.GetEnvironmentVariable(cRootEnvironmentVariable, env) case .Ok) && !env.IsEmpty)
		{
			outPath.Set(env);
			return;
		}
		DefaultRoot(outPath);
	}

	/// Empty and the host's own version both match; only a foreign stamp does not.
	public static bool EngineMatches(ExportTemplate template)
		=> template.EngineVersion.IsEmpty || (template.EngineVersion == EngineVersion.String);

	/// Packages a build's player directory into a template bundle: the manifest synthesized
	/// from it, the config and platform read off the build directory, a web dist recognised
	/// by its page. Install puts it under <destRoot>/<id>, ExportFolder into <destRoot>.
	public static Result<void, ErrorCode> Create(StringView playerDir, StringView destRoot, TemplateOutput mode,
		String outId = null, String outDir = null)
	{
		let template = scope ExportTemplate();
		SynthesizeHost(playerDir, template);
		template.IsHost = false;
		let webPage = scope $"{BuildLayout.cWebPlayerBaseName}.html";
		if (FileExists(PathJoin(playerDir, webPage, .. scope .())))
		{
			template.Platform.Set(BuildLayout.cWebPlatform);
			template.PlayerBinary.Set(webPage);
			template.Compiler.Set("Emscripten");
			// A web dist is another toolchain's build: the tool's own config says nothing
			// about it, so only its build directory can name one, else Release.
			template.Config.Clear();
			ClearAndDeleteItems(template.Sidecars);
			BuildLayout.CollectWebParts(playerDir, webPage, template.Sidecars);
		}
		let parsedConfig = scope String();
		let parsedPlatform = scope String();
		BuildLayout.ParseBuildDirectory(playerDir, parsedConfig, parsedPlatform);
		if (!parsedConfig.IsEmpty)
			template.Config.Set(parsedConfig);
		if (template.Config.IsEmpty)
			template.Config.Set("Release");
		if (!parsedPlatform.IsEmpty && (template.Platform != BuildLayout.cWebPlatform))
			template.Platform.Set(parsedPlatform);

		template.Id.Set(scope $"{BuildLayout.cTemplateIdPrefix}-{scope String(template.Platform)..ToLower()}-{scope String(template.Config)..ToLower()}-{template.EngineVersion}");
		template.Name.Set(scope $"{template.Platform} {template.Config} {template.EngineVersion}");
		if (!FileExists(PathJoin(playerDir, template.PlayerBinary, .. scope .())))
			return .Err(.NotFound);

		let bundleDir = scope String();
		if (mode == .Install)
			PathJoin(destRoot, template.Id, bundleDir);
		else
			bundleDir.Set(destRoot);
		if (!CreateDirectory(bundleDir))
			return .Err(.NotSupported);
		if (!CopyFile(playerDir, template.PlayerBinary, bundleDir, template.PlayerBinary))
			return .Err(.Internal);
		for (let sidecar in template.Sidecars)
			if (!CopyFile(playerDir, sidecar, bundleDir, sidecar))
				return .Err(.Internal);
		template.Directory.Set(bundleDir);
		let bundleFs = scope NativeFileSystem(bundleDir);
		if (SaveManifest(bundleFs, template) case .Err(let error))
			return .Err(error);
		if (outId != null)
			outId.Set(template.Id);
		if (outDir != null)
			outDir.Set(bundleDir);
		return .Ok;
	}

	/// Installs a bundle from `srcDir` into the templates root under its manifest's id.
	public static Result<void, ErrorCode> Import(StringView srcDir, StringView templatesRoot, String outId = null)
	{
		let srcFs = scope NativeFileSystem(srcDir);
		let manifest = scope ExportTemplate();
		if ((LoadManifest(srcFs, manifest) case .Err) || manifest.Id.IsEmpty)
			return .Err(.NotFound);
		CreateDirectory(templatesRoot);
		let dst = PathJoin(templatesRoot, manifest.Id, .. scope .());
		if (!CopyTree(srcDir, dst))
			return .Err(.Internal);
		if (outId != null)
			outId.Set(manifest.Id);
		return .Ok;
	}

	/// Deletes an installed bundle; NotFound when there is none.
	public static Result<void, ErrorCode> Remove(StringView templatesRoot, StringView templateId)
	{
		if (templateId.IsEmpty)
			return .Err(.InvalidArgument);
		let dir = PathJoin(templatesRoot, templateId, .. scope .());
		if (!DirectoryExists(dir))
			return .Err(.NotFound);
		return RemoveDirectoryRecursive(dir) ? .Ok : .Err(.Internal);
	}

	/// A file copied between directories; the caller's names.
	public static bool CopyFile(StringView srcDir, StringView srcName, StringView dstDir, StringView dstName)
	{
		let bytes = scope List<uint8>();
		if (ReadFile(PathJoin(srcDir, srcName, .. scope .()), bytes) case .Err)
			return false;
		let dst = PathJoin(dstDir, dstName, .. scope .());
		CreateDirectory(PathParent(dst, .. scope .()));
		return WriteFile(dst, bytes) case .Ok;
	}

	/// A directory tree copied, files overwritten.
	public static bool CopyTree(StringView src, StringView dst)
	{
		if (!CreateDirectory(dst))
			return false;
		bool ok = true;
		let names = scope List<(String name, bool isDirectory)>();
		ListDirectory(src, scope [&](name, isDirectory) => { names.Add((new String(name), isDirectory)); });
		for (let entry in names)
		{
			if (entry.isDirectory)
				ok = CopyTree(PathJoin(src, entry.name, .. scope .()), PathJoin(dst, entry.name, .. scope .())) && ok;
			else
				ok = CopyFile(src, entry.name, dst, entry.name) && ok;
			delete entry.name;
		}
		return ok;
	}
}
