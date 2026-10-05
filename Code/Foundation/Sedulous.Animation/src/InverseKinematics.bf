using System;
using Sedulous.Core;

namespace Sedulous.Animation;

/// What a solve did: whether the chain's end reached its target, and how far it missed (a
/// distance for a two bone chain, an angle in radians for an aim). `Valid` is false when the
/// bones do not form the chain (a bad index, or a bone not below the one before it); nothing
/// changed then.
struct IkResult
{
	public bool Valid = false;
	public bool Reached = false;
	public float Error = 0.0f;

	public this() {}
}

/// A two bone chain (a thigh, a shin, a foot; an upper arm, a forearm, a hand). Each bone must be
/// below the one before it; twist bones between them are carried along.
struct TwoBoneIkChain
{
	public int32 Start = -1;
	public int32 Mid = -1;
	public int32 End = -1;

	public this() {}

	public this(int32 start, int32 mid, int32 end)
	{
		Start = start;
		Mid = mid;
		End = end;
	}
}

struct TwoBoneIkSettings
{
	/// Model space.
	public Float3 Target = .(0, 0, 0);
	/// Turn the end bone to TargetRotation as well.
	public bool MatchRotation = false;
	/// Model space.
	public Quaternion TargetRotation = .Identity;
	/// The bend plane, first that applies: a pole (the mid joint bends toward it), the animated
	/// chain's own bend, the bind pose's bend, then HingeAxis. A knee and an elbow bend opposite
	/// ways, so the hinge has no default: it is the mid joint's rotation axis in the START bone's
	/// local space (the mid moves toward cross(hinge, chain direction)).
	public bool HasPole = false;
	/// Model space.
	public Float3 Pole = .(0, 0, 0);
	public Float3 HingeAxis = .(0, 0, 0);
	/// Nought leaves the pose as it was, byte for byte.
	public float Weight = 1.0f;
	/// A DETACHED end (an end bone not below the mid: asset pack rigs export feet and hands as IK
	/// target bones off the root, the shin or forearm with no child) is moved to the target itself
	/// (blended by the weight, turned with MatchRotation), and the chain bends all the way to meet
	/// it with its tip: the point of the mid bone that met the end, by default where the pose this
	/// solve receives has them (keeping any gap the baked rig left), or `Tip` (in the mid bone's
	/// space) with UseTip. With no end bone (minus one) and UseTip, the tip is the end.
	public bool UseTip = false;
	public Float3 Tip = .(0, 0, 0);

	public this() {}
}

/// An aim (a head, a spine sharing a turn, a weapon): the last bone's aim axis points at the
/// target, each bone taking its share of the swing still to go.
struct AimIkSettings
{
	/// Model space.
	public Float3 Target = .(0, 0, 0);
	/// In the last bone's local space.
	public Float3 AimAxis = .(0, 0, 1);
	/// In the last bone's local space.
	public Float3 UpAxis = .(0, 1, 0);
	/// The direction the up axis leans toward after the swing; without one, the animated up is
	/// kept (no roll drifts in from the swing).
	public bool HasUp = false;
	/// Model space.
	public Float3 Up = .(0, 0, 0);
	/// From the animated aim direction.
	public float MaxAngle = 60.0f * DegToRad;
	public float Weight = 1.0f;

	public this() {}
}

/// One leg of a foot solve: its two bone chain (the end bone is the foot) and the hinge for a
/// straight chain with a straight bind pose.
struct FootIkLeg
{
	public TwoBoneIkChain Chain = .();
	public Float3 HingeAxis = .(0, 0, 0);

	public this() {}

	public this(TwoBoneIkChain chain, Float3 hingeAxis)
	{
		Chain = chain;
		HingeAxis = hingeAxis;
	}
}

/// What is under a foot, found by the caller (a physics probe, in the engine): model space.
struct FootGround
{
	public bool Hit = false;
	public Float3 Point = .(0, 0, 0);
	public Float3 Normal = .(0, 1, 0);

	public this() {}

