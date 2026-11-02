using System;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Editor.Scene.Tests;

/// Measures every entity as one box far from the origin, as a render or physics domain answers:
/// content a view must look away from the origin to show.
class FarBox : SceneSystem, ISceneEntityBounds
{
	public static AABB Box => .(.(190.0f, 0.0f, -310.0f), .(210.0f, 10.0f, -290.0f));

	public override ISceneEntityBounds AsEntityBounds => this;

	public bool EntityBounds(Sedulous.Scene.Scene scene, EntityHandle entity, out AABB outBounds)
	{
		outBounds = Box;
		return true;
	}
}
