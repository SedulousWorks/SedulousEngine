using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Gameplay;

namespace Snowline;

/// Judges a jump over a crevasse. On an entity at the crevasse's lip, facing down the course
/// (Tools/course.py; a kicker launches the rider off the edge).
///
/// Once the rider passes the lip within Reach of it, its first touch of the snow is judged: short
/// of Short metres past the lip (in the crevasse, before its ramp up) is a crash (Board.Crash); at
/// or past it is a cleared gap (GapCleared, the distance flown at the touch), which the game scores.
/// A rider who rolls in without leaving the snow is short as well, once it is past the crevasse's
/// wall. A rider flying over is judged where it touches down, so the distance is the one flown.
[Behaviour("snowline.gap")]
[DisplayName("Gap"), Category("Snowline")]
[Description("Judges a jump over a crevasse: a landing short of its far side is a crash, past it a cleared gap.")]
class Gap : Behaviour
{
	[Description("The course's heading at the lip (radians; 0 runs toward +Z)")]
	public float Heading = 0.0f;
	[Description("Past the lip, how far a landing is still in the crevasse (m)")]
	public float Short = 13.5f;
	[Description("How far either side of the course the crevasse spans (m)")]
	public float Reach = 30.0f;

	private EntityHandle mRider = .Invalid;
	private float mLastAlong = -1000.0f;
	/// Past the lip this pass, not judged yet.
	private bool mArmed = false;
	/// Off the snow since the lip.
	private bool mFlew = false;

	protected override void OnStart()
	{
		// A new run: the gap waits for the rider again.
		Listen<RunRestart>(new [=this] (evt) =>
			{
				mLastAlong = -1000.0f;
				mArmed = false;
				mFlew = false;
			});
		mRider = Scene.FindEntityByName("Rider");
	}

	protected override void OnUpdate(float dt)
	{
		if (!Scene.IsValid(mRider))
			return;
		let offset = Scene.GetWorldPosition(mRider) - Scene.GetWorldPosition(Entity);
		let along = Pieces.Along(offset, Heading);
		let across = Pieces.Across(offset, Heading);
		if (!mArmed && (mLastAlong < 0.0f) && (along >= 0.0f) && (Abs(across) <= Reach))
		{
			mArmed = true;
			mFlew = false;
		}
		mLastAlong = along;
		if (!mArmed)
			return;
		let rider = Scene.GetComponent<CharacterComponent>(mRider);
		let grounded = (rider != null) && rider.Grounded;
		if (!grounded)
			mFlew = true;
		if (grounded && (mFlew || (along > 2.0f)))
			Judge(along); // past the crevasse by now if it flew over it
	}

	private void Judge(float along)
	{
		mArmed = false;
		if (along < Short)
			Pieces.BoardOn(Scene, mRider)?.Crash();
		else
			Post(GapCleared(along));
	}
}
