namespace Sedulous.Engine.Core.Tests;

using System;

/// Component that tracks how many times it was updated.
class UpdateTracker : Component
{
	public int32 UpdateCount = 0;
	public float LastDeltaTime = 0;
}

/// Manager that registers for the Update phase.
class UpdateTrackerManager : ComponentManager<UpdateTracker>
{
	protected override void OnRegisterUpdateFunctions()
	{
		RegisterUpdate(.Update, new => OnUpdate);
	}

	private void OnUpdate(float deltaTime)
	{
		for (let comp in ActiveComponents)
		{
			comp.UpdateCount++;
			comp.LastDeltaTime = deltaTime;
		}
	}
}

/// Manager that registers for PostTransform (extraction).
class ExtractionTracker : Component
{
	public int32 ExtractCount = 0;
}

class ExtractionTrackerManager : ComponentManager<ExtractionTracker>
{
	protected override void OnRegisterUpdateFunctions()
	{
		RegisterUpdate(.PostTransform, new => OnPostTransform);
	}

	private void OnPostTransform(float deltaTime)
	{
		for (let comp in ActiveComponents)
			comp.ExtractCount++;
	}
}

class SceneUpdateTests
{
	[Test]
	public static void Update_CallsRegisteredPhaseFunction()
	{
		let scene = scope Scene();
		let manager = new UpdateTrackerManager();
		scene.AddModule(manager);

		let entity = scene.CreateEntity();
		let handle = manager.CreateComponent(entity);

		scene.Update(0.016f);

		let comp = manager.Get(handle);
		Test.Assert(comp.UpdateCount == 1);
		Test.Assert(Math.Abs(comp.LastDeltaTime - 0.016f) < 0.0001f);
	}

	[Test]
	public static void Update_MultipleFrames()
	{
		let scene = scope Scene();
		let manager = new UpdateTrackerManager();
		scene.AddModule(manager);

		let entity = scene.CreateEntity();
		let handle = manager.CreateComponent(entity);

		scene.Update(0.016f);
		scene.Update(0.016f);
		scene.Update(0.016f);

		Test.Assert(manager.Get(handle).UpdateCount == 3);
	}

	[Test]
	public static void PostTransform_RunsAfterTransformUpdate()
	{
		let scene = scope Scene();
		let manager = new ExtractionTrackerManager();
		scene.AddModule(manager);

		let entity = scene.CreateEntity();
		let handle = manager.CreateComponent(entity);

		scene.Update(0);

		Test.Assert(manager.Get(handle).ExtractCount == 1);
	}

	[Test]
	public static void DeferredDestroy_DuringUpdate()
	{
		let scene = scope Scene();
		let manager = new UpdateTrackerManager();
		scene.AddModule(manager);

		let entity = scene.CreateEntity();
		manager.CreateComponent(entity);

		// Direct destroy outside update should work immediately
		scene.Update(0);
		Test.Assert(scene.IsValid(entity));

		scene.DestroyEntity(entity);
		Test.Assert(!scene.IsValid(entity));
	}

	[Test]
	public static void MultipleManagers_BothUpdate()
	{
		let scene = scope Scene();
		let updateMgr = new UpdateTrackerManager();
		let extractMgr = new ExtractionTrackerManager();
		scene.AddModule(updateMgr);
		scene.AddModule(extractMgr);

		let entity = scene.CreateEntity();
		let uh = updateMgr.CreateComponent(entity);
		let eh = extractMgr.CreateComponent(entity);

		scene.Update(0.016f);

		Test.Assert(updateMgr.Get(uh).UpdateCount == 1);
		Test.Assert(extractMgr.Get(eh).ExtractCount == 1);
	}
}
