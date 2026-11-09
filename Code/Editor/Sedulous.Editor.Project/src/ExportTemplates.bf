using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using System.Threading;
using Sedulous.Runtime;
using Sedulous.VFS;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// What a created template is called, when not its canonical id and name: a second bundle for
/// one platform (the Steam Deck build beside the desktop Linux one) sits beside the first rather
/// than replacing it. Empty fields keep the canonical ones.
struct TemplateIdentity
{
	public StringView Id;
	public StringView Name;
	public StringView Notes;
	/// A built-in icon's name (PlatformIcons.BuiltInNames: `handheld` for the Steam Deck build)
	/// or the path of an .svg to carry; empty gives the platform's built-in icon.
	public StringView Icon;
	/// Where the packages of the plugins the player links are (an engine checkout's Code/Plugins),
	/// for their files; empty: the checkout the player's build directory is in.
	public StringView PluginsRoot;
}

/// The template operations: the manifest file, the host synthesis, creating a bundle from a
/// build, importing and removing one, and where the templates root is.
static class ExportTemplates
{
	public const String cManifestFile = "template.xml";
	public const String cRootEnvironmentVariable = "SEDULOUS_TEMPLATES_DIR";
	/// The icon's file in a template bundle, the one creating a template writes.
	public const String cIconFile = "icon.svg";

