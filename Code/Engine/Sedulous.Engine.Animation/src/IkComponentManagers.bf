using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Profiler;
using Sedulous.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// The animator an IK component drives, as found this frame.
struct IkAnimatorLink
{
	public EntityHandle Entity = .Invalid;
	/// Null until the animator builds its player. BORROWED.
	public PoseModifierStack Stack = null;
	/// BORROWED.
	public Skeleton Skeleton = null;
	/// Whose world is the skeleton's model space: the first mesh entity, else the animator.
	public EntityHandle ModelEntity = .Invalid;

	public this() {}
}

/// The values every IK component carries that its manager's shared step reads.
struct IkCommon
{
	public IkRuntime Runtime;
	public bool Active;
	public float Weight;
	public float FadeSeconds;
	public int32 Order;
	public bool DebugDraw;
}

/// Inverse kinematics on scene entities (inverse-kinematics.md P2): finding the animator, taking
/// a modifier off it, drawing a solve, and the script's view of an entity's components.
static class IkScene
{
	/// The animator on `entity` itself, if any (a graph before a single clip, as they tick).
	public static bool AnimatorOn(Scene scene, EntityHandle entity, out IkAnimatorLink outLink)
	{
		outLink = .();
		if (let graphs = scene.GetSystem<AnimationGraphComponentManager>())
		{
			if (let graph = graphs.Get(entity))
			{
				outLink.Entity = entity;
				outLink.Stack = graph.Player?.Modifiers;
				outLink.Skeleton = graph.PlayerSkeleton;
				outLink.ModelEntity = ModelEntity(scene, graph.MeshEntities, entity);
				return true;
			}
		}
		if (let clips = scene.GetSystem<SkeletalAnimationComponentManager>())
		{
			if (let clip = clips.Get(entity))
			{
				outLink.Entity = entity;
				outLink.Stack = clip.Player?.Modifiers;
				outLink.Skeleton = clip.PlayerSkeleton;
				outLink.ModelEntity = ModelEntity(scene, clip.MeshEntities, entity);
				return true;
			}
		}
		return false;
	}

	private static EntityHandle ModelEntity(Scene scene, List<EntityRef> meshes, EntityHandle animator)
	{
		if (meshes != null)
		{
			for (let mesh in meshes)
			{
				let e = scene.FindEntity(mesh.Id);
				if (scene.IsValid(e))
					return e;
			}
		}
		return animator;
	}

	/// The nearest animator at or above `from`.
	public static bool FindAnimator(Scene scene, EntityHandle from, out IkAnimatorLink outLink)
	{
		outLink = .();
		var e = from;
		for (int depth = 0; scene.IsValid(e) && (depth < 1024); depth++)
		{
			if (AnimatorOn(scene, e, out outLink))
				return true;
			e = scene.GetParent(e);
		}
		return false;
	}

	/// Takes a component's modifier off its animator's player, if both are still there: looked
	/// up afresh, since the player may have been rebuilt or gone.
	public static void Detach(Scene scene, IkRuntime runtime)
	{
		if ((runtime == null) || !scene.IsValid(runtime.Animator))
			return;
		if (AnimatorOn(scene, runtime.Animator, let link) && (link.Stack != null))
			link.Stack.Remove(runtime.Modifier);
	}

	/// The world point a component reaches for: its target entity, else the script's point,
	/// else its own entity. False when a named target entity is gone.
	public static bool TargetWorld(Scene scene, EntityRef target, IkRuntime runtime, EntityHandle owner,
		out Float4x4 outWorld)
	{
		if (!target.IsNil)
		{
			let e = scene.FindEntity(target.Id);
			if (!scene.IsValid(e))
			{
				outWorld = .Identity();
				return false;
			}
			outWorld = scene.ComposeWorldMatrix(e);
			return true;
		}
		if (runtime.HasScriptTarget)
		{
			outWorld = Float4x4.Translation(runtime.ScriptTarget);
			return true;
		}
		outWorld = scene.ComposeWorldMatrix(owner);
		return true;
	}

	/// Draws a component's last solve: the chain, its target (green reached, orange not), its pole.
	public static void Draw(DebugDraw draw, IkRuntime runtime)
	{
		let m = runtime?.Modifier;
		if ((m == null) || !m.Solved || (runtime.Status != .Solving))
			return;
		let chain = Color(0.3f, 0.7f, 1.0f, 1.0f);
		let reached = Color(0.2f, 0.9f, 0.3f, 1.0f);
		let missed = Color(1.0f, 0.55f, 0.1f, 1.0f);
		for (int i = 0; i + 1 < m.DrawnCount; i++)
			draw.DrawLine(m.ChainWorld[i], m.ChainWorld[i + 1], chain, true);
		for (int i < m.DrawnCount)
			draw.DrawWireSphere(m.ChainWorld[i], 0.02f, chain, 8, true);
		draw.DrawWireSphere(runtime.TargetWorld, 0.05f, m.Result.Reached ? reached : missed, 12, true);
		if (runtime.HasPoleWorld && (m.DrawnCount > 1))
			draw.DrawLine(m.ChainWorld[1], runtime.PoleWorld, Color(0.8f, 0.4f, 1.0f, 1.0f), true);
	}

