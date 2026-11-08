using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Gameplay;

namespace Snowline;

/// The player's own best run, ridden again beside them. On the ghost's entity, whose first child is
/// the rider model in its own see-through colour. Placed by Tools/course.py.
///
/// Every run is recorded from the rider's first frame (RunStarted) at SampleRate samples a second,
/// each sample the rider's position and facing (x, y, z, yaw). When a run sets the course's best
/// (the game's NewBest), its recording is saved as the course's ghost ("ghost.<scene>", a list of
/// numbers in the save) and becomes the ghost of the runs after it. The ghost rides the saved run,
/// interpolated between its samples; with none saved it stays hidden.
[Behaviour("snowline.player_ghost")]
[DisplayName("Player Ghost"), Category("Snowline")]
[Description("The player's best run on the course, recorded, saved and ridden again beside them.")]
class PlayerGhost : Behaviour
{
	/// x, y, z, yaw.
	private const int cSampleSize = 4;

	[Description("Samples recorded each second")]
	public float SampleRate = 10.0f;

	private EntityHandle mRider = .Invalid;
	private EntityHandle mModel = .Invalid;
	/// This run, as it is ridden.
	private List<float> mRecording = new .() ~ delete _;
	/// The best run, played back.
	private List<float> mGhost = new .() ~ delete _;
	private bool mRunStarted = false;
	private bool mRecordingOn = false;
	private float mTime = 0.0f;
	private float mNextSample = 0.0f;

	protected override void OnStart()
	{
		Listen<RunStarted>(new [=this] (evt) =>
			{
				mRunStarted = true;
				mRecordingOn = true;
			});
		Listen<RunRestart>(new [=this] (evt) => Restart());
		// The run is over: stop recording (the rider coasts on past the line).
		Listen<RunFinished>(new [=this] (evt) => { mRecordingOn = false; });
		Listen<NewBest>(new [=this] (evt) => KeepBest());
		mRider = Scene.FindEntityByName("Rider");
		mModel = Scene.GetFirstChild(Entity);
		if (let save = RunServices.Get<SaveFacade>(Run))
			save.GetFloats(Key(.. scope .()), mGhost);
		Show(mGhost.Count >= cSampleSize * 2);
	}

	/// A new run: record afresh, and ride the best from the top.
	private void Restart()
	{
		mRecording.Clear();
		mRecordingOn = true;
		mTime = 0.0f;
		mNextSample = 0.0f;
		Show(mGhost.Count >= cSampleSize * 2);
	}

	/// This run is the course's best: it is the ghost from now on, and it is saved.
	private void KeepBest()
	{
		mGhost.Clear();
		mGhost.AddRange(mRecording);
		if (let save = RunServices.Get<SaveFacade>(Run))
		{
			save.SetFloats(Key(.. scope .()), mGhost);
			save.Flush();
		}
	}

	protected override void OnUpdate(float dt)
	{
		if (!mRunStarted || !Scene.IsValid(mRider))
			return;
		mTime += dt;
		if (mRecordingOn && (mTime >= mNextSample))
		{
			Record();
			mNextSample += 1.0f / SampleRate;
		}
		Play();
	}

	private void Record()
	{
		let at = Scene.GetWorldPosition(mRider);
		mRecording.Add(at.X);
		mRecording.Add(at.Y);
		mRecording.Add(at.Z);
		mRecording.Add(Pieces.Yaw(Scene.GetLocalTransform(mRider).Rotation));
	}

	/// The saved run at this run's time, between its two samples; it stays at its last one once its
	/// run is over.
	private void Play()
	{
		let samples = mGhost.Count / cSampleSize;
		if (samples < 2)
			return;
		var at = mTime * SampleRate;
		var i = (int)at;
		if (i >= samples - 1)
		{
			i = samples - 2;
			at = (float)(samples - 1);
		}
		let k = at - (float)i;
		let a = i * cSampleSize;
		let b = a + cSampleSize;
		let p = Float3(mGhost[a] + (mGhost[b] - mGhost[a]) * k,
			mGhost[a + 1] + (mGhost[b + 1] - mGhost[a + 1]) * k,
			mGhost[a + 2] + (mGhost[b + 2] - mGhost[a + 2]) * k);
		let turn = Pieces.Wrap(mGhost[b + 3] - mGhost[a + 3]);
		let yaw = mGhost[a + 3] + turn * k;
		Scene.SetLocalPosition(Entity, p);
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(yaw, 0.0f, 0.0f));
	}

	private void Show(bool visible)
	{
		if (Scene.IsValid(mModel))
			Scene.SetActive(mModel, visible);
	}

	/// The course's ghost's key in the save.
	private void Key(String outKey)
	{
		outKey.AppendF("ghost.{}", Scene.Name);
	}
}
