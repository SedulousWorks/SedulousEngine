using System;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Engine.Scene;

namespace Sedulous.Engine.Scene.Tests;

/// A Context level subsystem that REACTS to the scene lifecycle and leaves assembly to the
/// composition, which is the split a real domain has.
class FakeRenderSubsystem : Subsystem, ISceneObserver
{
	public int Ready = 0;
	public int Destroyed = 0;

	protected override void OnReady()
	{
		if (let scenes = Context.GetSubsystem<SceneSubsystem>())
		{
			scenes.RegisterObserver(this, .SystemsReady);
			scenes.RegisterObserver(this, .Destroying);
		}
	}

	public void OnSystemsReady(Scene scene) { Ready++; }
	public void OnDestroying(Scene scene) { Destroyed++; }
}