	/// The IK components on an entity, as the script calls see them.
	private static void ForEachRuntime(Scene scene, EntityHandle entity, delegate void(IkRuntime) visit)
	{
		if (scene == null)
			return;
		if (let twoBone = scene.GetSystem<TwoBoneIkComponentManager>())
		{
			if (let c = twoBone.Get(entity))
				visit(c.Runtime);
		}
		if (let aim = scene.GetSystem<AimIkComponentManager>())
		{
			if (let c = aim.Get(entity))
				visit(c.Runtime);
		}
	}

	/// The world point the entity's IK components reach for while they name no target entity.
	public static void SetTarget(Scene scene, EntityHandle entity, Float3 worldPosition)
	{
		ForEachRuntime(scene, entity, scope (runtime) =>
			{
				runtime.HasScriptTarget = true;
				runtime.ScriptTarget = worldPosition;
			});
	}

	/// Whether every IK component on the entity reached its target on the last solve.
	public static bool Reached(Scene scene, EntityHandle entity)
	{
		var any = false;
		var all = true;
		ForEachRuntime(scene, entity, scope [&] (runtime) =>
			{
				any = true;
				all = all && (runtime.Status == .Solving) && runtime.Modifier.Solved && runtime.Modifier.Result.Reached;
			});
		return any && all;
	}

	/// The largest miss: metres for a two bone chain, radians for an aim.
	public static float Error(Scene scene, EntityHandle entity)
	{
		var worst = 0.0f;
		ForEachRuntime(scene, entity, scope [&] (runtime) =>
			{
				if (runtime.Modifier.Solved)
					worst = Math.Max(worst, runtime.Modifier.Result.Error);
			});
		return worst;
	}
}

