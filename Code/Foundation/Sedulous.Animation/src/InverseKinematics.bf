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
		let bindC = Position(Inverse(skeleton.GetBone(chain.End).InverseBindPose));
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
	/// reach, else stopped at TwoBoneMaxReach of full reach (or the chain's shortest fold) and
	/// pointed at it. Bone lengths are the pose's own (a rotation keeps them; the bind pose's
	/// would miss when an animation moved a bone). The mid joint stays in the bend plane, so it
	/// never rolls or flips between frames. Writes the start and mid local rotations, and the
	/// end's with MatchRotation.
	public static IkResult SolveTwoBone(Skeleton skeleton, Span<BoneTransform> localPoses,
		ModelPoseCache model, TwoBoneIkChain chain, TwoBoneIkSettings settings)
	{
		var result = IkResult();
		if (!InPose(skeleton, localPoses, chain.Start) || !InPose(skeleton, localPoses, chain.Mid)
			|| !InPose(skeleton, localPoses, chain.End) || !IsBelow(skeleton, chain.Mid, chain.Start)
			|| !IsBelow(skeleton, chain.End, chain.Mid))
			return result;
		EnsureModel(skeleton, localPoses, model);
		result.Valid = true;

		let a = Position(model.At(chain.Start));
		let b = Position(model.At(chain.Mid));
		let c = Position(model.At(chain.End));
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
		BoneTransform[3] before = .(localPoses[chain.Start], localPoses[chain.Mid], localPoses[chain.End]);

		// 1. Open or close the mid joint, in the chain's bend plane, to the distance it must span.
		var along = c - a;
		along = (Length(along) > Epsilon * reach) ? Normalized(along) : Normalized(b - a);
		let side = BendSide(skeleton, model, chain, settings, along, upper);
		let hinge = Normalized(Cross(along, side));
		let shortest = Math.Max(Math.Abs(upper - lower), 1.0e-4f * reach);
		let span = Math.Clamp(Length(target - a), shortest, TwoBoneMaxReach * reach);
		let cosWanted = Math.Clamp((upper * upper + lower * lower - span * span) / (2.0f * upper * lower), -1.0f, 1.0f);
		// The interior angle measured about the hinge (a turn about it opens the joint), so a
		// straight chain or one bent the other way still lands on the bend side.
		let now = SignedAngle(Normalized(a - b), Normalized(c - b), hinge);
		TurnInModel(skeleton, localPoses, model, chain.Mid, Quaternion.FromAxisAngle(hinge, Acos(cosWanted) - now));
		model.RebuildFrom(skeleton, localPoses, chain.Mid);

		// 2. Swing the whole chain from the start: its end direction onto the target's, and its
		//    bend side onto the pole's (or carried along with the swing, without one).
		let bent = Position(model.At(chain.End));
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

		if (settings.MatchRotation)
		{
			let parent = ParentModelRotation(skeleton, model, chain.End);
			localPoses[chain.End].Rotation = Normalized(Inverse(parent) * settings.TargetRotation);
			model.RebuildFrom(skeleton, localPoses, chain.End);
		}

		if (settings.Weight < 1.0f)
		{
			int32[3] bones = .(chain.Start, chain.Mid, chain.End);
			for (int i < 3)
				localPoses[bones[i]].Rotation = Slerp(before[i].Rotation, localPoses[bones[i]].Rotation, settings.Weight);
			model.RebuildFrom(skeleton, localPoses, chain.Start);
		}

		result.Error = Length(Position(model.At(chain.End)) - target);
		result.Reached = result.Error <= ReachTolerance * reach;
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
}
