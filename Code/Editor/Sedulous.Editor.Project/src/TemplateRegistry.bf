using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;

namespace Sedulous.Editor.Core;

/// The templates available to an export: every bundle under the templates root, plus the
/// host implicit template synthesized from the player beside the running tool. An
/// imported template out-ranks the host for the same platform and config.
class TemplateRegistry
{
	private List<ExportTemplate> mTemplates = new .() ~ DeleteContainerAndItems!(_);

	/// Rescans: the bundles under `templatesRoot`, empty for none, and the host from
	/// `playerDir`.
	public void Refresh(StringView templatesRoot, StringView playerDir)
	{
		ClearAndDeleteItems(mTemplates);
		if (!templatesRoot.IsEmpty && DirectoryExists(templatesRoot))
		{
			let names = scope List<String>();
			defer { ClearAndDeleteItems(names); }
			ListDirectory(templatesRoot, scope [&](name, isDirectory) => { if (isDirectory) names.Add(new String(name)); });
			names.Sort(scope (a, b) => a <=> b);
			let rootFs = scope NativeFileSystem(templatesRoot);
			for (let name in names)
			{
				let template = new ExportTemplate();
				if (ExportTemplates.LoadManifest(rootFs, template, PathJoin(name, ExportTemplates.cManifestFile, .. scope .())) case .Ok)
				{
					PathJoin(templatesRoot, name, template.Directory);
					template.IsHost = false;
					mTemplates.Add(template);
				}
				else
				{
					delete template;
				}
			}
		}
		let host = new ExportTemplate();
		ExportTemplates.SynthesizeHost(playerDir, host);
		mTemplates.Add(host);
	}

	public int Count => mTemplates.Count;
	public ExportTemplate At(int index) => mTemplates[index];

	public ExportTemplate FindById(StringView id)
	{
		for (let template in mTemplates)
			if (template.Id == id)
				return template;
		return null;
	}

	/// The exact platform and config, an imported bundle before the host; else the best of
	/// the platform, preferring Release, imported before host.
	public ExportTemplate FindBy(StringView platform, StringView config)
	{
		let wantConfig = config.IsEmpty ? "Release" : config;
		ExportTemplate exactHost = null;
		for (let template in mTemplates)
		{
			if ((template.Platform != platform) || (template.EffectiveConfig != wantConfig))
				continue;
			if (template.IsHost)
				exactHost = template;
			else
				return template;
		}
		if (exactHost != null)
			return exactHost;
		ExportTemplate bestImported = null;
		bool bestImportedRelease = false;
		ExportTemplate bestHost = null;
		bool bestHostRelease = false;
		for (let template in mTemplates)
		{
			if (template.Platform != platform)
				continue;
			let isRelease = template.EffectiveConfig == "Release";
			if (template.IsHost)
			{
				if ((bestHost == null) || (isRelease && !bestHostRelease))
				{
					bestHost = template;
					bestHostRelease = isRelease;
				}
			}
			else if ((bestImported == null) || (isRelease && !bestImportedRelease))
			{
				bestImported = template;
				bestImportedRelease = isRelease;
			}
		}
		return (bestImported != null) ? bestImported : bestHost;
	}

	public ExportTemplate Resolve(ExportPreset preset)
		=> preset.TemplateId.IsEmpty ? FindBy(preset.Platform, preset.Config) : FindById(preset.TemplateId);
}
