using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Gameplay;

namespace Snowline;

/// Launches the rider off the lip. On the kicker's entity, whose origin is where its ramp comes out
/// of the snow and whose +Z runs up the ramp (Tools/course.py, Tools/blender/props.py).
///
/// The ramp is solid to the rider, but a character's contacts over a curve at speed are uneven: one
/// run left the lip at 16 m/s, the next hopped on the curve, lost half its speed and barely left the
/// snow. So the kicker sets the launch itself: it notes the rider's speed as it reaches the foot,
/// and when the rider crosses the lip within the kicker's width it hands the board the launch
/// (Board.Launch): the entry speed less what the climb takes (v^2 = v0^2 - 2 g h), off the lip's
/// angle above level.
[Behaviour("snowline.kicker")]
[DisplayName("Kicker"), Category("Snowline")]
[Description("A jump: launches the rider off its lip at the entry speed less the climb, at the lip's angle.")]
class Kicker : Behaviour
{
	/// Stored as "rampRun": a field named Run would hide the behaviour's own Run (its run).
	[Description("From the origin up the ramp to the lip (m)")]
	public float RampRun = 3.88f;
	[Description("The lip's height above the origin (m)")]
	public float LipHeight = 1.4f;
	[Description("The ramp's angle at the lip, against its own base (degrees)")]
	public float LipAngle = 29.0f;
	[Description("The kicker's width (m)")]
	public float Width = 5.0f;

	private EntityHandle mRider = .Invalid;
	private float mLastAlong = -1000.0f;
	/// The rider's speed at the foot this pass; -1 for none.
	private float mEntrySpeed = -1.0f;

	protected override void OnStart()
	{
		// A new run: the kicker waits for the rider again.
		Listen<RunRestart>(new [=this] (evt) =>
			{
				mLastAlong = -1000.0f;
				mEntrySpeed = -1.0f;
			});
		mRider = Scene.FindEntityByName("Rider");
	}

	protected override void OnUpdate(float dt)
	{
		if (!Scene.IsValid(mRider))
			return;
		// The rider in the kicker's frame: along its ramp (level), across it.
		let forward = RotateVector(Scene.GetLocalTransform(Entity).Rotation, .(0.0f, 0.0f, 1.0f));
		let flat = Sqrt(forward.X * forward.X + forward.Z * forward.Z);
		let fx = forward.X / flat;
		let fz = forward.Z / flat;
		let d = Scene.GetWorldPosition(mRider) - Scene.GetWorldPosition(Entity);
		let along = d.X * fx + d.Z * fz;
		let across = d.X * fz - d.Z * fx;
		let within = Abs(across) <= Width * 0.5f;
		if (within && (mLastAlong < 0.0f) && (along >= 0.0f))
		{
			let rider = Scene.GetComponent<CharacterComponent>(mRider);
			if (rider != null)
				mEntrySpeed = Length(rider.Velocity);
		}
		let lip = RampRun * flat; // the lip's distance along, level
		if (within && (mEntrySpeed > 0.0f) && (mLastAlong < lip) && (along >= lip))
		{
			let squared = mEntrySpeed * mEntrySpeed - 2.0f * 9.81f * LipHeight;
			let speed = (squared > 1.0f) ? Sqrt(squared) : 1.0f;
			// The lip's angle above level: its angle on the ramp less how far the kicker tips down
			// the slope it stands on.
			let tilt = RadiansToDegrees(Atan2(-forward.Y, flat));
			Pieces.BoardOn(Scene, mRider)?.Launch(LipAngle - tilt, speed);
			mEntrySpeed = -1.0f;
		}
		if (along > lip + 2.0f)
			mEntrySpeed = -1.0f; // past the kicker (round its side): this pass is over
		mLastAlong = along;
	}
}
