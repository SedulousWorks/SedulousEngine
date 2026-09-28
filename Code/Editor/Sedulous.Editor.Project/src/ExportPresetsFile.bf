using System;
using Sedulous.Core;
using Sedulous.VFS;

namespace Sedulous.Editor.Core;

/// export_presets.xml on the project root, and the built in default when a project has none.
static class ExportPresetsFile
{
	public const String cFileName = "export_presets.xml";

	/// The built in default: one preset targeting the host platform, sourcing the player
	/// from the driving tool's own build.
	public static void Defaults(ExportPresetSet outSet)
	{
		ClearAndDeleteItems(outSet.Presets);
		let host = new ExportPreset();
		host.Platform.Set(BuildLayout.HostPlatformName);
		host.Name.Set(host.Platform);
		host.Name.Append(" Desktop");
		host.OutputSubdir.Set(host.Platform);
		outSet.Presets.Add(host);
	}

	/// NotFound when absent; the caller falls back to Defaults.
	public static Result<void, ErrorCode> Load(IFileSystem root, ExportPresetSet outSet, StringView fileName = cFileName)
		=> XmlDocumentFile.Load(root, outSet, fileName);

	public static Result<void, ErrorCode> Save(IWritableFileSystem writable, ExportPresetSet presets, StringView fileName = cFileName)
		=> XmlDocumentFile.Save(writable, presets, fileName);
}
