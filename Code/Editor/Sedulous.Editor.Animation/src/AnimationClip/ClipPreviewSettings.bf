using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Animation;

/// The settings section holding every clip's preview rig.
[Serializable(1)]
class ClipPreviewSettings
{
	public List<ClipPreviewPref> Prefs = new .() ~ DeleteContainerAndItems!(_);
}