	public this(Float3 point, Float3 normal)
	{
		Hit = true;
		Point = point;
		Normal = normal;
	}
}

struct FootIkSettings
{
	/// Model space.
	public Float3 Up = .(0, 1, 0);
	/// The height along up of the ground the animation was made on: nought when the model's
	/// origin is at its feet (every imported sample rig); a rig whose origin is elsewhere says
	/// where.
	public float GroundHeight = 0.0f;
	/// The most the pelvis lowers to let the lower foot reach.
	public float PelvisDropMax = 0.3f;
	/// A foot turns to its ground's slope up to this.
	public float MaxTilt = 30.0f * DegToRad;
	/// A foot animated higher than this is swinging: it fades out by twice it.
	public float LiftHeight = 0.15f;
	/// Easing per second while a foot or the pelvis rises.
	public float RaiseRate = 20.0f;
	/// And while it lowers: slower, a foot settles onto the ground.
	public float LowerRate = 8.0f;
	public float Weight = 1.0f;

	public this() {}
}

/// The eased corrections a foot solve carries from one frame to the next (the caller keeps one
/// per character). The first solve takes its goals at once.
struct FootIkState
{
	public bool Primed = false;
	public float Pelvis = 0.0f;
	/// How far each foot rises (or falls) to its ground.
	public float[InverseKinematics.MaxFootIkLegs] Offset = default;
	/// How planted each foot is: nought swinging or with no ground, one down.
	public float[InverseKinematics.MaxFootIkLegs] Plant = default;

	public this() {}
}

struct FootIkResult
{
	public bool Valid = false;
	/// Along up, nought or below.
	public float PelvisOffset = 0.0f;
	/// Each foot's miss after its solve.
	public float[InverseKinematics.MaxFootIkLegs] FootError = default;

	public this() {}
}

/// Inverse kinematics solvers (inverse-kinematics.md P1): pure functions over a skeleton, a LOCAL
/// pose and its model space matrices (ModelPoseCache), with no physics and no scene. A solve
/// writes local rotations and keeps the cache current by rebuilding from the highest bone it
/// changed down, so bones above the chain never move. Targets are in the skeleton's model space;
/// the caller owns time (fades) and order. Nothing here allocates: the only buffer is the
/// cache's, sized once.
///
/// Rotations compose as the engine's row vector math does: a bone's model rotation is
/// `parentModel * local` (Hamilton order, the right factor applied first), so a model space turn
/// D of a bone is `inverse(parentModel) * D * parentModel * local` in its local rotation.
static class InverseKinematics
{
	/// The most bones an aim spreads over (its weight blend keeps their poses on the stack).
	public const int MaxAimBones = 16;
	/// How close an end must come to count as reached: this fraction of the chain's length.
	public const float ReachTolerance = 1.0e-3f;
	/// The fraction of full reach a two bone chain stops at, short of locking straight.
	public const float TwoBoneMaxReach = 0.995f;
	/// The most legs one foot solve plants (a biped 2, a quadruped 4).
	public const int MaxFootIkLegs = 4;

	public static Float3 Position(Float4x4 m) => .(m.M[3][0], m.M[3][1], m.M[3][2]);

	public static Quaternion RotationOf(Float4x4 m)
	{
		Decompose(m, ?, let rotation, ?);
		return rotation;
	}

	/// `v` less its part along unit `axis`.
	public static Float3 Perpendicular(Float3 v, Float3 axis) => v - axis * Dot(v, axis);

	/// A unit vector perpendicular to unit `v`, the same one every time for the same `v`.
	public static Float3 AnyPerpendicular(Float3 v)
	{
		let ax = Float3(Math.Abs(v.X), Math.Abs(v.Y), Math.Abs(v.Z));
		let other = ((ax.X <= ax.Y) && (ax.X <= ax.Z)) ? Float3(1, 0, 0)
			: (ax.Y <= ax.Z) ? Float3(0, 1, 0)
			: Float3(0, 0, 1);
		return Normalized(Perpendicular(other, v));
	}

