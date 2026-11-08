using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Resource;
using Sedulous.Animation;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Gameplay;

namespace SkyHopper;

/// A patroller: it walks back and forth along X between two points, facing the way it walks.
/// Touching it hurts the player, unless the player comes down on it from the air, which defeats
/// it (EnemyDefeated) and bounces the player off it. On the enemy's entity, whose first child is
/// its model.
///
/// Touching is a box, not a sphere: within Radius across the ground and with the player's centre
/// no higher than TouchHeight above the enemy's origin (and not below it). Only a player in the
/// air and on the way down stomps; one on the ground, walking or standing into the enemy, is hurt,
/// however the enemy's origin sits against the ground the player walks on.
///
/// A flier (the bee) is the same enemy in the air: it hovers, bobbing HoverHeight up and down, and
/// may patrol across the path (along Z) rather than along it. It is stomped and hurts the same
/// way, measured from where it flies.
[Behaviour("skyhopper.enemy")]
[DisplayName("Enemy"), Category("Sky Hopper")]
[Description("Patrols back and forth, hurts the player it touches, and is defeated by a stomp from above.")]
class Enemy : Behaviour
{
	[Description("Patrol half-width along X (m)")]
	public float PatrolDistance = 3.0f;
	[Description("Walk speed (m/s)")]
	public float Speed = 2.0f;
	[Description("Touch reach across the ground, enemy to player (m)")]
	public float Radius = 1.1f;
	[Description("Touching while the player's centre is at most this far above the enemy's origin (m)")]
	public float TouchHeight = 1.8f;
	[Description("Falling at least this fast counts as coming down on the enemy (m/s)")]
	public float StompSpeed = 1.0f;
	[Description("The model's walk clip; none keeps its idle")]
	public Ref<AnimationClip> WalkClip = .(Guid());
	[Description("Hover: bob this far up and down as it patrols (m); 0 walks")]
	public float HoverHeight = 0.0f;
	[Description("Hover bob rate (rad/s)")]
	public float HoverSpeed = 2.0f;
	[Description("Patrol along Z (across the path) rather than X")]
	public bool PatrolAlongZ = false;

	private EntityHandle mPlayer = .Invalid;
	private Float3 mHome = .(0.0f, 0.0f, 0.0f);
	private float mOffset = 0.0f;
	private float mDirection = 1.0f;
	private float mLastPlayerY = 0.0f;
	private float mTime = 0.0f;
	/// Stomped: its removal takes effect as the frame ends, and it does nothing more.
	private bool mDefeated = false;

	protected override void OnStart()
	{
		mPlayer = Scene.FindEntityByName("Player");
		mHome = Scene.GetLocalTransform(Entity).Position;
		let model = Scene.GetFirstChild(Entity);
		if (Scene.IsValid(model) && (WalkClip.Id != Guid()))
		{
			if (let animation = Scene.GetSystem<SkeletalAnimationComponentManager>())
			{
				animation.SetClip(model, WalkClip.Id);
				animation.Play(model);
			}
		}
		if (Scene.IsValid(mPlayer))
			mLastPlayerY = Scene.GetWorldPosition(mPlayer).Y;
	}

	protected override void OnUpdate(float dt)
	{
		if (mDefeated)
			return;
		mOffset += mDirection * Speed * dt;
		if (mOffset > PatrolDistance)
		{
			mOffset = PatrolDistance;
			mDirection = -1.0f;
		}
		else if (mOffset < -PatrolDistance)
		{
			mOffset = -PatrolDistance;
			mDirection = 1.0f;
		}
		mTime += dt;
		let bob = Sin(mTime * HoverSpeed) * HoverHeight;
		if (PatrolAlongZ)
		{
			Scene.SetLocalPosition(Entity, .(mHome.X, mHome.Y + bob, mHome.Z + mOffset));
			Scene.SetLocalRotation(Entity, Quaternion.FromAxisAngle(Float3.UnitY, (mDirection > 0.0f) ? 0.0f : 3.14159f));
		}
		else
		{
			Scene.SetLocalPosition(Entity, .(mHome.X + mOffset, mHome.Y + bob, mHome.Z));
			Scene.SetLocalRotation(Entity, Quaternion.FromAxisAngle(Float3.UnitY, (mDirection > 0.0f) ? 1.5708f : -1.5708f));
		}

		if (!Scene.IsValid(mPlayer))
			return;
		let at = Scene.GetWorldPosition(mPlayer);
		let fallSpeed = (dt > 0.0f) ? (mLastPlayerY - at.Y) / dt : 0.0f;
		mLastPlayerY = at.Y;
		let here = Scene.GetWorldPosition(Entity);
		let dx = at.X - here.X;
		let dz = at.Z - here.Z;
		let above = at.Y - here.Y;
		if ((dx * dx + dz * dz >= Radius * Radius) || (above > TouchHeight) || (above < 0.0f))
			return;
		let player = Scene.GetSystem<BehaviourManager<PlayerController>>()?.Get(mPlayer);
		let character = Scene.GetComponent<CharacterComponent>(mPlayer);
		let airborne = (character != null) && !character.Grounded;
		if (airborne && (fallSpeed >= StompSpeed))
		{
			mDefeated = true;
			Post(EnemyDefeated(1));
			if ((player != null) && player.IsActive)
				player.Bounce();
			Feedback.Spawn(Scene, Assets.StompStars, here + Float3(0.0f, 0.4f, 0.0f));
			Feedback.Play(Run, Assets.SquashSound);
			Scene.DestroyEntity(Entity);
		}
		else if ((player != null) && player.IsActive)
		{
			player.Hurt();
		}
	}
}
