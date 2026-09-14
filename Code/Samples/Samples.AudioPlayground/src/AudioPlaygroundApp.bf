using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Core;
using Sedulous.Engine.Audio;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.Render;
using Sedulous.Extensions.Imgui;
using Sedulous.Graphics;
using Sedulous.Render;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
using Sedulous.Shell;
using Samples.Common;
using cimgui_Beef;

namespace Samples.AudioPlayground;

/// The audio stack from a component to a speaker: a looping bed on the music bus, four spatial
/// emitters at four pitches, a reverb zone, and one shots fired through a cue.
///
/// Four pitches of ONE clip rather than four clips, because that is what proves the resampler:
/// the same samples come out at four different rates.
class AudioPlaygroundApp : DefaultApplication
{
	private Scene mScene = null;
	private EntityHandle mCamera = default;
	private List<EntityHandle> mEmitters = new .() ~ delete _;

	private AudioClip mAmbient = null ~ delete _;
	private AudioClip mBeepHigh = null ~ delete _;
	private AudioClip mBeepLow = null ~ delete _;
	private AudioClip mClick = null ~ delete _;
	private SoundCue mShotCue = null ~ delete _;

	private ImguiSubsystem mOverlay = null ~ delete _;

	private VoiceHandle mLastOneShot = default;
	private Float3 mLastOneShotPosition = .(0, 0, 0);
	private bool mHaveOneShot = false;
	private uint32 mRandomState = 0x12345678;

	private FlyCamera mFly = .();

	public override void Configure(IApplicationHost host)
	{
		base.Configure(host); // this is what registers the audio subsystem

		let graphics = host.Graphics;
		if ((graphics != null) && (graphics.Raw != null))
		{
			mOverlay = new ImguiSubsystem(graphics.Raw, graphics.FramesInFlight);
			host.Context.RegisterSubsystem<ImguiSubsystem>(mOverlay);
		}
	}

	public override void OnLaunch(IApplicationHost host)
	{
		base.OnLaunch(host);

		if (Audio == null)
			return;

		mScene = PrimaryScenes.CreateScene("audio-playground");

		mAmbient = SampleClips.Load("ambient_loop.wav", true);
		mBeepHigh = SampleClips.Load("beep_high.wav");
		mBeepLow = SampleClips.Load("beep_low.wav", true);
		mClick = SampleClips.Load("click.wav");

		// The camera entity IS the listener, so flying is what moves the ears.
		mCamera = mScene.CreateEntity("camera");
		if (let cameras = mScene.GetSystem<CameraComponentManager>())
			cameras.Add(mCamera);
		mScene.GetSystem<AudioListenerComponentManager>().Add(mCamera);

		mFly.Position = .(0.0f, 2.0f, 14.0f);
		mFly.MoveSpeed = 8.0f;
		mFly.FastSpeed = 25.0f;

		{
			let entity = mScene.CreateEntity("ambient");
			let source = mScene.GetSystem<AudioSourceComponentManager>().Add(entity);
			source.Clip.SetDirect(mAmbient);
			source.Bus = .Music;
			source.Spatial = false;
			source.Loop = true;
			source.AutoPlay = true;
			// QUIET, because the bed shares the beeps' range: level is what keeps the
			// positional sources readable over it.
			source.Volume = 0.35f;
		}

		// Four emitters at the compass points, the same clip at four pitches.
		let pitches = scope float[](0.75f, 1.0f, 1.5f, 2.0f);
		for (int i < 4)
		{
			let angle = Math.PI_f * 0.5f * (float)i;
			let entity = mScene.CreateEntity("emitter");
			mScene.SetLocalPosition(entity, .(10.0f * Math.Cos(angle), 1.5f,
				10.0f * Math.Sin(angle)));

			let source = mScene.GetSystem<AudioSourceComponentManager>().Add(entity);
			source.Clip.SetDirect(mBeepLow);
			source.Loop = true;
			source.AutoPlay = true;
			source.Spatial = true;
			source.Pitch = pitches[i];
			source.Volume = 0.7f;
			source.MinDistance = 2.0f;
			source.MaxDistance = 60.0f;
			source.DopplerFactor = 1.0f;
			mEmitters.Add(entity);
		}

		// A reverb zone over the origin: the tail fades in across its edge band, so flying
		// through it is audible as a room rather than a switch.
		{
			let zone = mScene.CreateEntity("cave-zone");
			let reverb = mScene.GetSystem<AudioReverbZoneComponentManager>().Add(zone);
			reverb.Radius = 12.0f;
			reverb.EdgeFade = 0.4f;
			reverb.RoomSize = 0.8f;
			reverb.Damping = 0.2f;
			reverb.WetLevel = 0.6f;
		}

		// The one shots go through a CUE: weighted variants with pitch jitter, so repeated
		// fire does not sound like the same sample twice.
		mShotCue = new SoundCue();
		mShotCue.Variants.Add(.(mBeepHigh, 3.0f));
		mShotCue.Variants.Add(.(mClick, 2.0f));
		mShotCue.Variants.Add(.(mBeepLow, 1.0f));
		mShotCue.PitchMin = 0.85f;
		mShotCue.PitchMax = 1.25f;

		mScene.Start();
		mScene.SetSimulationEnabled(true);

		if ((Audio.Engine != null) && Audio.Engine.IsHeadless)
			Console.WriteLine("AudioPlayground: no audio device - running silent.");

		Console.WriteLine("AudioPlayground: WASD and the right button to fly. Left button fires a");
		Console.WriteLine("positional one shot, Space clicks, T pauses the scene, Esc quits.");
	}