	/// The shortest turn taking unit `from` to unit `to` (a half turn about a fixed
	/// perpendicular when they are opposite).
	public static Quaternion FromTo(Float3 from, Float3 to)
	{
		let cosine = Dot(from, to);
		if (cosine >= 1.0f - 1.0e-7f)
			return .Identity;
		if (cosine <= -1.0f + 1.0e-7f)
			return Quaternion.FromAxisAngle(AnyPerpendicular(from), Pi);
		let axis = Cross(from, to);
		return Normalized(Quaternion(axis.X, axis.Y, axis.Z, 1.0f + cosine));
	}

	/// The turn about unit `axis` taking `from` toward `to`, both perpendicular to it.
	public static float SignedAngle(Float3 from, Float3 to, Float3 axis)
		=> Atan2(Dot(Cross(from, to), axis), Dot(from, to));

	private static Quaternion ParentModelRotation(Skeleton skeleton, ModelPoseCache model, int32 bone)
	{
		let b = skeleton.GetBone(bone);
		if ((b != null) && (b.ParentIndex >= 0))
			return RotationOf(model.At(b.ParentIndex));
		return (b != null) ? RotationOf(b.RootCorrection) : .Identity;
	}

	/// Turns `bone` by the model space rotation `turn` about its own origin.
	private static void TurnInModel(Skeleton skeleton, Span<BoneTransform> localPoses,
		ModelPoseCache model, int32 bone, Quaternion turn)
	{
		let parent = ParentModelRotation(skeleton, model, bone);
		localPoses[bone].Rotation = Normalized(Inverse(parent) * turn * parent * localPoses[bone].Rotation);
	}

	private static bool InPose(Skeleton skeleton, Span<BoneTransform> localPoses, int32 bone)
		=> (bone >= 0) && (bone < skeleton.BoneCount) && (bone < localPoses.Length);

	/// True when `ancestor` is above `bone` (not the bone itself).
	public static bool IsBelow(Skeleton skeleton, int32 bone, int32 ancestor)
	{
		var b = skeleton.GetBone(bone);
		for (int32 steps = 0; (b != null) && (b.ParentIndex >= 0) && (steps <= skeleton.BoneCount); steps++)
		{
			if (b.ParentIndex == ancestor)
				return true;
			b = skeleton.GetBone(b.ParentIndex);
		}
		return false;
	}

	/// The cache is current for this skeleton (a solver may be called outside a stack).
	private static void EnsureModel(Skeleton skeleton, Span<BoneTransform> localPoses, ModelPoseCache model)
	{
		if (model.Model.Length != skeleton.BoneCount)
			model.Build(skeleton, localPoses);
	}

	/// The side the mid joint bends toward, perpendicular to the unit chain direction `along`:
	/// the animated chain's bend, else the bind pose's carried by the start bone's turn since,
	/// else the hinge, else a fixed perpendicular (the same every frame).
	private static Float3 BendSide(Skeleton skeleton, ModelPoseCache model, TwoBoneIkChain chain,
		TwoBoneIkSettings settings, Float3 along, float upperLength)
	{
		let straight = 1.0e-2f * upperLength; // a bend under about half a degree
		let start = Position(model.At(chain.Start));
		let animated = Perpendicular(Position(model.At(chain.Mid)) - start, along);
		if (Length(animated) > straight)
			return Normalized(animated);

		let startNow = RotationOf(model.At(chain.Start));
		let bindStart = Inverse(skeleton.GetBone(chain.Start).InverseBindPose);
		let bindA = Position(bindStart);
		let bindB = Position(Inverse(skeleton.GetBone(chain.Mid).InverseBindPose));
		let bindC = settings.UseTip ? TransformPoint(settings.Tip, Inverse(skeleton.GetBone(chain.Mid).InverseBindPose))
			: Position(Inverse(skeleton.GetBone(chain.End).InverseBindPose));
		let bindAlong = Normalized(bindC - bindA);
		let bindBend = Perpendicular(bindB - bindA, bindAlong);
		if ((Length(bindAlong) > 0.5f) && (Length(bindBend) > straight))
		{
			let sinceBind = startNow * Inverse(RotationOf(bindStart));
			let carried = Perpendicular(RotateVector(sinceBind, bindBend), along);
			if (Length(carried) > straight)
				return Normalized(carried);
		}
		if (LengthSquared(settings.HingeAxis) > 1.0e-12f)
		{
			let side = Cross(RotateVector(startNow, Normalized(settings.HingeAxis)), along);
			if (LengthSquared(side) > 1.0e-8f)
				return Normalized(Perpendicular(side, along));
		}
		return AnyPerpendicular(along);
	}

