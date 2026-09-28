using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Core;

/// A project's export presets: the root of <project>/export_presets.xml.
[Serializable(3)]
class ExportPresetSet
{
	public List<ExportPreset> Presets = new .() ~ DeleteContainerAndItems!(_);

	/// By name, case sensitive; null when absent.
	public ExportPreset Find(StringView presetName)
	{
		for (let preset in Presets)
			if (preset.Name == presetName)
				return preset;
		return null;
	}
}
