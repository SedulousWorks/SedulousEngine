namespace Sedulous.Scenes.Tests;

using System;

class FixedUpdateCounter : Component
{
	public int32 FixedCount = 0;
	public float LastFixedDelta = 0;
}

class FixedUpdateManager : ComponentManager<FixedUpdateCounter>
{
	protected override void OnRegisterUpdateFunctions()
	{
		RegisterFixedUpdate(new => OnFixedUpdate);
	}

	private void OnFixedUpdate(float fixedDelta)
	{
		for (let comp in ActiveComponents)
		{
			comp.FixedCount++;
			comp.LastFixedDelta = fixedDelta;
		}
	}
}

class FixedUpdateTests
{
	[Test]
	public static void FixedUpdate_CallsRegisteredFunction()
	{
		let scene = scope Scene();
		let manager = new FixedUpdateManager();
		scene.AddModule(manager);

		let entity = scene.CreateEntity();
		let handle = manager.CreateComponent(entity);

		scene.FixedUpdate(1.0f / 60.0f);

		let comp = manager.Get(handle);
		Test.Assert(comp.FixedCount == 1);
		Test.Assert(Math.Abs(comp.LastFixedDelta - 1.0f / 60.0f) < 0.0001f);
	}

	[Test]
	public static void FixedUpdate_MultipleSteps()
	{
		let scene = scope Scene();
		let manager = new FixedUpdateManager();
		scene.AddModule(manager);

		let entity = scene.CreateEntity();
		let handle = manager.CreateComponent(entity);

		scene.FixedUpdate(1.0f / 60.0f);
		scene.FixedUpdate(1.0f / 60.0f);
		scene.FixedUpdate(1.0f / 60.0f);

		Test.Assert(manager.Get(handle).FixedCount == 3);
	}

	[Test]
	public static void FixedUpdate_IndependentFromUpdate()
	{
		let scene = scope Scene();
		let fixedMgr = new FixedUpdateManager();
		let updateMgr = new UpdateTrackerManager();
		scene.AddModule(fixedMgr);
		scene.AddModule(updateMgr);

		let entity = scene.CreateEntity();
		let fh = fixedMgr.CreateComponent(entity);
		let uh = updateMgr.CreateComponent(entity);

		// Only fixed update
		scene.FixedUpdate(0.016f);

		Test.Assert(fixedMgr.Get(fh).FixedCount == 1);
		Test.Assert(updateMgr.Get(uh).UpdateCount == 0); // not called

		// Only regular update
		scene.Update(0.016f);

		Test.Assert(fixedMgr.Get(fh).FixedCount == 1); // not called again
		Test.Assert(updateMgr.Get(uh).UpdateCount == 1);
	}
}
