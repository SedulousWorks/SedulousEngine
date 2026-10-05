using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// Where an IK component stands: solving, waiting for its animator's first tick, or disabled by
/// what it cannot resolve (each disabled state logs once when it begins).
enum IkStatus : uint8
{
	Waiting,
	Solving,
	NoAnimator,
	UnknownBone,
	NotAChain,
}

enum IkKind : uint8
{
	TwoBone,
	Aim,
	Foot,
}

/// One component's solve, run by the animator's player as a pose modifier
/// (inverse-kinematics.md P2). The manager fills it each frame (it holds its own copy: a
/// component moves in its manager's pool, this does not); the player runs it after the pose
/// and writes back the result and, for debug drawing, the chain in world space.
class IkModifier : IPoseModifier
{
	public IkKind Kind = .TwoBone;
	public TwoBoneIkChain Chain = .();
	public TwoBoneIkSettings TwoBone = .();
	public List<int32> AimBones = new .() ~ delete _;
	public List<float> AimShares = new .() ~ delete _;
	public AimIkSettings Aim = .();
	/// Aim.Up is computed from this model space point and the last bone, each solve.
	public bool AimUpIsPoint = false;
	public Float3 AimUpPoint = .(0, 0, 0);
	public Float4x4 ModelToWorld = .Identity();
	public Float4x4 WorldToModel = .Identity();

	// ---- feet (IkKind.Foot) ----

	/// A planted foot within this of its ground counts as reached (metres).
	public const float FootReachTolerance = 1.0e-3f;
	public List<FootIkLeg> FootLegs = new .() ~ delete _;
	public int32 FootPelvis = -1;
	public FootIkSettings Foot = .();
	public FootIkState FootState = .();
	public FootIkResult FootResult = .();
	public FootGround[InverseKinematics.MaxFootIkLegs] FootGrounds = default;
	public bool[InverseKinematics.MaxFootIkLegs] FootHitWorld = default;
	public Float3[InverseKinematics.MaxFootIkLegs] FootGroundWorld = default;
	public float FootRayUp = 0.5f;
	public float FootRayDown = 0.75f;
	public uint32 FootGroupMask = 0xFFFFFFFF;
	/// This frame's seconds, handed over once.
	public float FootStep = 0.0f;
	/// The next evaluation probes and steps.
	public bool FootNewFrame = false;
	/// The scene's solid surface rays; null is no ground. BORROWED.
	public ISceneRayQuery Rays = null;

	/// The last solve.
	public IkResult Result = .();
	public bool Solved = false;
	public int32[InverseKinematics.MaxAimBones] Drawn = default;
	public Float3[InverseKinematics.MaxAimBones] ChainWorld = default;
	public int DrawnCount = 0;
	/// Points per polyline; nought draws one polyline through them all.
	public int DrawnStride = 0;

	public void Apply(Skeleton skeleton, Span<BoneTransform> localPoses, ModelPoseCache model)
	{
		if (Kind == .Foot)
		{
			ApplyFoot(skeleton, localPoses, model);
			return;
		}
		DrawnStride = 0;
		if (Kind == .TwoBone)
		{
			Result = InverseKinematics.SolveTwoBone(skeleton, localPoses, model, Chain, TwoBone);
			Drawn[0] = Chain.Start;
			Drawn[1] = Chain.Mid;
			Drawn[2] = Chain.End;
			DrawnCount = 3;
		}
		else
		{
			if (AimUpIsPoint && !AimBones.IsEmpty)
				Aim.Up = AimUpPoint - InverseKinematics.Position(model.At(AimBones.Back));
			Result = InverseKinematics.SolveAim(skeleton, localPoses, model, AimBones, AimShares, Aim);
			DrawnCount = Math.Min(AimBones.Count, InverseKinematics.MaxAimBones);
			for (int i < DrawnCount)
				Drawn[i] = AimBones[i];
		}
		DrawnToWorld(model);
	}

	private void DrawnToWorld(ModelPoseCache model)
	{
		for (int i < DrawnCount)
			ChainWorld[i] = TransformPoint(InverseKinematics.Position(model.At(Drawn[i])), ModelToWorld);
		Solved = true;
	}

