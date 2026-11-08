using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Resource;
using Sedulous.Animation;
using Sedulous.Engine.Gameplay;

namespace PaperKid;

/// A dog or a cat on a lawn of the title backdrop. It trots to a spot on its lawn (the rectangle
/// XMin..XMax by ZMin..ZMax), does something there (stands about, sits, lies down, or its own
/// thing: the dog sniffs the grass, the cat grooms), then trots to another spot.
///
/// Its model is its first child, with the clips the fields name. Every clip starts and ends in
/// the same standing pose, so a switch at a clip's end does not snap; the held actions last their
/// clip's length, and standing about loops the idle clip for a while.
///
/// It walks by the walk clip's own travel: the model's animator moves this entity by the clip's
/// root motion (Entity mode, aimed here), so the feet never slide. This only steers (it turns the
/// way it wants to go) and sets the pace (the clip's speed), slower while still turning.
[Behaviour("paperkid.pet")]
[DisplayName("Pet"), Category("PaperKid")]
[Description("Potters about a lawn: trots to a spot by its walk clip's root motion, then stands, sits, lies down or does its own thing.")]
class Pet : Behaviour
{
	[Description("Lawn's left edge (m)")]
	public float XMin = -12.0f;
	[Description("Lawn's right edge (m)")]
	public float XMax = -6.0f;
	[Description("Lawn's far edge (m)")]
	public float ZMin = 9.0f;
	[Description("Lawn's near edge (m)")]
	public float ZMax = 13.0f;
	[Description("Walking speed (m/s)")]
	public float Speed = 0.8f;
	[Description("Metres the walk clip covers at speed 1 (its root motion)")]
	public float WalkMetres = 0.55f;
	[Description("Walk (loops)")]
	public Ref<AnimationClip> WalkClip = .(Guid());
	[Description("Standing about (loops)")]
	public Ref<AnimationClip> IdleClip = .(Guid());
	[Description("Sitting down and up again")]
	public Ref<AnimationClip> SitClip = .(Guid());
	[Description("Sit clip's length (s)")]
	public float SitSeconds = 4.0f;
	[Description("Lying down and up again")]
	public Ref<AnimationClip> LieClip = .(Guid());
	[Description("Lie clip's length (s)")]
	public float LieSeconds = 5.0f;
	[Description("Its own thing (sniffing, grooming)")]
	public Ref<AnimationClip> OwnClip = .(Guid());
	[Description("Own clip's length (s)")]
	public float OwnSeconds = 3.0f;

	private EntityHandle mModel = .Invalid;
	private bool mWalking = false;
	private float mToX = 0.0f;
	private float mToZ = 0.0f;
	/// Radians; 0 faces +Z.
	private float mYaw = 0.0f;
	/// Seconds left of what it is doing where it stands.
	private float mLeft = 0.0f;

	protected override void OnStart()
	{
		mModel = Scene.GetFirstChild(Entity);
		mYaw = Feedback.Range(Random, -3.14159f, 3.14159f);
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(mYaw, 0.0f, 0.0f));
		// Start in the middle of something, not all walking off at once.
		DoSomething();
		mLeft = Feedback.Range(Random, 0.5f, mLeft);
	}

	protected override void OnUpdate(float dt)
	{
		if (!mWalking)
		{
			mLeft -= dt;
			if (mLeft <= 0.0f)
				WalkSomewhere();
			return;
		}
		let p = Scene.GetLocalTransform(Entity).Position;
		let dx = mToX - p.X;
		let dz = mToZ - p.Z;
		let far = Sqrt(dx * dx + dz * dz);
		if (far < 0.05f)
		{
			DoSomething();
			return;
		}
		// Turn toward the spot (the short way round, easing), and walk the way it faces, so it
		// curves round rather than sliding sideways.
		var turn = Atan2(dx, dz) - mYaw;
		while (turn > 3.14159f)
			turn -= 6.28318f;
		while (turn < -3.14159f)
			turn += 6.28318f;
		let ease = 4.0f * dt;
		mYaw += turn * ((ease < 1.0f) ? ease : 1.0f);
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(mYaw, 0.0f, 0.0f));
		// Slow while still turning a long way round, so it does not orbit the spot; and slow as it
		// arrives, so the clip's travel stops on the spot rather than past it.
		var facing = Cos(turn);
		if (facing < 0.2f)
			facing = 0.2f;
		var arriving = far / 0.3f;
		if (arriving > 1.0f)
			arriving = 1.0f;
		if (arriving < 0.3f)
			arriving = 0.3f;
		SetPace(Speed * facing * arriving);
	}

	private void WalkSomewhere()
	{
		mToX = Feedback.Range(Random, XMin, XMax);
		mToZ = Feedback.Range(Random, ZMin, ZMax);
		mWalking = true;
		PlayClip(WalkClip.Id);
		SetPace(Speed);
	}

	private void DoSomething()
	{
		mWalking = false;
		let pick = Feedback.IntRange(Random, 0, 3);
		if ((pick == 1) && (SitClip.Id != Guid()))
		{
			PlayClip(SitClip.Id);
			mLeft = SitSeconds;
		}
		else if ((pick == 2) && (LieClip.Id != Guid()))
		{
			PlayClip(LieClip.Id);
			mLeft = LieSeconds;
		}
		else if ((pick == 3) && (OwnClip.Id != Guid()))
		{
			PlayClip(OwnClip.Id);
			mLeft = OwnSeconds;
		}
		else
		{
			PlayClip(IdleClip.Id);
			mLeft = Feedback.Range(Random, 2.0f, 5.0f);
		}
		if (Scene.IsValid(mModel))
			Feedback.ClipSpeed(Scene, mModel, 1.0f);
	}

	private void PlayClip(Guid clip)
	{
		if (!Scene.IsValid(mModel) || (clip == Guid()))
			return;
		Feedback.PlayClip(Scene, mModel, clip);
	}

	private void SetPace(float pace)
	{
		if (Scene.IsValid(mModel))
			Feedback.ClipSpeed(Scene, mModel, pace / WalkMetres);
	}
}