/// The work every IK manager shares: the animator, the chain, the fade, the stack. A derived
/// manager supplies its components' common values, Resolve (bone names to indices; a failure
/// names what failed) and Fill (the frame's targets in model space).
///
/// Before the animation graph (-1) and single clip (0) managers, whose players run the solve.
abstract class IkComponentManagerBase<T> : SerializableComponentManager<T>
	where T : struct, ISerializable, new
{
	/// BORROWED: the scene outlives its systems. Null once the manager is being torn down.
	protected Scene mScene = null;

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
	}

	/// The base's destructor sweeps the components through OnComponentDestroyed. Mid teardown
	/// the animators may already be gone, so it must not look them up: a player left holding a
	/// modifier is torn down in the same teardown, with no tick in between.
	public ~this()
	{
		mScene = null;
	}

	public override bool IsSimulationOnly => true;
	public override int32 UpdateOrder => -2;

	protected abstract IkCommon Common(T* component);
	protected abstract IkStatus Resolve(T* component, Skeleton skeleton, String outFailed);
	protected abstract bool Fill(T* component, EntityHandle owner, Float4x4 worldToModel);

	protected void Detach(IkRuntime runtime)
	{
		if (mScene != null)
			IkScene.Detach(mScene, runtime);
	}

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if ((phase != .PostUpdate) || (mScene == null))
			return;
		using (ProfileScope("Animation.Ik"))
		{
			ForEach(scope (component, owner) =>
				{
					Step(component, owner, deltaTime);
				});
		}
	}

	/// Draws every component asking for it (DebugDraw) into `draw`.
	public void DrawDebug(DebugDraw draw)
	{
		ForEach(scope (component, owner) =>
			{
				let common = Common(component);
				if (common.DebugDraw)
					IkScene.Draw(draw, common.Runtime);
			});
	}

	private void Disable(IkRuntime runtime, EntityHandle owner, IkStatus status, StringView detail)
	{
		Detach(runtime);
		runtime.Status = status;
		runtime.Weight = 0.0f;
		if (runtime.Logged != status)
		{
			runtime.Logged = status;
			GlobalLog(.Warning, "Animation: inverse kinematics on '{}' is off: {}", mScene.GetEntityName(owner), detail);
		}
	}

	private void Step(T* component, EntityHandle owner, float deltaTime)
	{
		let common = Common(component);
		let runtime = common.Runtime;
		if (runtime == null)
			return;
		if (!mScene.IsEffectivelyActive(owner))
		{
			Detach(runtime);
			runtime.Weight = 0.0f;
			return;
		}
		if (!IkScene.FindAnimator(mScene, owner, let link))
		{
			Disable(runtime, owner, .NoAnimator, "no animation graph or skeletal animation at or above it");
			return;
		}
		if (link.Entity != runtime.Animator)
		{
			Detach(runtime);
			runtime.Animator = link.Entity;
			runtime.ResolvedFor = null;
		}
		if ((link.Stack == null) || (link.Skeleton == null))
		{
			// The animator builds its player on its first tick.
			runtime.Status = .Waiting;
			return;
		}
		if (runtime.ResolvedFor !== link.Skeleton)
		{
			let failed = scope String();
			let resolved = Resolve(component, link.Skeleton, failed);
			if (resolved != .Solving)
			{
				runtime.ResolvedFor = null;
				Disable(runtime, owner, resolved, failed);
				return;
			}
			runtime.ResolvedFor = link.Skeleton;
		}
		runtime.Status = .Solving;
		runtime.Logged = .Solving;

		// The weight eases toward its goal at full scale per FadeSeconds.
		let goal = common.Active ? Math.Clamp(common.Weight, 0.0f, 1.0f) : 0.0f;
		let step = (common.FadeSeconds > 0.0f) ? (deltaTime / common.FadeSeconds) : 1.0f;
		runtime.Weight = (runtime.Weight < goal) ? Math.Min(goal, runtime.Weight + step) : Math.Max(goal, runtime.Weight - step);
		if (runtime.Weight <= 0.0f)
		{
			Detach(runtime);
			return;
		}

		// Composed fresh: the cached world matrices update only after PostUpdate.
		let modelToWorld = mScene.ComposeWorldMatrix(link.ModelEntity);
		runtime.Modifier.ModelToWorld = modelToWorld;
		if (!Fill(component, owner, Inverse(modelToWorld)))
		{
			// The target entity is gone: nothing to reach this frame.
			Detach(runtime);
			return;
		}
		if (runtime.Order != common.Order)
		{
			link.Stack.Remove(runtime.Modifier);
			runtime.Order = common.Order;
		}
		// A no operation while it is there.
		link.Stack.Add(runtime.Modifier, runtime.Order);
	}
}

class TwoBoneIkComponentManager : IkComponentManagerBase<TwoBoneIkComponent>
{
	protected override void OnComponentCreated(TwoBoneIkComponent* component, EntityHandle entity)
	{
		component.StartBone = new String();
		component.MidBone = new String();
		component.EndBone = new String();
		component.Runtime = new IkRuntime();
	}

	protected override void OnComponentDestroyed(TwoBoneIkComponent* component, EntityHandle entity)
	{
		Detach(component.Runtime);
		DeleteAndNullify!(component.Runtime);
		DeleteAndNullify!(component.StartBone);
		DeleteAndNullify!(component.MidBone);
		DeleteAndNullify!(component.EndBone);
	}

	protected override IkCommon Common(TwoBoneIkComponent* c)
		=> .() { Runtime = c.Runtime, Active = c.Active, Weight = c.Weight, FadeSeconds = c.FadeSeconds, Order = c.Order, DebugDraw = c.DebugDraw };

	protected override IkStatus Resolve(TwoBoneIkComponent* c, Skeleton skeleton, String outFailed)
	{
		String[3] names = .(c.StartBone, c.MidBone, c.EndBone);
		int32[3] bones = .(-1, -1, -1);
		for (int i < 3)
		{
			bones[i] = skeleton.FindBone(names[i]);
			if (bones[i] < 0)
			{
				outFailed.AppendF("no bone named '{}' in its animator's skeleton", names[i]);
				return .UnknownBone;
			}
		}
		if (!InverseKinematics.IsBelow(skeleton, bones[1], bones[0]) || !InverseKinematics.IsBelow(skeleton, bones[2], bones[1]))
		{
			outFailed.AppendF("'{}', '{}', '{}' are not a chain (each below the one before)", c.StartBone, c.MidBone, c.EndBone);
			return .NotAChain;
		}
		let m = c.Runtime.Modifier;
		m.Kind = .TwoBone;
		m.Chain = .(bones[0], bones[1], bones[2]);
		return .Solving;
	}

