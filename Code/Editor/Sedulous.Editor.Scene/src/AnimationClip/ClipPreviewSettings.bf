using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Scene;

/// The settings section holding every clip's preview rig.
[Serializable(1)]
class ClipPreviewSettings
{
	public List<ClipPreviewPref> Prefs = new .() ~ DeleteContainerAndItems!(_);
}