	/// Feet: probe the ground under the animated feet once a frame (a second evaluation in the
	/// same frame reuses the hits and holds the easing: no extra rays, no double step), then solve.
	private void ApplyFoot(Skeleton skeleton, Span<BoneTransform> localPoses, ModelPoseCache model)
	{
		let legs = Math.Min(FootLegs.Count, InverseKinematics.MaxFootIkLegs);
		var step = 0.0f;
		if (FootNewFrame)
		{
			FootNewFrame = false;
			step = FootStep;
			Float3[InverseKinematics.MaxFootIkLegs] feet = default;
			InverseKinematics.FootIkAnimatedFeet(model, .(FootLegs.Ptr, legs), .(&feet[0], legs));
			let up = Normalized(Foot.Up);
			let downWorld = TransformDirection(-up, ModelToWorld);
			// Model to world length.
			let scale = Length(downWorld);
			for (int i < legs)
			{
				FootGrounds[i] = .();
				FootHitWorld[i] = false;
				if ((Rays == null) || (scale <= Epsilon))
					continue;
				let origin = TransformPoint(feet[i] + up * FootRayUp, ModelToWorld);
				if (Rays.CastRay(origin, downWorld * (1.0f / scale), (FootRayUp + FootRayDown) * scale, FootGroupMask, let hit))
				{
					FootGrounds[i] = .(TransformPoint(hit.Position, WorldToModel), Normalized(TransformDirection(hit.Normal, WorldToModel)));
					FootHitWorld[i] = true;
					FootGroundWorld[i] = hit.Position;
				}
			}
		}
		FootResult = InverseKinematics.SolveFootIk(skeleton, localPoses, model, FootPelvis, .(FootLegs.Ptr, legs),
			.(&FootGrounds[0], legs), Foot, ref FootState, step);
		Result.Valid = FootResult.Valid;
		Result.Error = 0.0f;
		for (int i < legs)
			Result.Error = Math.Max(Result.Error, FootResult.FootError[i]);
		Result.Reached = Result.Valid && (Result.Error <= FootReachTolerance);
		DrawnCount = 0;
		for (int i < legs)
		{
			Drawn[DrawnCount++] = FootLegs[i].Chain.Start;
			Drawn[DrawnCount++] = FootLegs[i].Chain.Mid;
			Drawn[DrawnCount++] = FootLegs[i].Chain.End;
		}
		DrawnStride = 3;
		DrawnToWorld(model);
	}
}

/// An IK component's runtime side, none of it saved. Created and freed by its manager: a
/// component is a struct in a packed pool and cannot own heap data.
class IkRuntime
{
	public IkModifier Modifier = new .() ~ delete _;
	/// The animator the modifier was added to.
	public EntityHandle Animator = .Invalid;
	/// The skeleton the chain was resolved on, BORROWED and compared by reference.
	public Skeleton ResolvedFor = null;
	public IkStatus Status = .Waiting;
	public IkStatus Logged = .Waiting;
	/// Eased toward the component's weight, or nought while inactive.
	public float Weight = 0.0f;
	/// The order it was added to the stack at.
	public int32 Order = 0;
	public bool HasScriptTarget = false;
	/// World space (scene.Animation.SetIkTarget).
	public Float3 ScriptTarget = .(0, 0, 0);
	public Float3 TargetWorld = .(0, 0, 0);
	public bool HasPoleWorld = false;
	public Float3 PoleWorld = .(0, 0, 0);
}

/// A two bone chain bent so its end reaches a target: a foot on a step, a hand on a handle. On
/// an entity under the animated model (or on it), driving the nearest animator at or above it.
[SerializableComponent("two_bone_ik")]
[DisplayName("Two Bone IK")]
[Category("Animation")]
[Scriptable]
struct TwoBoneIkComponent : ISerializable
{
	/// The chain by bone names. OWNED, created and freed by the manager.
	[Scriptable, BoneName, DisplayName("Start Bone"), Description("The chain's first bone (a thigh, an upper arm).")]
	public String StartBone = null;
	[Scriptable, BoneName, DisplayName("Mid Bone"), Description("The joint that bends (a knee, an elbow).")]
	public String MidBone = null;
	[Scriptable, BoneName, DisplayName("End Bone"), Description("The bone that reaches the target (a foot, a hand).")]
	public String EndBone = null;
	[Scriptable, Description("The entity to reach. Empty: the point a script sets, else this entity.")]
	public EntityRef Target = .();
	[Scriptable, DisplayName("Match Rotation"), Description("The end bone takes the target's rotation as well.")]
	public bool MatchRotation = false;
	[Scriptable, Description("Optional: the joint bends toward this entity.")]
	public EntityRef Pole = .();
	[Scriptable, DisplayName("Hinge Axis"), Description("The joint's axis in the first bone's space, for a chain that is straight with no pole and a straight bind pose.")]
	public Float3 HingeAxis = .(0, 0, 0);
	[Scriptable, Range(0.0f, 1.0f, 0.01f)]
	public float Weight = 1.0f;
	/// The weight eases on and off over this.
	[Scriptable, DisplayName("Fade Seconds"), Range(0.0f, 4.0f, 0.05f)]
	public float FadeSeconds = 0.2f;
	[Scriptable]
	public bool Active = true;
	[Scriptable, Description("Lower runs first, across the animator's IK components.")]
	public int32 Order = 0;
	[Scriptable, DisplayName("Debug Draw"), Description("Draw the chain and its target while the scene runs.")]
	public bool DebugDraw = false;

