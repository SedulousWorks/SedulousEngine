using System;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Animation;

namespace Sedulous.Editor.Scene;

/// Inverse kinematics on the selected entity (inverse-kinematics.md P4): the solve itself while
/// the scene runs, else the chain where the bind pose puts it, its target and its pole (or up), so
/// a chain is seen before it is run. A bone name the skeleton lacks breaks the line there and
/// marks the entity orange.
static class IkGizmoDraw
{
	public const Color Chain = .(0.3f, 0.7f, 1.0f, 1.0f);
	public const Color Target = .(0.2f, 0.9f, 0.3f, 1.0f);
	public const Color Pole = .(0.8f, 0.4f, 1.0f, 1.0f);
	public const Color Missing = .(1.0f, 0.55f, 0.1f, 1.0f);

	/// The orange mark at the entity: no animator, or a bone the skeleton lacks.
	public static void MarkMissing(GizmoContext ctx, EntityHandle owner)
		=> ctx.Debug.DrawWireSphere(ctx.Scene.GetWorldPosition(owner), 0.08f, Missing, 10, true);

	/// A chain of named bones where the bind pose stands, joint spheres and links. Answers the
	/// last joint drawn, if any.
	public static bool DrawBindChain(GizmoContext ctx, EntityHandle owner, IkAuthoringAnimator animator,
		Span<StringView> bones, out Float3 outLast)
	{
		outLast = .(0, 0, 0);
		var any = false;
		var havePrevious = false;
		var previous = Float3(0, 0, 0);
		for (let bone in bones)
		{
			if (!IkScene.BindBoneWorld(ctx.Scene, animator, bone, let at))
			{
				MarkMissing(ctx, owner);
				havePrevious = false;
				continue;
			}
			if (havePrevious)
				ctx.Debug.DrawLine(previous, at, Chain, true);
			ctx.Debug.DrawWireSphere(at, 0.02f, Chain, 8, true);
			previous = at;
			havePrevious = true;
			outLast = at;
			any = true;
		}
		return any;
	}

	public static bool EntityAt(GizmoContext ctx, EntityRef reference, out Float3 outWorld)
	{
		outWorld = .(0, 0, 0);
		if (reference.IsNil)
			return false;
		let e = ctx.Scene.FindEntity(reference.Id);
		if (!ctx.Scene.IsValid(e))
			return false;
		outWorld = ctx.Scene.GetWorldPosition(e);
		return true;
	}

	/// While the scene runs the component draws its own solve; true when it did.
	public static bool DrawSolving(GizmoContext ctx, IkRuntime runtime)
	{
		if ((runtime == null) || (runtime.Status != .Solving) || !runtime.Modifier.Solved)
			return false;
		IkScene.Draw(ctx.Debug, runtime);
		return true;
	}

	/// The animator, or the orange mark and false.
	public static bool Animator(GizmoContext ctx, EntityHandle owner, out IkAuthoringAnimator outAnimator)
	{
		if (IkScene.FindAuthoringAnimator(ctx.Scene, owner, out outAnimator) == .Found)
			return true;
		MarkMissing(ctx, owner);
		return false;
	}
}

class TwoBoneIkGizmoRenderer : IGizmoRenderer
{
	public Type ComponentType => typeof(TwoBoneIkComponent);

	public void Draw(void* component, EntityHandle owner, GizmoContext ctx)
	{
		let c = (TwoBoneIkComponent*)component;
		if (IkGizmoDraw.DrawSolving(ctx, c.Runtime))
			return;
		if (!IkGizmoDraw.Animator(ctx, owner, let animator))
			return;
		StringView[3] bones = .(c.StartBone, c.MidBone, c.EndBone);
		IkGizmoDraw.DrawBindChain(ctx, owner, animator, bones, ?);
		if (!IkGizmoDraw.EntityAt(ctx, c.Target, var target))
			target = ctx.Scene.GetWorldPosition(owner);
		ctx.Debug.DrawWireSphere(target, 0.05f, IkGizmoDraw.Target, 12, true);
		if (IkGizmoDraw.EntityAt(ctx, c.Pole, let pole))
		{
			if (IkScene.BindBoneWorld(ctx.Scene, animator, c.MidBone, let mid))
				ctx.Debug.DrawLine(mid, pole, IkGizmoDraw.Pole, true);
		}
	}
}

class AimIkGizmoRenderer : IGizmoRenderer
{
	public Type ComponentType => typeof(AimIkComponent);

	public void Draw(void* component, EntityHandle owner, GizmoContext ctx)
	{
		let c = (AimIkComponent*)component;
		if (IkGizmoDraw.DrawSolving(ctx, c.Runtime))
			return;
		if (!IkGizmoDraw.Animator(ctx, owner, let animator))
			return;
		StringView[InverseKinematics.MaxAimBones] bones = default;
		var count = 0;
		for (let bone in c.Bones)
		{
			if (count < InverseKinematics.MaxAimBones)
				bones[count++] = bone.Bone;
		}
		let drew = IkGizmoDraw.DrawBindChain(ctx, owner, animator, .(&bones[0], count), let last);
		if (!IkGizmoDraw.EntityAt(ctx, c.Target, var target))
			target = ctx.Scene.GetWorldPosition(owner);
		ctx.Debug.DrawWireSphere(target, 0.05f, IkGizmoDraw.Target, 12, true);
		if (drew)
		{
			ctx.Debug.DrawLine(last, target, IkGizmoDraw.Target, true);
			if (IkGizmoDraw.EntityAt(ctx, c.Up, let up))
				ctx.Debug.DrawLine(last, up, IkGizmoDraw.Pole, true);
		}
	}
}

class FootIkGizmoRenderer : IGizmoRenderer
{
	public Type ComponentType => typeof(FootIkComponent);

	public void Draw(void* component, EntityHandle owner, GizmoContext ctx)
	{
		let c = (FootIkComponent*)component;
		if (IkGizmoDraw.DrawSolving(ctx, c.Runtime))
			return;
		if (!IkGizmoDraw.Animator(ctx, owner, let animator))
			return;
		// Each leg, and the reach of its ground probe (above and below the foot, along the
		// model's up).
		let up = Normalized(TransformDirection(.(0, 1, 0), ctx.Scene.GetWorldMatrix(animator.ModelEntity)));
		for (let leg in c.Legs)
		{
			StringView[3] bones = .(leg.StartBone, leg.MidBone, leg.EndBone);
			IkGizmoDraw.DrawBindChain(ctx, owner, animator, bones, ?);
			if (IkScene.BindBoneWorld(ctx.Scene, animator, leg.EndBone, let foot))
				ctx.Debug.DrawLine(foot + up * c.RayUp, foot - up * c.RayDown, IkGizmoDraw.Target, true);
		}
	}
}
