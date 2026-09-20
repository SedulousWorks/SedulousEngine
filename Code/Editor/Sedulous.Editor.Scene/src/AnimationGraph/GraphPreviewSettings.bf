using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Scene;

/// The settings section holding every graph's preview rig.
[Serializable(1)]
class GraphPreviewSettings
{
	public List<GraphPreviewPref> Prefs = new .() ~ DeleteContainerAndItems!(_);
}