	[Hidden]
	public IkRuntime Runtime = null;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		Sedulous.Core.Serialization.Serialize(ar, "startBone", StartBone);
		Sedulous.Core.Serialization.Serialize(ar, "midBone", MidBone);
		Sedulous.Core.Serialization.Serialize(ar, "endBone", EndBone);
		SerializeValue(ar, "target", ref Target.Id);
		SerializeValue(ar, "matchRotation", ref MatchRotation);
		SerializeValue(ar, "pole", ref Pole.Id);
		SerializeValue(ar, "hingeAxis", ref HingeAxis);
		SerializeValue(ar, "weight", ref Weight);
		SerializeValue(ar, "fadeSeconds", ref FadeSeconds);
		SerializeValue(ar, "active", ref Active);
		SerializeValue(ar, "order", ref Order);
		SerializeValue(ar, "debugDraw", ref DebugDraw);
	}
}

/// One bone of an aim and its share of the swing still to go.
[Scriptable]
class AimIkBone : ISerializable
{
	[Scriptable, BoneName]
	public String Bone = new .() ~ delete _;
	[Scriptable, Range(0.0f, 1.0f, 0.01f), Description("This bone's part of the turn still to go (the last: 1).")]
	public float Share = 1.0f;

	public this() {}

	public this(StringView bone, float share)
	{
		Bone.Set(bone);
		Share = share;
	}

	public void Serialize(ISerializer ar)
	{
		Sedulous.Core.Serialization.Serialize(ar, "bone", Bone);
		SerializeValue(ar, "share", ref Share);
	}
}

/// Bones that turn so the last one points at a target: a head that follows, a spine sharing
/// the turn (0.3, 0.5, 1.0), a weapon.
[SerializableComponent("aim_ik")]
[DisplayName("Aim IK")]
[Category("Animation")]
[Scriptable]
struct AimIkComponent : ISerializable
{
	/// Root first; the last one aims. OWNED, created and freed by the manager.
	[Scriptable, Description("Root first; the last bone aims (a spine: 0.3, 0.5, 1).")]
	public List<AimIkBone> Bones = null;
	[Scriptable, Description("The entity to aim at. Empty: the point a script sets, else this entity.")]
	public EntityRef Target = .();
	[Scriptable, Description("Optional: the up axis leans toward this entity (else the animated up).")]
	public EntityRef Up = .();
	/// In the last bone's space.
	[Scriptable, DisplayName("Aim Axis")]
	public Float3 AimAxis = .(0, 0, 1);
	[Scriptable, DisplayName("Up Axis")]
	public Float3 UpAxis = .(0, 1, 0);
	[Scriptable, DisplayName("Max Angle"), Range(0.0f, 180.0f, 1.0f), Description("Degrees from the animated direction.")]
	public float MaxAngle = 60.0f;
	[Scriptable, Range(0.0f, 1.0f, 0.01f)]
	public float Weight = 1.0f;
	[Scriptable, DisplayName("Fade Seconds"), Range(0.0f, 4.0f, 0.05f)]
	public float FadeSeconds = 0.2f;
	[Scriptable]
	public bool Active = true;
	[Scriptable]
	public int32 Order = 0;
	[Scriptable, DisplayName("Debug Draw")]
	public bool DebugDraw = false;

	[Hidden]
	public IkRuntime Runtime = null;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		ar.Key("bones");
		SerializeList(ar, Bones);
		SerializeValue(ar, "target", ref Target.Id);
		SerializeValue(ar, "up", ref Up.Id);
		SerializeValue(ar, "aimAxis", ref AimAxis);
		SerializeValue(ar, "upAxis", ref UpAxis);
		SerializeValue(ar, "maxAngle", ref MaxAngle);
		SerializeValue(ar, "weight", ref Weight);
		SerializeValue(ar, "fadeSeconds", ref FadeSeconds);
		SerializeValue(ar, "active", ref Active);
		SerializeValue(ar, "order", ref Order);
		SerializeValue(ar, "debugDraw", ref DebugDraw);
	}
}

/// One leg of a FootIkComponent: its chain by bone names (the end bone is the foot).
[Scriptable]
class FootIkLegBones : ISerializable
{
	[Scriptable, BoneName, DisplayName("Start Bone"), Description("The thigh.")]
	public String StartBone = new .() ~ delete _;
	[Scriptable, BoneName, DisplayName("Mid Bone"), Description("The shin (the knee bends).")]
	public String MidBone = new .() ~ delete _;
	[Scriptable, BoneName, DisplayName("End Bone"), Description("The foot.")]
	public String EndBone = new .() ~ delete _;
	[Scriptable, DisplayName("Hinge Axis"), Description("The knee's axis in the thigh's space, for a straight leg with a straight bind pose.")]
	public Float3 HingeAxis = .(0, 0, 0);

