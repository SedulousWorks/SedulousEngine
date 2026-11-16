using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Engine.Render;
using Sedulous.Profiler;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// Ticks every graph animation in the animation phase, exactly as the clip manager does but
/// evaluating a graph player.
///
/// It runs at a LOWER update order than the clip manager, so a graph backed entity is driven
/// by its graph. An entity is expected to carry one or the other: both pose the same mesh, and
/// drawing takes the palette of the first to answer, this one. Time is simulation gated and
/// the pose is not, as in the clip manager (see its comment).
class AnimationGraphComponentManager : ResourceBindingComponentManager<AnimationGraphComponent>, ISkinningPaletteSource
{
	/// BORROWED: the scene outlives its systems.
	private Scene mScene = null;
	/// Which of its animators posed each mesh at the last update.
	private PosedMeshes mPosed = new .() ~ delete _;
	/// The one-shots that ended since the last DrainEnded.
	private List<OneShotEnded> mEnded = new .() ~ delete _;
	/// The clip events passed since the last DrainEvents.
	private List<ClipEventFired> mEvents = new .() ~ DeleteContainerAndItems!(_);

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
	}

	/// Before the clip manager, which sits at nought.
	public override int32 UpdateOrder => -1;

	protected override void OnComponentCreated(AnimationGraphComponent* component,
		EntityHandle entity)
	{
		component.MeshEntities = new List<EntityRef>();
	}

	/// The base's destructor sweeps the components through OnComponentDestroyed; mid teardown the
	/// scene's other systems may be gone, so a driven character is not released then.
	public ~this()
	{
		mScene = null;
	}

	protected override void OnComponentDestroyed(AnimationGraphComponent* component,
		EntityHandle entity)
	{
		// A character this animator was walking stops with it.
		if (mScene != null)
			RootMotionApply.Release(mScene, ref component.RootMotionState);
		DeleteAndNullify!(component.Player);
		DeleteAndNullify!(component.MeshEntities);
		component.PlayerSkeleton = null;
		component.PlayerGraph = null;
	}

	// ---- the parameters ----
	//
	// The player is built on the first tick that has a skeleton and a graph; before then
	// these are no-ops. An unknown name is a no-op in the player.

	public void SetFloat(EntityHandle entity, StringView name, float value)
	{
		if (let player = Player(entity))
			player.SetFloat(name, value);
	}

	public void SetInt(EntityHandle entity, StringView name, int32 value)
	{
		if (let player = Player(entity))
			player.SetInt(name, value);
	}

	public void SetBool(EntityHandle entity, StringView name, bool value)
	{
		if (let player = Player(entity))
			player.SetBool(name, value);
	}

	/// Fires a trigger; the graph consumes it on the transition that reads it.
	public void SetTrigger(EntityHandle entity, StringView name)
	{
		if (let player = Player(entity))
			player.SetTrigger(name);
	}

	// ---- one-shots: a clip once over whatever state the graph is in, blended in and out ----

	/// Asks for `clip` to play over the entity's graph once its clip has loaded. One already
	/// playing gives way.
	public void PlayOneShot(EntityHandle entity, Guid clip, OneShotSettings settings)
	{
		let component = Get(entity);
		if (component != null)
			OneShots.Request(ref component.OneShot, Resources, clip, settings);
	}

	/// Blends the entity's one-shot out over `blendOut` seconds; it then reports its end.
	public void StopOneShot(EntityHandle entity, float blendOut)
	{
		let component = Get(entity);
		if (component != null)
			OneShots.Stop(ref component.OneShot, component.Player?.Overlay, blendOut);
	}

	/// From the request until the one-shot has blended out.
	public bool IsPlayingOneShot(EntityHandle entity)
	{
		let component = Get(entity);
		return (component != null) && OneShots.IsPlaying(component.OneShot, component.Player?.Overlay);
	}

	/// The one-shots that ended since the last call, added to `outEnded` (the animation
	/// subsystem tells its listeners).
	/// The clip events passed since the last call, handed to `outEvents`, which owns them.
	public void DrainEvents(List<ClipEventFired> outEvents)
	{
		outEvents.AddRange(mEvents);
		mEvents.Clear();
	}

	public void DrainEnded(List<OneShotEnded> outEnded)
	{
		outEnded.AddRange(mEnded);
		mEnded.Clear();
	}

	private AnimationGraphPlayer Player(EntityHandle entity)
	{
		let component = Get(entity);
		return (component != null) ? component.Player : null;
	}

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if ((phase != .PostUpdate) || (mScene == null))
			return;

		let meshes = mScene.GetSystem<MeshComponentManager>();
		if (meshes == null)
			return;

		using (ProfileScope("Animation.Graph"))
		{
			// Recorded again below: an animator gone, or a mesh it stopped naming, drops out.
			mPosed.Clear();
			ForEach(scope (component, owner) =>
				{
					Tick(meshes, component, owner, deltaTime);
				});
		}
	}

	private void Tick(MeshComponentManager meshes, AnimationGraphComponent* component,
		EntityHandle owner, float deltaTime)
	{
		// Recorded first, so a frozen animator's meshes keep its last pose.
		mPosed.RecordAll(mScene, meshes, owner, component.MeshEntities);
		// Frozen.
		if (!mScene.IsEffectivelyActive(owner))
		{
			RootMotionApply.Release(mScene, ref component.RootMotionState);
			return;
		}

		let skeleton = component.Skeleton.Get;
		let graph = component.Graph.Get;
		if ((skeleton == null) || (graph == null))
		{
			RootMotionApply.Release(mScene, ref component.RootMotionState);
			return;
		}

		// (Re)build when EITHER object changed: the first tick, a pick, a reload.
		if ((component.Player == null) || (component.PlayerSkeleton !== skeleton)
			|| (component.PlayerGraph !== graph))
		{
			delete component.Player;
			component.Player = new AnimationGraphPlayer(graph, skeleton);
			// Its clip events, for the animation subsystem to tell its listeners.
			component.Player.SetEventHandler(new (name, time) => { mEvents.Add(new ClipEventFired(owner, name)); });
			component.PlayerSkeleton = skeleton;
			component.PlayerGraph = graph;
		}

		if (!component.Active)
		{
			RootMotionApply.Release(mScene, ref component.RootMotionState);
			return;
		}

		if (mScene.SimulationEnabled)
		{
			OneShots.Start(ref component.OneShot, component.Player.Overlay);
			component.Player.Update(deltaTime);
			OneShots.Ended(ref component.OneShot, component.Player.ConsumeOneShotEnded(), owner, mEnded);
			RootMotionApply.Apply(mScene, owner, component.MeshEntities, component.RootMotionTarget, component.RootMotion,
				ref component.RootMotionState, component.Player.ConsumeRootMotion(), deltaTime);
		}
		else
		{
			RootMotionApply.Release(mScene, ref component.RootMotionState);
		}

		// The pose is evaluated here, once a frame, whether or not anything draws it: its
		// modifiers (foot IK's ground probes) step with the frame, not with a reader.
		component.Player.GetSkinningMatrices();
	}

	public override ISkinningPaletteSource AsSkinningPaletteSource => this;

	/// The palette of the animator that posed `mesh` at its last update, read from its player
	/// as it is now; false once the animator is gone (its player with it): the mesh draws static.
	public bool SkinningPaletteOf(EntityHandle mesh, out SkinningPalette outPalette)
	{
		outPalette = .();
		let animator = mPosed.AnimatorOf(mesh);
		let component = animator.IsAssigned ? Get(animator) : null;
		if ((component == null) || (component.Player == null))
			return false;
		let current = component.Player.EvaluatedSkinningMatrices;
		outPalette.Current = current.Ptr;
		outPalette.Previous = component.Player.GetPrevSkinningMatrices().Ptr;
		outPalette.BoneCount = (uint32)current.Length;
		return true;
	}
}