	/// Bends a two bone chain so its end reaches `settings.Target`: exactly when the target is in
	/// reach, else stopped at TwoBoneMaxReach of full reach (or the span the pose already has, if
	/// the animation holds it straighter; or the chain's shortest fold) and pointed at it. Bone lengths are the pose's own (a rotation keeps them; the bind pose's
	/// would miss when an animation moved a bone). The mid joint stays in the bend plane, so it
	/// never rolls or flips between frames. Writes the start and mid local rotations, and the
	/// end's with MatchRotation.
	public static IkResult SolveTwoBone(Skeleton skeleton, Span<BoneTransform> localPoses,
		ModelPoseCache model, TwoBoneIkChain chain, TwoBoneIkSettings settings)
	{
		var result = IkResult();
		let hasEnd = InPose(skeleton, localPoses, chain.End);
		let detached = hasEnd && !IsBelow(skeleton, chain.End, chain.Mid);
		// The end is the tip itself.
		let tip = !hasEnd;
		// A detached end the chain carries, or one above it, has no meeting point.
		if (!InPose(skeleton, localPoses, chain.Start) || !InPose(skeleton, localPoses, chain.Mid)
			|| !IsBelow(skeleton, chain.Mid, chain.Start) || (!hasEnd && !settings.UseTip)
			|| (detached && ((chain.End == chain.Start) || (chain.End == chain.Mid)
			|| IsBelow(skeleton, chain.End, chain.Start) || IsBelow(skeleton, chain.Start, chain.End))))
			return result;
		EnsureModel(skeleton, localPoses, model);
		result.Valid = true;
		if (detached)
			return SolveDetached(skeleton, localPoses, model, chain, settings);

		// Where the chain ends: the end bone, or the tip carried by the mid bone.
		Float3 EndNow() => tip ? TransformPoint(settings.Tip, model.At(chain.Mid)) : Position(model.At(chain.End));

		let a = Position(model.At(chain.Start));
		let b = Position(model.At(chain.Mid));
		let c = EndNow();
		let target = settings.Target;
		let upper = Length(b - a);
		let lower = Length(c - b);
		let reach = upper + lower;
		if ((upper <= Epsilon) || (lower <= Epsilon) || (settings.Weight <= 0.0f))
		{
			result.Error = Length(c - target);
			result.Reached = result.Error <= ReachTolerance * reach;
			return result;
		}
		int32[3] bones = .(chain.Start, chain.Mid, tip ? chain.Mid : chain.End);
		BoneTransform[3] before = .(localPoses[bones[0]], localPoses[bones[1]], localPoses[bones[2]]);

		// 1. Open or close the mid joint, in the chain's bend plane, to the distance it must span.
		var along = c - a;
		along = (Length(along) > Epsilon * reach) ? Normalized(along) : Normalized(b - a);
		let side = BendSide(skeleton, model, chain, settings, along, upper);
		let hinge = Normalized(Cross(along, side));
		let shortest = Math.Max(Math.Abs(upper - lower), 1.0e-4f * reach);
		// Short of locking straight, unless the animation already holds the chain straighter: IK
		// never pulls a nearly straight standing leg up off the ground it already reaches.
		let longest = Math.Max(TwoBoneMaxReach * reach, Math.Min(Length(c - a), reach));
		let span = Math.Clamp(Length(target - a), shortest, longest);
		let cosWanted = Math.Clamp((upper * upper + lower * lower - span * span) / (2.0f * upper * lower), -1.0f, 1.0f);
		// The interior angle measured about the hinge (a turn about it opens the joint), so a
		// straight chain or one bent the other way still lands on the bend side.
		let now = SignedAngle(Normalized(a - b), Normalized(c - b), hinge);
		TurnInModel(skeleton, localPoses, model, chain.Mid, Quaternion.FromAxisAngle(hinge, Acos(cosWanted) - now));
		model.RebuildFrom(skeleton, localPoses, chain.Mid);

		// 2. Swing the whole chain from the start: its end direction onto the target's, and its
		//    bend side onto the pole's (or carried along with the swing, without one).
		let bent = EndNow();
		let alongNow = Normalized(bent - a);
		let sideNow = Normalized(Perpendicular(b - a, alongNow));
		let toTarget = (Length(target - a) > Epsilon * reach) ? Normalized(target - a) : alongNow;
		let swing = FromTo(alongNow, toTarget);
		let sideSwung = Normalized(Perpendicular(RotateVector(swing, sideNow), toTarget));
		var sideWanted = sideSwung;
		if (settings.HasPole)
		{
			let toPole = Perpendicular(settings.Pole - a, toTarget);
			if (Length(toPole) > 1.0e-4f * reach)
				sideWanted = Normalized(toPole);
		}
		let twist = Quaternion.FromAxisAngle(toTarget, SignedAngle(sideSwung, sideWanted, toTarget));
		TurnInModel(skeleton, localPoses, model, chain.Start, twist * swing);
		model.RebuildFrom(skeleton, localPoses, chain.Start);

		if (settings.MatchRotation && !tip)
		{
			let parent = ParentModelRotation(skeleton, model, chain.End);
			localPoses[chain.End].Rotation = Normalized(Inverse(parent) * settings.TargetRotation);
			model.RebuildFrom(skeleton, localPoses, chain.End);
		}

		if (settings.Weight < 1.0f)
		{
			for (int i < (tip ? 2 : 3))
				localPoses[bones[i]].Rotation = Slerp(before[i].Rotation, localPoses[bones[i]].Rotation, settings.Weight);
			model.RebuildFrom(skeleton, localPoses, chain.Start);
		}

		result.Error = Length(EndNow() - target);
		result.Reached = result.Error <= ReachTolerance * reach;
		return result;
	}