	public override void OnUpdate(IApplicationHost host, float deltaTime)
	{
		base.OnUpdate(host, deltaTime);

		let input = (host.Shell != null) ? host.Shell.Input : null;
		if (input != null)
			mFly.Update(input.Keyboard, input.Mouse, deltaTime);
		PushCameraToEntity();

		if ((input == null) || (mScene == null))
			return;

		if (input.Keyboard.IsKeyPressed(.Escape))
			host.RequestExit(0);

		if (input.Mouse.IsButtonPressed(.Left) && (Audio != null))
		{
			// Ahead of the camera and scattered, so each shot lands somewhere new and the
			// panning is audible.
			let forward = mFly.Forward;
			let distance = 4.0f + 8.0f * Random01();
			let position = Float3(
				mFly.Position.X + forward.X * distance + (Random01() - 0.5f) * 4.0f,
				mFly.Position.Y + forward.Y * distance,
				mFly.Position.Z + forward.Z * distance + (Random01() - 0.5f) * 4.0f);

			AudioPlayParams parameters = .();
			parameters.MinDistance = 1.5f;
			parameters.MaxDistance = 50.0f;
			mLastOneShot = Audio.PlayCueOneShot3D(mShotCue, position, parameters);
			mLastOneShotPosition = position;
			mHaveOneShot = true;
		}

		if (input.Keyboard.IsKeyPressed(.Space) && (Audio != null))
			Audio.PlayOneShot(mClick, .UI);

		// Pausing the scene fades ITS voices and leaves the rest playing, which is the whole
		// point of a per scene voice group.
		if (input.Keyboard.IsKeyPressed(.T))
			mScene.SetSimulationEnabled(!mScene.SimulationEnabled);

		DrawEmitterGizmos(host);

		if (mOverlay != null)
		{
			mOverlay.NewFrame(input, deltaTime);
			BuildPanel();
		}
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		// The aspect follows the WINDOW, so a resize does not stretch what is heard to be in
		// front of the camera away from where it is drawn.
		if ((mScene != null) && (frame.Height > 0))
		{
			if (let cameras = mScene.GetSystem<CameraComponentManager>())
			{
				if (let camera = cameras.Get(mCamera))
					camera.Aspect = (float)frame.Width / (float)frame.Height;
			}
		}

		base.OnRenderWindow(host, ref frame);

		if (mOverlay != null)
			mOverlay.Render(ref frame);
	}

	/// A small deterministic generator, so a run is repeatable and nothing drags in a library
	/// for four random numbers.
	private float Random01()
	{
		mRandomState = mRandomState &* 1664525 &+ 1013904223;
		return (float)((mRandomState >> 8) & 0xFFFFFF) / 16777215.0f;
	}

	private void DrawEmitterGizmos(IApplicationHost host)
	{
		let renderer = host.Context.GetSubsystem<RenderSubsystem>();
		if ((renderer == null) || (mScene == null))
			return;

		let draw = renderer.DebugScene(mScene);
		for (let emitter in mEmitters)
			draw.DrawWireSphere(mScene.GetWorldPosition(emitter), 0.5f, .(0.3f, 0.9f, 1.0f, 1.0f));

		// The last shot is drawn only while it is still SOUNDING, which is what ties the mark
		// to the sound rather than to the click.
		if (mHaveOneShot && (Audio != null) && Audio.IsPlaying(mLastOneShot))
			draw.DrawWireSphere(mLastOneShotPosition, 0.35f, .(1.0f, 0.8f, 0.2f, 1.0f));
	}

	private void BuildPanel()
	{
		igSetNextWindowPos(.() { x = 10, y = 10 }, (int32)ImGuiCond.ImGuiCond_FirstUseEver, .());
		igBegin("Audio", null, 0);

		let engine = (Audio != null) ? Audio.Engine : null;
		if (engine != null)
		{
			let device = engine.IsHeadless ? "  (no device)" : "";
			igText(scope $"voices: {engine.ActiveVoiceCount}{device}");

			let buses = scope AudioBus[](.Master, .Effects, .Music, .UI);
			let labels = scope char8*[]("Master".CStr(), "Effects".CStr(), "Music".CStr(),
				"UI".CStr());
			for (int i < 4)
			{
				var volume = engine.BusVolume(buses[i]);
				if (igSliderFloat(labels[i], &volume, 0.0f, 1.5f, "%.2f", 0))
					engine.SetBusVolume(buses[i], volume);
			}
		}

		if (mScene != null)
		{
			let state = mScene.SimulationEnabled ? "running" : "PAUSED";
			igText(scope $"simulation: {state} (T toggles)");
		}

		igText("left button fires a 3D one shot, Space clicks, Esc quits");
		igEnd();
	}

	private void PushCameraToEntity()
	{
		if (mScene == null)
			return;

		var transform = mScene.GetLocalTransform(mCamera);
		transform.Position = mFly.Position;
		transform.Rotation = mFly.Rotation;
		mScene.SetLocalTransform(mCamera, transform);
	}
}