	/// The SVG a template is shown by: the icon file in its bundle, or (the host template, a
	/// bundle from before icons, an unreadable file) its platform's built-in icon.
	public static void IconSvg(ExportTemplate template, String outSvg)
	{
		if (!template.Icon.IsEmpty && !template.Directory.IsEmpty)
		{
			let bytes = scope List<uint8>();
			if ((ReadFile(PathJoin(template.Directory, template.Icon, .. scope .()), bytes) case .Ok) && !bytes.IsEmpty)
			{
				outSvg.Append((char8*)bytes.Ptr, bytes.Count);
				return;
			}
		}
		outSvg.Append(PlatformIcons.SvgFor(template.Platform));
	}

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
		// The shader compiler is the editor's, not the player's, which renders from the
		// cooked shader pack: a template never carries it. It would only add weight, and its
		// glibc floor would keep a template off an older system (the Steam Deck's).
		for (int i = outTemplate.Sidecars.Count - 1; i >= 0; i--)
		{
			if (ExportStaging.IsDxcRuntimeLib(outTemplate.Sidecars[i]))
			{
				delete outTemplate.Sidecars[i];
				outTemplate.Sidecars.RemoveAt(i);
			}
		}
		// The third-party notices go with every copy of the player, a template and an export
		// included.
		if (FileExists(PathJoin(playerDir, BuildLayout.cThirdPartyNotices, .. scope .())))
			outTemplate.Sidecars.Add(new String(BuildLayout.cThirdPartyNotices));
		// The plugins it links, as its --plugins lists them, and where their packages are.
		ClearAndDeleteItems(outTemplate.Plugins);
		PackagesRootOf(playerDir, outTemplate.PackagesRoot);
		HostPlugins(PathJoin(playerDir, outTemplate.PlayerBinary, .. scope .()), outTemplate.Plugins);
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
	/// by its page. Install puts it under <destRoot>/<id>, ExportFolder into <destRoot>. The
	/// identity, when given, replaces the canonical id, name and notes, and names its icon (an
	/// unknown name is InvalidArgument, a missing .svg NotFound, both before anything is written).
	public static Result<void, ErrorCode> Create(StringView playerDir, StringView destRoot, TemplateOutput mode,
		String outId = null, String outDir = null, TemplateIdentity identity = .())
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
			// about it, so only its folder can name one: the profiling build's dist-profile,
			// else the shipping build's.
			template.Config.Clear();
			if (PathFilename(scope String(playerDir)..TrimEnd('/')..TrimEnd('\\'), .. scope .()) == BuildLayout.cWebProfileDist)
				template.Config.Set("Profile");
			ClearAndDeleteItems(template.Sidecars);
			BuildLayout.CollectWebParts(playerDir, webPage, template.Sidecars);
			ClearAndDeleteItems(template.Plugins); // the web player links none
		}
		let parsedConfig = scope String();
		let parsedPlatform = scope String();
		BuildLayout.ParseBuildDirectory(playerDir, parsedConfig, parsedPlatform);
		if (!parsedConfig.IsEmpty)
			template.Config.Set(BuildLayout.TemplateConfigFor(parsedConfig));
		if (template.Config.IsEmpty)
			template.Config.Set("Release");
		if (!parsedPlatform.IsEmpty && (template.Platform != BuildLayout.cWebPlatform))
			template.Platform.Set(parsedPlatform);

		template.Id.Set(scope $"{BuildLayout.cTemplateIdPrefix}-{scope String(template.Platform)..ToLower()}-{scope String(template.Config)..ToLower()}-{template.EngineVersion}");
		template.Name.Set(scope $"{template.Platform} {template.Config} {template.EngineVersion}");
		if (!identity.Id.IsEmpty)
			template.Id.Set(identity.Id);
		if (!identity.Name.IsEmpty)
			template.Name.Set(identity.Name);
		if (!identity.Notes.IsEmpty)
			template.Notes.Set(identity.Notes);
		if (!FileExists(PathJoin(playerDir, template.PlayerBinary, .. scope .())))
			return .Err(.NotFound);

		// The icon the template carries: an .svg given by path is copied in; otherwise the
		// built-in one named, or the platform's. Refused rather than shipping without the icon
		// its maker asked for.
		let customIcon = identity.Icon.EndsWith(".svg");
		let builtInIcon = customIcon ? StringView() :
			PlatformIcons.BuiltInSvg(identity.Icon.IsEmpty ? PlatformIcons.DefaultName(template.Platform) : identity.Icon);
		if (customIcon && !FileExists(identity.Icon))
			return .Err(.NotFound);
		if (!customIcon && builtInIcon.IsEmpty)
			return .Err(.InvalidArgument);

		let bundleDir = scope String();
		if (mode == .Install)
		{
			PathJoin(destRoot, template.Id, bundleDir);
			// Installing an id REPLACES its bundle: a sidecar the new build no longer has must
			// not linger and ship with every export made from it.
			if (DirectoryExists(bundleDir))
				RemoveDirectoryRecursive(bundleDir);
		}
		else
		{
			bundleDir.Set(destRoot);
		}
		if (!CreateDirectory(bundleDir))
			return .Err(.NotSupported);
		if (!FileCopy.CopyFile(playerDir, template.PlayerBinary, bundleDir, template.PlayerBinary))
			return .Err(.Internal);
		for (let sidecar in template.Sidecars)
			if (!FileCopy.CopyFile(playerDir, sidecar, bundleDir, sidecar))
				return .Err(.Internal);
		if (CarryPluginFiles(template, identity.PluginsRoot.IsEmpty ? StringView(template.PackagesRoot) : identity.PluginsRoot, bundleDir) case .Err(let carried))
			return .Err(carried);
		// Read and written whole: a copy over a longer icon must not keep its tail.
		let iconBytes = scope List<uint8>();
		if (customIcon)
		{
			if (ReadFile(identity.Icon, iconBytes) case .Err)
				return .Err(.NotFound);
		}
		else
			iconBytes.AddRange(.((uint8*)builtInIcon.Ptr, builtInIcon.Length));
		if (WriteFile(PathJoin(bundleDir, cIconFile, .. scope .()), iconBytes) case .Err)
			return .Err(.Internal);
		template.Icon.Set(cIconFile);
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

	// ---- the plugins a template's player links ----

	/// Where a bundle carries its plugins' files: plugins/<id>/, each its Plugin.xml and its deploy
	/// files for the template's platform.
	public const String cPluginsDir = "plugins";

	/// The plugins in a player's --plugins output, one `id|version` line each, appended. A line
	/// without the bar is not one (an older player, asked as ReadPlayerPlugins asks, prints its
	/// version instead).
	public static void ParsePlugins(StringView lines, List<TemplatePlugin> outPlugins)
	{
		for (var line in lines.Split('\n'))
		{
			line.Trim();
			let bar = line.IndexOf('|');
			if (bar <= 0)
				continue;
			let plugin = new TemplatePlugin();
			plugin.Id.Set(line.Substring(0, bar));
			plugin.Version.Set(line.Substring(bar + 1));
			outPlugins.Add(plugin);
		}
	}

	/// The plugins the player at `playerPath` links, appended: it is run for its --plugins, with
	/// --version after it, so a player from before the flag prints its version and lists nothing
	/// rather than starting a game. None for a player that does not run here.
	public static void ReadPlayerPlugins(StringView playerPath, List<TemplatePlugin> outPlugins)
	{
		let result = scope ProcessResult();
		Process.Run(playerPath, scope StringView[]("--plugins", "--version"), result);
		if (result.ExitCode == 0)
			ParsePlugins(result.Output, outPlugins);
	}

	/// The host template's plugins, by the player's modification time: refreshing the registry
	/// runs the player only when it was rebuilt.
	private static Monitor sHostPluginsLock = new .() ~ delete _;
	private static String sHostPluginsPlayer = new .() ~ delete _;
	private static int64 sHostPluginsTicks = 0;
	private static List<TemplatePlugin> sHostPlugins = new .() ~ DeleteContainerAndItems!(_);

	private static void HostPlugins(StringView playerPath, List<TemplatePlugin> outPlugins)
	{
		if (!FileStat(playerPath, let size, let ticks))
			return;
		using (sHostPluginsLock.Enter())
		{
			if ((sHostPluginsPlayer != playerPath) || (sHostPluginsTicks != ticks))
			{
				ClearAndDeleteItems!(sHostPlugins);
				ReadPlayerPlugins(playerPath, sHostPlugins);
				sHostPluginsPlayer.Set(playerPath);
				sHostPluginsTicks = ticks;
			}
			for (let plugin in sHostPlugins)
			{
				let copy = new TemplatePlugin();
				copy.Id.Set(plugin.Id);
				copy.Version.Set(plugin.Version);
				outPlugins.Add(copy);
			}
		}
	}

	/// The engine checkout's plugin packages a player in its build directory was built from:
	/// <checkout>/Code/Plugins, three folders above build/<Config>_<Platform>/<Player>. Empty when
	/// there is none.
	public static void PackagesRootOf(StringView playerDir, String outRoot)
	{
		outRoot.Clear();
		let trimmed = scope String(playerDir);
		while (trimmed.EndsWith("/") || trimmed.EndsWith("\\"))
			trimmed.RemoveFromEnd(1);
		let code = PathParent(PathParent(PathParent(trimmed, .. scope .()), .. scope .()), .. scope .());
		let root = PathJoin(code, "Plugins", .. scope .());
		if (!code.IsEmpty && DirectoryExists(root))
			outRoot.Set(root);
	}

	/// Copies each of `template`'s plugins' Plugin.xml and its deploy files for the template's
	/// platform from its package under `packagesRoot` into `bundleDir`/plugins/<id>/, so an export
	/// has them with no engine checkout. A plugin with no package there is warned about and carries
	/// nothing; a deploy file its manifest names that is not there fails.
	private static Result<void, ErrorCode> CarryPluginFiles(ExportTemplate template, StringView packagesRoot, StringView bundleDir)
	{
		for (let plugin in template.Plugins)
		{
			let package = scope String();
			if (!PluginPackages.FindPackage(packagesRoot, plugin.Id, package))
			{
				GlobalLog(.Warning, "Template: the player links plugin '{}', whose package is not under '{}': its files are not carried", plugin.Id, packagesRoot);
				continue;
			}
			let into = PathJoin(PathJoin(bundleDir, cPluginsDir, .. scope .()), plugin.Id, .. scope .());
			CreateDirectory(PathJoin(bundleDir, cPluginsDir, .. scope .()));
			CreateDirectory(into);
			if (!FileCopy.CopyFile(package, PluginManifest.cFileName, into, PluginManifest.cFileName))
				return .Err(.Internal);
			let manifest = scope PluginManifest();
			if (PluginManifest.Load(package, manifest) case .Err)
				return .Err(.Internal);
			if (let platform = manifest.FindPlatform(template.Platform))
			{
				for (let file in platform.Deploy)
				{
					if (!FileCopy.CopyFile(package, file, into, file))
					{
						GlobalLog(.Error, "Template: plugin '{}' deploys '{}' on {}, which its package lacks", plugin.Id, file, template.Platform);
						return .Err(.NotFound);
					}
				}
			}
		}
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
		// As an install does, the bundle is replaced whole; unless it IS the source, a bundle
		// re-imported from where it is installed.
		if (DirectoryExists(dst) && !SameDirectory(srcDir, dst))
			RemoveDirectoryRecursive(dst);
		if (!FileCopy.CopyTree(srcDir, dst))
			return .Err(.Internal);
		if (outId != null)
			outId.Set(manifest.Id);
		return .Ok;
	}

	private static bool SameDirectory(StringView a, StringView b)
	{
		let fullA = System.IO.Path.GetFullPath(a, .. scope .());
		let fullB = System.IO.Path.GetFullPath(b, .. scope .());
		while (fullA.EndsWith("/") || fullA.EndsWith("\\"))
			fullA.RemoveFromEnd(1);
		while (fullB.EndsWith("/") || fullB.EndsWith("\\"))
			fullB.RemoveFromEnd(1);
		return fullA == fullB;
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
}