	/// A detached end: moved itself, then met by the chain's tip (see TwoBoneIkSettings).
	private static IkResult SolveDetached(Skeleton skeleton, Span<BoneTransform> localPoses, ModelPoseCache model,
		TwoBoneIkChain chain, TwoBoneIkSettings settings)
	{
		var result = IkResult();
		result.Valid = true;
		let end = Position(model.At(chain.End));
		let reach = Length(Position(model.At(chain.Mid)) - Position(model.At(chain.Start)))
			+ Length(end - Position(model.At(chain.Mid)));
		let weight = Math.Clamp(settings.Weight, 0.0f, 1.0f);
		if (weight <= 0.0f)
		{
			result.Error = Length(end - settings.Target);
			result.Reached = result.Error <= ReachTolerance * reach;
			return result;
		}
		let tip = settings.UseTip ? settings.Tip : TransformPoint(end, Inverse(model.At(chain.Mid)));
		let turn = RotationOf(model.At(chain.End));
		let b = skeleton.GetBone(chain.End);
		let parent = (b.ParentIndex >= 0) ? model.At(b.ParentIndex) : b.RootCorrection;
		let goal = end + (settings.Target - end) * weight;
		let goalTurn = settings.MatchRotation ? Slerp(turn, settings.TargetRotation, weight) : turn;
		localPoses[chain.End].Position = TransformPoint(goal, Inverse(parent));
		localPoses[chain.End].Rotation = Normalized(Inverse(RotationOf(parent)) * goalTurn);
		model.RebuildFrom(skeleton, localPoses, chain.End);

		var meet = settings;
		meet.UseTip = true;
		meet.Tip = tip;
		meet.Target = Position(model.At(chain.End));
		meet.MatchRotation = false;
		meet.Weight = 1.0f;
		let met = SolveTwoBone(skeleton, localPoses, model, .(chain.Start, chain.Mid, -1), meet);
		// Reached when the end is on the target and the chain met it.
		result.Error = Math.Max(Length(Position(model.At(chain.End)) - settings.Target), met.Error);
		result.Reached = result.Error <= ReachTolerance * Math.Max(reach, Epsilon);
		return result;
	}

