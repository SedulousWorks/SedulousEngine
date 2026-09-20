using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Scene;

/// The settings section holding every material's preview choice.
[Serializable(1)]
class MaterialPreviewSettings
{
	public List<MaterialPreviewPref> Prefs = new .() ~ DeleteContainerAndItems!(_);
}
