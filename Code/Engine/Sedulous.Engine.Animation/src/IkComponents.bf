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

	/// The last solve.
	public IkResult Result = .();
	public bool Solved = false;
	public int32[InverseKinematics.MaxAimBones] Drawn = default;
	public Float3[InverseKinematics.MaxAimBones] ChainWorld = default;
	public int DrawnCount = 0;

	public void Apply(Skeleton skeleton, Span<BoneTransform> localPoses, ModelPoseCache model)
	{
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
		for (int i < DrawnCount)
			ChainWorld[i] = TransformPoint(InverseKinematics.Position(model.At(Drawn[i])), ModelToWorld);
		Solved = true;
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