	/// Points the last bone's aim axis at `settings.Target`, the swing shared along `bones` (root
	/// first): bone i takes `shares[i]` of what is still to go (a spine: 0.3, 0.5, 1.0; the last
	/// share 1 lands it exactly). Empty `shares` gives the last bone all of it. The direction is
	/// held within MaxAngle of the animated one, and the up axis is then turned toward `Up` (or
	/// back to the animated up) about the aim axis. The error is the angle left to the target.
	public static IkResult SolveAim(Skeleton skeleton, Span<BoneTransform> localPoses,
		ModelPoseCache model, Span<int32> bones, Span<float> shares, AimIkSettings settings)
	{
		var result = IkResult();
		if (bones.IsEmpty || (bones.Length > MaxAimBones) || (!shares.IsEmpty && (shares.Length != bones.Length))
			|| (LengthSquared(settings.AimAxis) < 1.0e-12f))
			return result;
		for (int i < bones.Length)
		{
			if (!InPose(skeleton, localPoses, bones[i]) || ((i > 0) && !IsBelow(skeleton, bones[i], bones[i - 1])))
				return result;
		}
		EnsureModel(skeleton, localPoses, model);
		result.Valid = true;

		let last = bones[bones.Length - 1];
		let aimAxis = Normalized(settings.AimAxis);
		let animated = RotationOf(model.At(last));
		let aimFrom = Normalized(RotateVector(animated, aimAxis));
		let upFrom = RotateVector(animated, settings.UpAxis);

		// The direction to aim from `origin`: the target's, held within MaxAngle of the animated.
		Float3 Wanted(Float3 origin)
		{
			let toTarget = settings.Target - origin;
			if (Length(toTarget) <= Epsilon)
				return aimFrom;
			let direction = Normalized(toTarget);
			let angle = Acos(Math.Clamp(Dot(aimFrom, direction), -1.0f, 1.0f));
			if (angle <= settings.MaxAngle)
				return direction;
			var axis = Cross(aimFrom, direction);
			axis = (LengthSquared(axis) > 1.0e-12f) ? Normalized(axis) : AnyPerpendicular(aimFrom);
			return RotateVector(Quaternion.FromAxisAngle(axis, settings.MaxAngle), aimFrom);
		}
		Float3 AimNow() => Normalized(RotateVector(RotationOf(model.At(last)), aimAxis));
		float Missed()
		{
			let toTarget = settings.Target - Position(model.At(last));
			return (Length(toTarget) > Epsilon) ? Acos(Math.Clamp(Dot(AimNow(), Normalized(toTarget)), -1.0f, 1.0f)) : 0.0f;
		}

		if (settings.Weight <= 0.0f)
		{
			result.Error = Missed();
			result.Reached = result.Error <= ReachTolerance;
			return result;
		}

		BoneTransform[MaxAimBones] before = ?;
		for (int i < bones.Length)
			before[i] = localPoses[bones[i]];
		for (int i < bones.Length)
		{
			let share = shares.IsEmpty ? ((i + 1 == bones.Length) ? 1.0f : 0.0f) : Math.Clamp(shares[i], 0.0f, 1.0f);
			if (share <= 0.0f)
				continue;
			// The target direction from where the last bone is NOW (a turn above it moved it).
			let direction = Wanted(Position(model.At(last)));
			let turn = Slerp(Quaternion.Identity, FromTo(AimNow(), direction), share);
			TurnInModel(skeleton, localPoses, model, bones[i], turn);
			model.RebuildFrom(skeleton, localPoses, bones[i]);
		}

		// Roll the last bone about its aim so the up axis leans where it should.
		let aim = AimNow();
		let upWanted = Perpendicular(settings.HasUp ? settings.Up : upFrom, aim);
		let upHas = Perpendicular(RotateVector(RotationOf(model.At(last)), settings.UpAxis), aim);
		if ((LengthSquared(upWanted) > 1.0e-10f) && (LengthSquared(upHas) > 1.0e-10f))
		{
			let roll = SignedAngle(Normalized(upHas), Normalized(upWanted), aim);
			TurnInModel(skeleton, localPoses, model, last, Quaternion.FromAxisAngle(aim, roll));
			model.RebuildFrom(skeleton, localPoses, last);
		}

		if (settings.Weight < 1.0f)
		{
			for (int i < bones.Length)
				localPoses[bones[i]].Rotation = Slerp(before[i].Rotation, localPoses[bones[i]].Rotation, settings.Weight);
			model.RebuildFrom(skeleton, localPoses, bones[0]);
		}

		result.Error = Missed();
		result.Reached = result.Error <= ReachTolerance;
		return result;
	}