	protected override bool Fill(TwoBoneIkComponent* c, EntityHandle owner, Float4x4 worldToModel)
	{
		let runtime = c.Runtime;
		if (!IkScene.TargetWorld(mScene, c.Target, runtime, owner, let targetWorld))
			return false;
		var s = ref runtime.Modifier.TwoBone;
		runtime.TargetWorld = InverseKinematics.Position(targetWorld);
		s.Target = TransformPoint(runtime.TargetWorld, worldToModel);
		s.MatchRotation = c.MatchRotation;
		if (c.MatchRotation)
			s.TargetRotation = InverseKinematics.RotationOf(targetWorld * worldToModel);
		s.HasPole = false;
		runtime.HasPoleWorld = false;
		if (!c.Pole.IsNil)
		{
			let pole = mScene.FindEntity(c.Pole.Id);
			if (mScene.IsValid(pole))
			{
				runtime.PoleWorld = InverseKinematics.Position(mScene.ComposeWorldMatrix(pole));
				runtime.HasPoleWorld = true;
				s.HasPole = true;
				s.Pole = TransformPoint(runtime.PoleWorld, worldToModel);
			}
		}
		s.HingeAxis = c.HingeAxis;
		s.Weight = runtime.Weight;
		return true;
	}
}

class AimIkComponentManager : IkComponentManagerBase<AimIkComponent>
{
	protected override void OnComponentCreated(AimIkComponent* component, EntityHandle entity)
	{
		component.Bones = new List<AimIkBone>();
		component.Runtime = new IkRuntime();
	}

	protected override void OnComponentDestroyed(AimIkComponent* component, EntityHandle entity)
	{
		Detach(component.Runtime);
		DeleteAndNullify!(component.Runtime);
		DeleteContainerAndItems!(component.Bones);
		component.Bones = null;
	}

	protected override IkCommon Common(AimIkComponent* c)
		=> .() { Runtime = c.Runtime, Active = c.Active, Weight = c.Weight, FadeSeconds = c.FadeSeconds, Order = c.Order, DebugDraw = c.DebugDraw };

	protected override IkStatus Resolve(AimIkComponent* c, Skeleton skeleton, String outFailed)
	{
		if (c.Bones.IsEmpty || (c.Bones.Count > InverseKinematics.MaxAimBones))
		{
			outFailed.AppendF("an aim takes 1 to {} bones, it lists {}", InverseKinematics.MaxAimBones, c.Bones.Count);
			return .NotAChain;
		}
		let m = c.Runtime.Modifier;
		m.Kind = .Aim;
		m.AimBones.Clear();
		m.AimShares.Clear();
		for (int i < c.Bones.Count)
		{
			let bone = skeleton.FindBone(c.Bones[i].Bone);
			if (bone < 0)
			{
				outFailed.AppendF("no bone named '{}' in its animator's skeleton", c.Bones[i].Bone);
				return .UnknownBone;
			}
			if ((i > 0) && !InverseKinematics.IsBelow(skeleton, bone, m.AimBones[i - 1]))
			{
				outFailed.AppendF("'{}' is not below '{}'", c.Bones[i].Bone, c.Bones[i - 1].Bone);
				return .NotAChain;
			}
			m.AimBones.Add(bone);
			m.AimShares.Add(c.Bones[i].Share);
		}
		return .Solving;
	}

	protected override bool Fill(AimIkComponent* c, EntityHandle owner, Float4x4 worldToModel)
	{
		let runtime = c.Runtime;
		if (!IkScene.TargetWorld(mScene, c.Target, runtime, owner, let targetWorld))
			return false;
		let m = runtime.Modifier;
		// The shares follow the component's: an inspector edit needs no re-resolve.
		for (int i = 0; (i < m.AimShares.Count) && (i < c.Bones.Count); i++)
			m.AimShares[i] = c.Bones[i].Share;
		var s = ref m.Aim;
		runtime.TargetWorld = InverseKinematics.Position(targetWorld);
		s.Target = TransformPoint(runtime.TargetWorld, worldToModel);
		s.AimAxis = c.AimAxis;
		s.UpAxis = c.UpAxis;
		s.MaxAngle = c.MaxAngle * DegToRad;
		s.Weight = runtime.Weight;
		s.HasUp = false;
		m.AimUpIsPoint = false;
		runtime.HasPoleWorld = false;
		if (!c.Up.IsNil)
		{
			let up = mScene.FindEntity(c.Up.Id);
			if (mScene.IsValid(up))
			{
				runtime.PoleWorld = InverseKinematics.Position(mScene.ComposeWorldMatrix(up));
				runtime.HasPoleWorld = true;
				s.HasUp = true;
				m.AimUpIsPoint = true;
				m.AimUpPoint = TransformPoint(runtime.PoleWorld, worldToModel);
			}
		}
		return true;
	}
}
