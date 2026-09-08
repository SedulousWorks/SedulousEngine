using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Scene.Resource;

/// The primary object of a prefab instance.
///
/// A DISTINCT type from SceneDocument so a browser, a creator and a picker can tell a
/// prefab from a scene. The stream format behind it is identical, which is what lets a
/// scene editor open a prefab unchanged.
[Serializable]
class PrefabDocument
{
	public String Name = new .() ~ delete _;
}