	/// Where each foot stands in the animated pose (model space): the points a caller probes the
	/// ground under, before the solve changes anything. Fills `outFeet` up to the legs' count.
	public static void FootIkAnimatedFeet(ModelPoseCache model, Span<FootIkLeg> legs, Span<Float3> outFeet)
	{
		for (int i = 0; (i < legs.Length) && (i < outFeet.Length); i++)
			outFeet[i] = Position(model.At(legs[i].Chain.End));
	}

	/// Feet that stand on the ground under them (inverse-kinematics.md P3): each planted foot
	/// rises or falls by the ground's height under it (measured from the animation's ground,
	/// GroundHeight along up) and turns to the slope within MaxTilt; the pelvis lowers by the
	/// deepest correction, clamped, so the lower foot can reach; a foot the animation lifts above
	/// LiftHeight is swinging and is left to the animation. In order: the pelvis, its rebuild,
	/// then each leg. The corrections ease by `deltaSeconds` through `state`.
	public static FootIkResult SolveFootIk(Skeleton skeleton, Span<BoneTransform> localPoses, ModelPoseCache model,
		int32 pelvis, Span<FootIkLeg> legs, Span<FootGround> grounds, FootIkSettings settings, ref FootIkState state,
		float deltaSeconds)
	{
		var result = FootIkResult();
		if (legs.IsEmpty || (legs.Length > MaxFootIkLegs) || (grounds.Length != legs.Length)
			|| (LengthSquared(settings.Up) < 1.0e-12f))
			return result;
		// A foot below its shin is the chain's end; a foot elsewhere (an IK target bone off the
		// root, as asset pack rigs export it) is DETACHED: it is moved itself and the leg bent to
		// meet it with the point of the shin that met it in the animated pose.
		bool[MaxFootIkLegs] detached = default;
		for (int i < legs.Length)
		{
			let chain = legs[i].Chain;
			if (!InPose(skeleton, localPoses, chain.Start) || !InPose(skeleton, localPoses, chain.Mid)
				|| !InPose(skeleton, localPoses, chain.End) || !IsBelow(skeleton, chain.Mid, chain.Start)
				|| (chain.End == chain.Mid) || (chain.End == chain.Start) || IsBelow(skeleton, chain.Start, chain.End))
				return result;
			detached[i] = !IsBelow(skeleton, chain.End, chain.Mid);
			// A foot the thigh carries but the shin does not: no meeting point.
			if (detached[i] && IsBelow(skeleton, chain.End, chain.Start))
				return result;
		}
		let movesPelvis = InPose(skeleton, localPoses, pelvis);
		EnsureModel(skeleton, localPoses, model);
		result.Valid = true;
		let up = Normalized(settings.Up);

		// The goals, from the animated pose.
		Float3[MaxFootIkLegs] feet = default;
		Quaternion[MaxFootIkLegs] footTurn = default;
		Float3[MaxFootIkLegs] tips = default;
		float[MaxFootIkLegs] offsetGoal = default;
		float[MaxFootIkLegs] plantGoal = default;
		for (int i < legs.Length)
		{
			feet[i] = Position(model.At(legs[i].Chain.End));
			footTurn[i] = RotationOf(model.At(legs[i].Chain.End));
			if (detached[i])
				tips[i] = TransformPoint(feet[i], Inverse(model.At(legs[i].Chain.Mid)));
			// No ground: the animation keeps the foot.
			if (!grounds[i].Hit)
				continue;
			let lift = Dot(feet[i], up) - settings.GroundHeight;
			let band = Math.Max(settings.LiftHeight, 1.0e-4f);
			plantGoal[i] = Math.Clamp(1.0f - (lift - settings.LiftHeight) / band, 0.0f, 1.0f);
			offsetGoal[i] = Dot(grounds[i].Point, up) - settings.GroundHeight;
		}

		// Ease toward them: the first solve takes them at once; a zero step, a paused scene still
		// evaluating, holds them.
		let primed = state.Primed;
		void Ease(ref float value, float goal)
		{
			if (!primed)
			{
				value = goal;
				return;
			}
			let rate = (goal > value) ? settings.RaiseRate : settings.LowerRate;
			value += (goal - value) * (1.0f - Exp(-Math.Max(rate, 0.0f) * Math.Max(deltaSeconds, 0.0f)));
		}
		var deepest = 0.0f;
		for (int i < legs.Length)
		{
			Ease(ref state.Offset[i], offsetGoal[i]);
			Ease(ref state.Plant[i], plantGoal[i]);
			deepest = Math.Min(deepest, state.Offset[i] * state.Plant[i]);
		}
		Ease(ref state.Pelvis, Math.Max(deepest, -Math.Max(settings.PelvisDropMax, 0.0f)));
		state.Primed = true;
		result.PelvisOffset = state.Pelvis;

		let weight = Math.Clamp(settings.Weight, 0.0f, 1.0f);
		if (weight <= 0.0f)
			return result;
		if (movesPelvis && (state.Pelvis != 0.0f))
		{
			// The pelvis lowers along model up, turned into its parent's space.
			let b = skeleton.GetBone(pelvis);
			let parent = (b.ParentIndex >= 0) ? model.At(b.ParentIndex) : b.RootCorrection;
			localPoses[pelvis].Position += TransformDirection(up * (state.Pelvis * weight), Inverse(parent));
			model.RebuildFrom(skeleton, localPoses, pelvis);
		}
		for (int i < legs.Length)
		{
			let legWeight = weight * state.Plant[i];
			if (legWeight <= 0.0f)
			{
				// Swinging: the animation's (only the pelvis carried it).
				result.FootError[i] = 0.0f;
				continue;
			}
			var leg = TwoBoneIkSettings();
			leg.Target = feet[i] + up * state.Offset[i];
			leg.HingeAxis = legs[i].HingeAxis;
			leg.Weight = legWeight;
			leg.MatchRotation = true;
			var tilt = Quaternion.Identity;
			let normal = (LengthSquared(grounds[i].Normal) > 1.0e-12f) ? Normalized(grounds[i].Normal) : up;
			let slope = Acos(Math.Clamp(Dot(up, normal), -1.0f, 1.0f));
			let axis = Cross(up, normal);
			if ((slope > 1.0e-5f) && (LengthSquared(axis) > 1.0e-12f))
				tilt = Quaternion.FromAxisAngle(Normalized(axis), Math.Min(slope, Math.Max(settings.MaxTilt, 0.0f)));
			leg.TargetRotation = tilt * footTurn[i];
			if (detached[i])
			{
				// The foot moves itself and the leg meets it with the tip it had in the animated
				// pose (taken before the pelvis moved the shin).
				leg.UseTip = true;
				leg.Tip = tips[i];
			}
			result.FootError[i] = SolveTwoBone(skeleton, localPoses, model, legs[i].Chain, leg).Error;
		}
		return result;
	}
}