	public this() {}

	public this(StringView start, StringView mid, StringView end)
	{
		StartBone.Set(start);
		MidBone.Set(mid);
		EndBone.Set(end);
	}

	public void Serialize(ISerializer ar)
	{
		Sedulous.Core.Serialization.Serialize(ar, "startBone", StartBone);
		Sedulous.Core.Serialization.Serialize(ar, "midBone", MidBone);
		Sedulous.Core.Serialization.Serialize(ar, "endBone", EndBone);
		SerializeValue(ar, "hingeAxis", ref HingeAxis);
	}
}

/// Feet that stand on the ground under them: each planted foot finds its ground with a ray
/// (through the scene's ray query: physics, solid surfaces only), rises or falls to it and turns
/// to its slope; the pelvis lowers so the lower foot reaches; a foot the animation lifts is
/// swinging and left alone.
[SerializableComponent("foot_ik")]
[DisplayName("Foot IK")]
[Category("Animation")]
[Scriptable]
struct FootIkComponent : ISerializable
{
	/// Up to four. OWNED, created and freed by the manager.
	[Scriptable, Description("Up to four legs, each thigh, shin, foot.")]
	public List<FootIkLegBones> Legs = null;
	/// OWNED, created and freed by the manager.
	[Scriptable, BoneName, DisplayName("Pelvis Bone"), Description("Lowers so the lower foot can reach (empty: it stays).")]
	public String PelvisBone = null;
	[Scriptable, DisplayName("Ray Up"), Description("The ground probe starts this far above the foot.")]
	public float RayUp = 0.5f;
	[Scriptable, DisplayName("Ray Down"), Description("And looks this far below it.")]
	public float RayDown = 0.75f;
	[Scriptable, DisplayName("Group Mask"), Description("The collision groups that count as ground.")]
	public uint32 GroupMask = 0xFFFFFFFF;
	[Scriptable, DisplayName("Pelvis Drop Max")]
	public float PelvisDropMax = 0.3f;
	[Scriptable, DisplayName("Max Tilt"), Range(0.0f, 90.0f, 1.0f), Description("Degrees a foot turns to its ground's slope.")]
	public float MaxTilt = 30.0f;
	[Scriptable, DisplayName("Lift Height"), Description("A foot animated higher than this is swinging and left alone.")]
	public float LiftHeight = 0.15f;
	[Scriptable, DisplayName("Ground Height"), Description("The animation's ground along up: 0 when the model's origin is at its feet.")]
	public float GroundHeight = 0.0f;
	[Scriptable, DisplayName("Raise Rate")]
	public float RaiseRate = 20.0f;
	[Scriptable, DisplayName("Lower Rate")]
	public float LowerRate = 8.0f;
	[Scriptable, Range(0.0f, 1.0f, 0.01f)]
	public float Weight = 1.0f;
	[Scriptable, DisplayName("Fade Seconds"), Range(0.0f, 4.0f, 0.05f)]
	public float FadeSeconds = 0.2f;
	[Scriptable]
	public bool Active = true;
	[Scriptable]
	public int32 Order = 0;
	[Scriptable, DisplayName("Debug Draw")]
	public bool DebugDraw = false;

	[Hidden]
	public IkRuntime Runtime = null;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		ar.Key("legs");
		SerializeList(ar, Legs);
		Sedulous.Core.Serialization.Serialize(ar, "pelvisBone", PelvisBone);
		SerializeValue(ar, "rayUp", ref RayUp);
		SerializeValue(ar, "rayDown", ref RayDown);
		SerializeValue(ar, "groupMask", ref GroupMask);
		SerializeValue(ar, "pelvisDropMax", ref PelvisDropMax);
		SerializeValue(ar, "maxTilt", ref MaxTilt);
		SerializeValue(ar, "liftHeight", ref LiftHeight);
		SerializeValue(ar, "groundHeight", ref GroundHeight);
		SerializeValue(ar, "raiseRate", ref RaiseRate);
		SerializeValue(ar, "lowerRate", ref LowerRate);
		SerializeValue(ar, "weight", ref Weight);
		SerializeValue(ar, "fadeSeconds", ref FadeSeconds);
		SerializeValue(ar, "active", ref Active);
		SerializeValue(ar, "order", ref Order);
		SerializeValue(ar, "debugDraw", ref DebugDraw);
	}
}
