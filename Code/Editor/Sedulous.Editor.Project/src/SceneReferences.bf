using System;
using System.Collections;

namespace Sedulous.Editor.Core;

/// What a scene or prefab references directly.
class SceneReferences
{
	/// The component resource Ref ids: mesh, material, texture, ... instances.
	public List<Guid> Resources = new .() ~ delete _;
	/// The prefab instance ids nested in it.
	public List<Guid> Prefabs = new .() ~ delete _;
}
