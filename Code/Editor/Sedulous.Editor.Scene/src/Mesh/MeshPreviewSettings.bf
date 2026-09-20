using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Scene;

/// The settings section holding every mesh's preview material choice.
[Serializable(1)]
class MeshPreviewSettings
{
	public List<MeshPreviewPref> Prefs = new .() ~ DeleteContainerAndItems!(_);
}
