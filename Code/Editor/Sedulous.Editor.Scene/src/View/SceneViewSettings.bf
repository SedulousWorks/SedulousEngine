using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Scene;

/// The settings section holding every scene's view state, one entry per scene edited.
[Serializable(3)]
class SceneViewSettings
{
	public List<SceneViewPref> Prefs = new .() ~ DeleteContainerAndItems!(_);
}
