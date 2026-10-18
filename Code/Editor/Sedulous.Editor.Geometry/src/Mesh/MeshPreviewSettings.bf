using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Geometry;

/// The settings section holding every mesh's preview material choice.
[Serializable(1)]
class MeshPreviewSettings
{
	public List<MeshPreviewPref> Prefs = new .() ~ DeleteContainerAndItems!(_);
}
