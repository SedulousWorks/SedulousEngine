using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// Something to take: walked over, it is taken (LootTaken with its value, a chime, and it is gone).
/// The level's target is taken the same way and says so instead (TargetTaken), so the game knows
/// the thief may now leave by the exit.
[Behaviour("lamplight.loot")]
[DisplayName("Loot"), Category("Lamplight")]
[Description("Something to take, turning to catch the eye: walked over, it is taken, the level's target among them.")]
class Loot : Behaviour
{
	[Description("The thief")]
	public EntityRef Thief = .();
	[Description("What it is worth")]
	public int32 Value = 10;
	[Description("The level's target: carried to the exit, it ends the level")]
	public bool Target = false;
	[Description("How near the thief takes it (m)")]
	public float Reach = 0.9f;
	[Description("How fast it turns, to catch the eye (turns a second)")]
	public float Spin = 0.6f;

	/// The thief Thief names in this scene, found as it starts.
	private EntityHandle mThief = .Invalid;
	/// Degrees.
	private float mTurn = 0.0f;
	/// Taken: its removal takes effect as the frame ends.
	private bool mTaken = false;

	protected override void OnStart()
	{
		mThief = Scene.FindEntity(Thief.Id);
	}

	protected override void OnUpdate(float dt)
	{
		if (mTaken)
			return;
		mTurn += Spin * 360.0f * dt;
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(DegreesToRadians(mTurn), 0.0f, 0.0f));
		if (!Scene.IsValid(mThief))
			return;
		let a = Scene.GetWorldPosition(Entity);
		let b = Scene.GetWorldPosition(mThief);
		let dx = a.X - b.X;
		let dz = a.Z - b.Z;
		if (dx * dx + dz * dz > Reach * Reach)
			return;
		mTaken = true;
		Pieces.PlayAt(Run, Target ? Assets.TakenSound : Assets.CoinsSound, a);
		if (Target)
			Post(TargetTaken(Value));
		else
			Post(LootTaken(Value));
		Scene.DestroyEntity(Entity);
	}
}
