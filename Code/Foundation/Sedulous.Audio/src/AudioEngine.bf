using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using miniaudio_Beef;

namespace Sedulous.Audio;

/// The audio engine.
///
/// A FIXED voice pool with generation checked handles, priority stealing and a recent play
/// merge, rather than unbounded voices: a game that can spawn a thousand sounds in a frame
/// will, and the pool is what makes that survivable.
///
/// Stopping and pausing ALWAYS fade, over about ten milliseconds, and a voice is reaped on
/// the caller's own thread once the fade lands. An instant cut is a click, and a click is the
/// most audible thing an engine can do.
///
/// HEADLESS mode opens no device at all and pumps the mixer from the update, so the whole
/// state machine runs deterministically in a test, in the cooker, and on a machine with no
/// sound card. Asking for a device and not getting one falls back to it rather than failing.
///
/// Every call belongs on ONE thread, the caller's; the backend owns the mixing thread and its
/// own control surface is safe for that pattern.
class AudioEngine
{
	/// The filter's order. Two poles is enough to hear and cheap enough to run per voice.
	private const uint32 cLowpassOrder = 2;
	private const float cDegreesToRadians = 3.14159265358979323846f / 180.0f;

	/// One open stream handed to the backend through the bridge.
	private class BridgedFile
	{
		public IStream Stream ~ delete _;
	}

	/// A clip registered with the backend's resource manager.
	///
	/// The manager holds the payload BY REFERENCE and does not copy it, so this owns the
	/// decoded frames and keeps the clip, and with it the encoded bytes, alive.
	private class RegisteredClip
	{
		public AudioClip KeepAlive = null;
		public List<float> DecodedFrames = new .() ~ delete _;
		public uint64 DecodedFrameCount = 0;
		public uint32 DecodedChannels = 0;
		public bool Registered = false;

		/// The mono variant, for a spatial play of a multi channel clip.
		public bool MonoRegistered = false;
		public List<float> MonoFrames = new .() ~ delete _;
		public uint64 MonoFrameCount = 0;
	}

	private struct DedupeEntry
	{
		public double Time;
		public VoiceHandle Handle;
	}

	/// One link of an effect chain, typed so teardown calls the right destroy.
	private struct BusEffectNode
	{
		public AudioBusEffectKind Kind;
		public mab_node* Node;
		/// Set only for a reverb, whose state lives here rather than in C.
		public ReverbNode Reverb;
	}

	/// A reverberator wrapped in a graph node: the maths is ours, the node is the backend's.
	private class ReverbNode
	{
		public mab_node* Node = null;
		public FreeverbState State = new .() ~ delete _;
	}

	/// A named custom bus, realised as one more group parented per the layout.
	private class CustomBusData
	{
		public String Name = new .() ~ delete _;
		/// The parent when there is no custom one.
		public AudioBus FixedParent = .Master;
		/// An index into the custom buses, or negative.
		public int32 ParentCustom = -1;
		public float Volume = 1.0f;
		public bool Muted = false;
		public mab_sound_group* Group = null;
		public List<BusEffectNode> Effects = new .() ~ delete _;
		/// Runs' and scenes' child groups under this bus, made lazily, the way the fixed buses
		/// have a child per run and per scene: a voice on this bus routes scene child, run child,
		/// this bus, so the run's and the scene's stop, pause, mute and gains reach it through
		/// the graph.
		public Dictionary<uint64, mab_sound_group*> RunChildren = new .() ~ delete _;
		public Dictionary<uint64, mab_sound_group*> SceneChildren = new .() ~ delete _;
	}

	/// A value eased from `From` to `To` over `Duration` seconds; inactive is settled.
	private struct VoiceRamp
	{
		public float From = 0.0f;
		public float To = 0.0f;
		public float Elapsed = 0.0f;
		public float Duration = 0.0f;
		public bool Active = false;

		public this() {}

		public void Start(float current, float target, float seconds) mut
		{
			From = current;
			To = target;
			Elapsed = 0.0f;
			Duration = seconds;
			Active = true;
		}

		/// Advances by `dt` and answers the value now, eased in and out so a speed up has no
		/// corner.
		public float Advance(float dt) mut
		{
			Elapsed += dt;
			if (Elapsed >= Duration)
			{
				Active = false;
				return To;
			}
			let t = Elapsed / Duration;
			return From + (To - From) * (t * t * (3.0f - 2.0f * t));
		}
	}

	/// One pool slot.
	private class VoiceSlot
	{
		public mab_sound* Sound = null;
		public uint32 Generation = 1;
		public VoiceState State = .Free;
		public uint8 Priority = 0;
		public bool Spatial = false;
		public bool Looping = false;

		/// Non empty means it routes through a named bus.
		public String CustomBusName = new .() ~ delete _;

		public Float3 Position = .(0, 0, 0);
		public float Volume = 1.0f;
		public float Pitch = 1.0f;
		/// SetVoiceVolume and SetVoicePitch over a duration.
		public VoiceRamp VolumeRamp = .();
		public VoiceRamp PitchRamp = .();
		public AudioBus Bus = .Effects;
		public uint64 SceneGroup = 0;
		/// The run this voice belongs to: its own, or its scene group's.
		public uint64 RunGroup = 0;
		/// BORROWED: the caller keeps the clip alive.
		public AudioClip Clip = null;

		/// A splitter at the END of the chain: its first output is the dry path to the group,
		/// its second feeds the scene's send reverb in parallel. Null when the voice was
		/// played with no send.
		public mab_node* SplitterNode = null;
		public float ReverbSend = 0.0f;

		/// The distance filter, between the sound and its group.
		public mab_node* LowpassNode = null;
		public float LowpassFloorHz = 0.0f;
		public float LowpassMinDistance = 1.0f;
		public float LowpassMaxDistance = 100.0f;
		public float LowpassCutoffHz = 0.0f;
	}

	/// A stolen voice's tail, fading out where nothing can address it.
	private class DyingVoice
	{
		public mab_sound* Sound = null;
		public mab_node* Lowpass = null;
		public mab_node* Splitter = null;
		public AudioClip Clip = null;
	}

	/// One scene's child groups, made lazily under each bus it actually uses.
	private class SceneGroupData
	{
		/// The run whose groups this scene nests under; nought is the buses.
		public uint64 RunGroup = 0;
		public mab_sound_group*[AudioBus.Count] Groups;
		public bool Paused = false;

		/// The zone reverb on the scene's own effects group.
		public ReverbNode Reverb = null;
		public float ReverbWet = 0.0f;

		/// The per voice send target: a WET ONLY reverberator fed by the voices' splitters,
		/// straight into the effects bus. A zone retunes its room; whether it is heard is the
		/// VOICE's own knob rather than the zone's.
		public ReverbNode SendReverb = null;
	}

	/// One running game's groups: a child under each bus the run uses (lazy), the run's own
	/// bus gains, its music slot, and its whole run pause, mute and volume. The scene groups of
	/// the run parent under these instead of the buses.
	private class RunGroupData
	{
		/// The run's own gain for one of a layout's custom buses, kept by name across a
		/// rebuild.
		public class NamedGain
		{
			public String Name = new .() ~ delete _;
			public float Gain = 1.0f;
			public bool Muted = false;
		}

		public mab_sound_group*[AudioBus.Count] Groups;
		public float[AudioBus.Count] BusGain = .(1.0f, 1.0f, 1.0f, 1.0f);
		public bool[AudioBus.Count] BusMuted;
		public float Volume = 1.0f;
		public bool Paused = false;
		public bool Muted = false;
		/// Ramps toward nought (muted) or one over cRunMuteFadeSeconds.
		public float MuteFactor = 1.0f;
		public VoiceHandle MusicVoice = .();
		public List<NamedGain> NamedGains = new .() ~ DeleteContainerAndItems!(_);

		public NamedGain FindNamed(StringView name)
		{
			for (let entry in NamedGains)
			{
				if (entry.Name == name)
					return entry;
			}
			return null;
		}

		public NamedGain EnsureNamed(StringView name)
		{
			if (let found = FindNamed(name))
				return found;
			let entry = new NamedGain();
			entry.Name.Set(name);
			NamedGains.Add(entry);
			return entry;
		}
	}

	/// How long muting or unmuting a run takes, so moving the audible Game tab cross fades
	/// rather than clicks.
	private const float cRunMuteFadeSeconds = 0.1f;

	private AudioEngineSettings mSettings;
	private bool mHeadless = false;
	private bool mInitialized = false;

	private mab_engine* mEngine = null;
	private mab_vfs* mVfs = null;
	private mab_vfs_callbacks mVfsCallbacks = .();

	private float mMasterVolume = 1.0f;

	private mab_sound_group*[AudioBus.Count] mBusGroups;
	private float[AudioBus.Count] mBusVolume = .(1.0f, 1.0f, 1.0f, 1.0f);
	private bool[AudioBus.Count] mBusMuted;
	private List<BusEffectNode>[AudioBus.Count] mBusEffects =
		.(new .(), new .(), new .(), new .()) ~ { for (var list in _) delete list; };

	private List<VoiceSlot> mVoices = new .() ~ DeleteContainerAndItems!(_);
	private uint32 mVoiceCount = 0;
	private uint32 mStreamVoiceCount = 0;

	private List<DyingVoice> mDyingVoices = new .() ~ DeleteContainerAndItems!(_);

	private Dictionary<uint64, SceneGroupData> mSceneGroups = new .() ~ delete _;
	private uint64 mNextSceneGroupId = 1;
	private Dictionary<uint64, RunGroupData> mRunGroups = new .() ~ delete _;
	private uint64 mNextRunGroupId = 1;

	/// Keyed by the clip's address. The engine holds no reference of its own; the entry's own
	/// keep alive does.
	private Dictionary<int, RegisteredClip> mRegisteredClips = new .() ~ delete _;
	private Dictionary<int, AudioClip> mStreamClips = new .() ~ delete _;
	private Dictionary<int, DedupeEntry> mRecentPlays = new .() ~ delete _;

	private List<CustomBusData> mCustomBuses = new .() ~ DeleteContainerAndItems!(_);

	private Float3 mListenerPosition = .(0, 0, 0);
	private VoiceHandle mMusicVoice = .();

	private double mTimeSeconds = 0.0;
	private bool mWarnedMonoDownmix = false;
	private bool mWarnedStreamStereoSpatial = false;
	private bool mWarnedUnknownBusName = false;

	/// The headless mixing scratch.
	private List<float> mPumpScratch = new .() ~ delete _;
	/// The clip name a play builds, reused rather than allocated per play.
	private String mNameScratch = new .() ~ delete _;

	public this(AudioEngineSettings settings = null)
	{
		// Its OWN copy, so the caller may keep, change or free what it passed.
		mSettings = new AudioEngineSettings();
		if (settings != null)
			mSettings.CopyFrom(settings);

		mHeadless = mSettings.Headless;
		if (!InitializeEngine(mHeadless) && !mHeadless)
		{
			Console.Error.WriteLine("Audio: no playback device available, so the engine runs headless: the voices advance silently and the handles stay valid");
			mHeadless = true;
			InitializeEngine(true);
		}

		if (!mInitialized)
		{
			Console.Error.WriteLine("Audio: the engine failed to initialise, so audio is off");
			return;
		}

		InitializeBusGroups();

		mVoiceCount = mSettings.VoiceCount;
		mStreamVoiceCount = mSettings.StreamVoiceCount;
		for (uint32 i = 0; i < (mVoiceCount + mStreamVoiceCount); i++)
			mVoices.Add(new VoiceSlot());
	}

	public ~this()
	{
		Shutdown();
		delete mSettings;
	}

	/// True when mixing without a device, whether that was asked for or fallen back to.
	public bool IsHeadless => mHeadless;

	// ==================== the frame ====================

	/// The caller's tick: reaps the voices whose fade or stream finished, advances the merge
	/// clock, and, headless, pumps the elapsed time through the mixer.
	public void Update(float deltaTime)
	{
		if (!mInitialized)
			return;

		var delta = deltaTime;
		if (delta < 0.0f)
			delta = 0.0f;
		// A hitch clamp: a long stall must not pump a second of audio in one go.
		if (delta > 0.25f)
			delta = 0.25f;

		mTimeSeconds += delta;

		// The runs' mute ramps: a muted run fades out, and an unmuted one back in, over a short
		// window instead of clicking, so moving the audible Game tab cross fades.
		let rampStep = delta / cRunMuteFadeSeconds;
		for (let entry in mRunGroups)
		{
			let run = entry.value;
			let target = run.Muted ? 0.0f : 1.0f;
			if (run.MuteFactor != target)
			{
				run.MuteFactor = (run.MuteFactor < target) ? Math.Min(run.MuteFactor + rampStep, target)
					: Math.Max(run.MuteFactor - rampStep, target);
				ApplyRunGains(entry.key, run);
			}
		}

		if (mHeadless && (delta > 0.0f))
			PumpHeadless(delta);

		// The stolen tails: reaped as their fades land.
		for (int i = mDyingVoices.Count - 1; i >= 0; i--)
		{
			if (mab_sound_is_playing(mDyingVoices[i].Sound) == 0)
				ReapDyingVoice(i);
		}

		for (var slot in mVoices)
		{
			if (slot.State == .Free)
				continue;

			UpdateVoiceLowpass(slot);

			// The eased volume and pitch: held while the voice is paused, so a pause keeps its
			// place.
			if ((slot.State == .Playing) || (slot.State == .Stopping))
			{
				if (slot.VolumeRamp.Active)
				{
					slot.Volume = slot.VolumeRamp.Advance(delta);
					mab_sound_set_volume(slot.Sound, slot.Volume * ((slot.Clip != null) ? slot.Clip.Gain : 1.0f));
				}
				if (slot.PitchRamp.Active)
				{
					slot.Pitch = slot.PitchRamp.Advance(delta);
					mab_sound_set_pitch(slot.Sound, slot.Pitch);
				}
			}

			// A voice that has finished, or whose fade to stop has landed, releases here on
			// the caller's own thread rather than from under the mixer.
			if (slot.State == .Stopping)
			{
				if (mab_sound_is_playing(slot.Sound) == 0)
					ReleaseSlot(slot);
				continue;
			}

			if ((slot.State == .Playing) && !slot.Looping
				&& (mab_sound_at_end(slot.Sound) != 0))
				ReleaseSlot(slot);
		}
	}

	/// Pumps the mixer by hand, in the time that has passed.
	private void PumpHeadless(float deltaTime)
	{
		let channels = mab_engine_get_channels(mEngine);
		let sampleRate = mab_engine_get_sample_rate(mEngine);
		if ((channels == 0) || (sampleRate == 0))
			return;

		const uint64 cChunkFrames = 1024;
		let needed = (int)(cChunkFrames * channels);
		if (mPumpScratch.Count < needed)
			mPumpScratch.Resize(needed);

		var remaining = (uint64)((double)deltaTime * sampleRate);
		while (remaining > 0)
		{
			let frames = Min(remaining, cChunkFrames);
			uint64 read = 0;
			if ((mab_engine_read_pcm_frames(mEngine, &mPumpScratch[0], frames, &read) != 0)
				|| (read == 0))
				break;
			remaining -= read;
		}
	}

	// ==================== voices ====================

	/// Starts a voice.
	///
	/// An invalid handle comes back when the clip has nothing to play or the pool is full of
	/// higher priority voices. A same clip play within the merge window answers the existing
	/// voice's handle rather than stacking a duplicate.
	public VoiceHandle Play(AudioClip clip, AudioPlayParams parameters = .())
	{
		if (!mInitialized || (clip == null))
			return .();
		if (!clip.Stream && clip.EncodedData.IsEmpty)
			return .();
		if (clip.Stream && (clip.StreamSource == null))
			return .();

		let clipKey = (int)(void*)Internal.UnsafeCastToPtr(clip);

		// The recent play merge: a repeat inside the window folds into the voice already
		// going. An opt out play neither merges NOR arms the window, or a persistent source
		// would swallow the legitimate one shots that follow it.
		if (parameters.AllowDedupe)
		{
			if (mRecentPlays.TryGetValue(clipKey, let recent))
			{
				if (((mTimeSeconds - recent.Time) < mSettings.DedupeWindowSeconds)
					&& (Resolve(recent.Handle) != null))
					return recent.Handle;
			}
		}

		let wantMonoDownmix = parameters.Spatial && (clip.Channels > 1) && !clip.Stream;
		if (parameters.Spatial && (clip.Channels > 1))
			WarnAboutSpatialMultichannel(clip);

		// The name the resource manager knows the payload by, which is the clip's own address
		// under a prefix saying which form of it this is.
		mNameScratch.Clear();
		var useMonoVariant = false;

		if (clip.Stream)
		{
			mStreamClips[clipKey] = clip;
			mNameScratch.AppendF("dstream:{:X}", clipKey);
		}
		else
		{
			let registered = EnsureRegistered(clip, wantMonoDownmix);
			if (registered == null)
				return .();
			useMonoVariant = wantMonoDownmix && registered.MonoRegistered;
			mNameScratch.AppendF("{}{:X}", useMonoVariant ? "dclipm:" : "dclip:", clipKey);
		}

		let slotIndex = AcquireSlot(clip.Stream, parameters.Priority);
		if (slotIndex < 0)
			return .();
		let slot = mVoices[slotIndex];

		// A scene group's voice belongs to the scene's run; a scene less voice to its own.
		var runGroup = parameters.RunGroup;
		if (parameters.SceneGroup != 0)
			runGroup = mSceneGroups.TryGetValue(parameters.SceneGroup, let sceneData) ? sceneData.RunGroup : 0;

		// A known custom bus overrides the fixed one. An unknown name warns once and falls
		// back: a typo in content must never silence a game.
		var group = GroupFor(parameters.SceneGroup, runGroup, parameters.Bus);
		var customBusIndex = -1;
		if (!parameters.BusName.IsEmpty)
		{
			customBusIndex = FindCustomBus(parameters.BusName);
			if ((customBusIndex >= 0) && (mCustomBuses[customBusIndex].Group != null))
			{
				group = CustomGroupFor(parameters.SceneGroup, runGroup, (int32)customBusIndex);
			}
			else
			{
				customBusIndex = -1;
				if (!mWarnedUnknownBusName)
				{
					mWarnedUnknownBusName = true;
					Console.Error.WriteLine(scope $"Audio: a play addressed the unknown custom bus '{parameters.BusName}', so it used the fixed bus instead; further such warnings are suppressed");
				}
			}
		}

		let flags = clip.Stream ? MAB_SOUND_FLAG_STREAM : 0;
		slot.Sound = mab_sound_create_from_file(mEngine, mNameScratch, flags, group);
		if (slot.Sound == null)
		{
			slot.Generation++;
			Console.Error.WriteLine("Audio: a voice failed to start for a clip");
			return .();
		}

		slot.State = parameters.StartPaused ? .Paused : .Playing;
		slot.Priority = parameters.Priority;
		slot.Spatial = parameters.Spatial;
		slot.Position = parameters.Position;
		slot.Volume = parameters.Volume;
		slot.Pitch = parameters.Pitch;
		slot.VolumeRamp = .();
		slot.PitchRamp = .();
		slot.Bus = parameters.Bus;
		slot.CustomBusName.Clear();
		if (customBusIndex >= 0)
			slot.CustomBusName.Set(parameters.BusName);
		slot.SceneGroup = parameters.SceneGroup;
		slot.RunGroup = runGroup;
		slot.Clip = clip;
		slot.Looping = parameters.Loop || clip.Loop;

		SpliceDistanceLowpass(slot, parameters, group);
		SpliceReverbSend(slot, parameters, group);
		ApplyVoiceParams(slot, parameters, clip);

		// A paused scene's or run's group is halted, so a voice started under it stays frozen
		// until it resumes, on a custom bus as on a fixed one.
		if (!parameters.StartPaused)
			mab_sound_start(slot.Sound);

		let handle = VoiceHandle((uint32)slotIndex, slot.Generation);
		if (parameters.AllowDedupe)
			mRecentPlays[clipKey] = .() { Time = mTimeSeconds, Handle = handle };
		return handle;
	}

	/// A spatial play of a multi channel clip is a mistake worth naming once.
	///
	/// Three dimensional imaging wants ONE channel: a stereo source placed at a point is two
	/// sources at that point, which images as nothing in particular. An in memory clip is
	/// downmixed for real; a streamed one plays as it is, since decoding it twice to fix an
	/// import is worse than the imaging.
	private void WarnAboutSpatialMultichannel(AudioClip clip)
	{
		if (clip.Stream)
		{
			if (!mWarnedStreamStereoSpatial)
			{
				mWarnedStreamStereoSpatial = true;
				Console.Error.WriteLine("Audio: a STREAMED multi channel clip is being spatialised; reimport it forced to mono for correct imaging; further such warnings are suppressed");
			}
		}
		else if (!mWarnedMonoDownmix)
		{
			mWarnedMonoDownmix = true;
			Console.Error.WriteLine("Audio: a multi channel clip is being spatialised, so it is downmixed to mono at play; reimport it forced to mono to avoid the cost; further such warnings are suppressed");
		}
	}

	/// Splices the distance filter between the sound and its group. It is wholly per voice; a
	/// floor of nought puts no node in the chain at all.
	private void SpliceDistanceLowpass(VoiceSlot slot, AudioPlayParams parameters,
		mab_sound_group* group)
	{
		if (!parameters.Spatial || (parameters.DistanceLowpassHz <= 0.0f) || (group == null))
			return;

		let node = mab_lpf_node_create(mEngine, OpenCutoffHz, cLowpassOrder);
		if (node == null)
			return;

		let groupNode = mab_sound_group_get_node(group);
		if ((mab_node_attach_output_bus(node, 0, groupNode, 0) == 0)
			&& (mab_node_attach_output_bus(mab_sound_get_node(slot.Sound), 0, node, 0) == 0))
		{
			slot.LowpassNode = node;
			slot.LowpassFloorHz = parameters.DistanceLowpassHz;
			slot.LowpassMinDistance = parameters.MinDistance;
			slot.LowpassMaxDistance = parameters.MaxDistance;
			// Nought forces the first mapping to land rather than being read as unchanged.
			slot.LowpassCutoffHz = 0.0f;
		}
		else
		{
			mab_lpf_node_destroy(node);
		}
	}

	/// Splices the send: a splitter at the end of the chain whose first output is the dry
	/// path and whose second feeds the scene's send reverb in PARALLEL.
	private void SpliceReverbSend(VoiceSlot slot, AudioPlayParams parameters,
		mab_sound_group* group)
	{
		if ((parameters.ReverbSend <= 0.0f) || (parameters.SceneGroup == 0) || (group == null))
			return;

		let sendReverb = EnsureSceneSendReverb(parameters.SceneGroup);
		if (sendReverb == null)
			return;

		let send = Clamp(parameters.ReverbSend, 0.0f, 1.0f);
		let splitter = mab_splitter_node_create(mEngine);
		if (splitter == null)
			return;

		// The chain's current end feeds the splitter, and the splitter feeds both paths.
		let tail = (slot.LowpassNode != null) ? slot.LowpassNode : mab_sound_get_node(slot.Sound);
		let groupNode = mab_sound_group_get_node(group);

		if ((mab_node_attach_output_bus(splitter, 0, groupNode, 0) == 0)
			&& (mab_node_attach_output_bus(splitter, 1, sendReverb.Node, 0) == 0)
			&& (mab_node_attach_output_bus(tail, 0, splitter, 0) == 0))
		{
			mab_node_set_output_bus_volume(splitter, 1, send);
			slot.SplitterNode = splitter;
			slot.ReverbSend = send;
		}
		else
		{
			mab_splitter_node_destroy(splitter);
		}
	}

	private void ApplyVoiceParams(VoiceSlot slot, AudioPlayParams parameters, AudioClip clip)
	{
		mab_sound_set_volume(slot.Sound, parameters.Volume * clip.Gain);
		mab_sound_set_pitch(slot.Sound, parameters.Pitch);
		mab_sound_set_looping(slot.Sound, slot.Looping ? 1 : 0);

		if (slot.Looping && ((clip.LoopStartFrame > 0) || (clip.LoopEndFrame > 0)))
		{
			let loopEnd = (clip.LoopEndFrame > 0) ? clip.LoopEndFrame : clip.FrameCount;
			mab_sound_set_loop_point_frames(slot.Sound, clip.LoopStartFrame, loopEnd);
		}

		if (parameters.Spatial)
		{
			mab_sound_set_spatialization_enabled(slot.Sound, 1);
			mab_sound_set_positioning_absolute(slot.Sound);
			mab_sound_set_position(slot.Sound, parameters.Position.X, parameters.Position.Y,
				parameters.Position.Z);
			mab_sound_set_velocity(slot.Sound, parameters.Velocity.X, parameters.Velocity.Y,
				parameters.Velocity.Z);
			mab_sound_set_attenuation_model(slot.Sound, (uint32)parameters.AttenuationModel);
			mab_sound_set_min_distance(slot.Sound, parameters.MinDistance);
			mab_sound_set_max_distance(slot.Sound, parameters.MaxDistance);
			mab_sound_set_rolloff(slot.Sound, parameters.Rolloff);
			mab_sound_set_doppler_factor(slot.Sound, parameters.DopplerFactor);
			if ((parameters.ConeInnerAngleDegrees < 360.0f)
				|| (parameters.ConeOuterAngleDegrees < 360.0f))
				mab_sound_set_cone(slot.Sound,
					parameters.ConeInnerAngleDegrees * cDegreesToRadians,
					parameters.ConeOuterAngleDegrees * cDegreesToRadians,
					parameters.ConeOuterGain);
		}
		else
		{
			mab_sound_set_spatialization_enabled(slot.Sound, 0);
			mab_sound_set_pan(slot.Sound, parameters.Pan);
		}
	}

	/// Fades out over the stop window and then reaps. Safe on a stale handle.
	public void Stop(VoiceHandle handle) => Stop(handle, 0.0f);

	/// The same, fading out over `fadeSeconds`, at least the click free stop window.
	public void Stop(VoiceHandle handle, float fadeSeconds)
	{
		let slot = Resolve(handle);
		if (slot == null)
			return;

		// A paused voice is silent already, so there is nothing to fade out of.
		if (slot.State == .Paused)
		{
			ReleaseSlot(slot);
			return;
		}

		if (slot.State != .Stopping)
		{
			let fade = Math.Max((uint64)(Math.Max(fadeSeconds, 0.0f) * 1000.0f + 0.5f), FadeMilliseconds);
			mab_sound_stop_with_fade_ms(slot.Sound, fade);
			slot.State = .Stopping;
		}
	}

	public void StopAll()
	{
		for (int i < mVoices.Count)
		{
			if (mVoices[i].State != .Free)
				Stop(.((uint32)i, mVoices[i].Generation));
		}
	}

	/// Pausing fades out but KEEPS the cursor; resuming fades back in.
	public void SetPaused(VoiceHandle handle, bool paused)
	{
		let slot = Resolve(handle);
		if ((slot == null) || (slot.State == .Stopping))
			return;

		if (paused)
		{
			if (slot.State == .Paused)
				return;
			mab_sound_stop_with_fade_ms(slot.Sound, FadeMilliseconds);
			slot.State = .Paused;
			return;
		}

		if (slot.State != .Paused)
			return;

		// The scheduled stop is cleared first, or starting again would run straight back into
		// the fade that was already in flight.
		mab_sound_reset_stop_time_and_fade(slot.Sound);
		mab_sound_set_fade_in_ms(slot.Sound, 0.0f, 1.0f, FadeMilliseconds);
		mab_sound_start(slot.Sound);
		slot.State = .Playing;
	}

	public bool IsPlaying(VoiceHandle handle)
	{
		let slot = Resolve(handle);
		return (slot != null) && (slot.State == .Playing);
	}

	public bool IsValidHandle(VoiceHandle handle) => Resolve(handle) != null;

	public bool GetVoiceStatus(VoiceHandle handle, out VoiceStatus outStatus)
	{
		outStatus = .();
		let slot = Resolve(handle);
		if (slot == null)
			return false;

		outStatus.Active = true;
		outStatus.Playing = (slot.State == .Playing);
		outStatus.Paused = (slot.State == .Paused);
		outStatus.Stopping = (slot.State == .Stopping);
		outStatus.Spatial = slot.Spatial;
		outStatus.Volume = slot.Volume;
		outStatus.Pitch = slot.Pitch;
		outStatus.Bus = slot.Bus;
		outStatus.BusName = slot.CustomBusName;
		outStatus.Priority = slot.Priority;
		outStatus.Position = slot.Position;
		outStatus.LowpassCutoffHz = slot.LowpassCutoffHz;
		outStatus.ReverbSend = slot.ReverbSend;

		float cursor = 0.0f;
		if (mab_sound_get_cursor_seconds(slot.Sound, &cursor) == 0)
			outStatus.CursorSeconds = cursor;

		return true;
	}

	/// The volume at once, or eased there over `seconds` (Update advances it; a later set
	/// retargets from where it is).
	public void SetVoiceVolume(VoiceHandle handle, float volume, float seconds = 0.0f)
	{
		let slot = Resolve(handle);
		if (slot == null)
			return;
		let target = Math.Max(volume, 0.0f);
		if (seconds > 0.0f)
		{
			slot.VolumeRamp.Start(slot.Volume, target, seconds);
			return;
		}
		slot.VolumeRamp = .();
		slot.Volume = target;
		mab_sound_set_volume(slot.Sound, target * ((slot.Clip != null) ? slot.Clip.Gain : 1.0f));
	}

	/// The pitch, the playback rate (1.2 plays twenty percent faster and higher), at once or
	/// eased there over `seconds`.
	public void SetVoicePitch(VoiceHandle handle, float pitch, float seconds = 0.0f)
	{
		let slot = Resolve(handle);
		if (slot == null)
			return;
		let target = Math.Max(pitch, 0.01f); // a rate of nought would stall the voice for good
		if (seconds > 0.0f)
		{
			slot.PitchRamp.Start(slot.Pitch, target, seconds);
			return;
		}
		slot.PitchRamp = .();
		slot.Pitch = target;
		mab_sound_set_pitch(slot.Sound, target);
	}

	public void SetVoicePan(VoiceHandle handle, float pan)
	{
		let slot = Resolve(handle);
		if (slot == null)
			return;
		mab_sound_set_pan(slot.Sound, pan);
	}

	public void SetVoiceLooping(VoiceHandle handle, bool loop)
	{
		let slot = Resolve(handle);
		if (slot == null)
			return;
		slot.Looping = loop;
		mab_sound_set_looping(slot.Sound, loop ? 1 : 0);
	}

	/// The per frame spatial sync. The velocity is what shifts the pitch of something moving.
	public void SetVoicePosition(VoiceHandle handle, Float3 position, Float3 velocity)
	{
		let slot = Resolve(handle);
		if (slot == null)
			return;
		slot.Position = position;
		mab_sound_set_position(slot.Sound, position.X, position.Y, position.Z);
		mab_sound_set_velocity(slot.Sound, velocity.X, velocity.Y, velocity.Z);
	}

	/// Scales the send live. A no op on a voice played without one: the splitter only splices
	/// at the play, the graph not being rewireable under a running voice for free.
	public void SetVoiceReverbSend(VoiceHandle handle, float send)
	{
		let slot = Resolve(handle);
		if ((slot == null) || (slot.SplitterNode == null))
			return;
		slot.ReverbSend = Clamp(send, 0.0f, 1.0f);
		mab_node_set_output_bus_volume(slot.SplitterNode, 1, slot.ReverbSend);
	}

	/// The ADDRESSABLE voices: the slots a live generation owns. A stolen voice leaves this
	/// count the instant it is stolen, its handle dying then, even though its tail is still
	/// mixing for a few milliseconds.
	public int ActiveVoiceCount
	{
		get
		{
			var count = 0;
			for (let slot in mVoices)
			{
				if (slot.State != .Free)
					count++;
			}
			return count;
		}
	}

	/// The stolen tails still fading. They are unaddressable and bounded.
	public int DyingVoiceCount => mDyingVoices.Count;

	// ==================== the pool ====================

	private VoiceSlot Resolve(VoiceHandle handle)
	{
		if (!handle.IsValid || (handle.Slot >= (uint32)mVoices.Count))
			return null;

		let slot = mVoices[(int)handle.Slot];
		if ((slot.State == .Free) || (slot.Generation != handle.Generation))
			return null;
		return slot;
	}

	/// The squared distance to the listener, which is all an ordering needs.
	private float DistanceToListener(VoiceSlot slot)
	{
		if (!slot.Spatial)
			return 0.0f;

		let delta = slot.Position - mListenerPosition;
		return Dot(delta, delta);
	}

	/// A free slot, else the lowest priority strictly below the newcomer, else the FARTHEST
	/// voice of equal priority. Negative when nothing may be taken.
	///
	/// Distance breaks a tie because the farthest of several equally important sounds is the
	/// one whose loss is least audible.
	private int AcquireSlot(bool streamPool, uint8 priority)
	{
		let first = streamPool ? (int)mVoiceCount : 0;
		let last = streamPool ? (int)(mVoiceCount + mStreamVoiceCount) : (int)mVoiceCount;

		for (int i = first; i < last; i++)
		{
			if (mVoices[i].State == .Free)
				return i;
		}

		var victim = -1;
		var victimPriority = priority;
		for (int i = first; i < last; i++)
		{
			if ((mVoices[i].Priority < victimPriority)
				|| ((victim >= 0) && (mVoices[i].Priority == victimPriority)
					&& (DistanceToListener(mVoices[i]) > DistanceToListener(mVoices[victim]))))
			{
				victim = i;
				victimPriority = mVoices[i].Priority;
			}
		}

		if (victim < 0)
		{
			// Nothing below it, so the farthest of EQUAL priority.
			for (int i = first; i < last; i++)
			{
				if (mVoices[i].Priority != priority)
					continue;
				if ((victim < 0)
					|| (DistanceToListener(mVoices[i]) > DistanceToListener(mVoices[victim])))
					victim = i;
			}
		}

		if (victim >= 0)
		{
			StealSlot(mVoices[victim]);
			return victim;
		}
		return -1;
	}

	/// The victim's handle dies NOW and its slot is reused at once, but its sound fades on the
	/// dying list rather than clicking off. A silent victim releases immediately: there is
	/// nothing audible to protect.
	private void StealSlot(VoiceSlot slot)
	{
		if ((slot.Sound == null) || (slot.State == .Paused)
			|| (mSettings.DyingVoiceCapacity == 0))
		{
			ReleaseSlot(slot);
			return;
		}

		while (mDyingVoices.Count >= (int)mSettings.DyingVoiceCapacity)
			ReapDyingVoice(0);

		mab_sound_stop_with_fade_ms(slot.Sound, StealFadeMilliseconds);

		let dying = new DyingVoice();
		dying.Sound = slot.Sound;
		dying.Lowpass = slot.LowpassNode;
		dying.Splitter = slot.SplitterNode;
		dying.Clip = slot.Clip;
		mDyingVoices.Add(dying);

		// The chain HANDS OVER whole: the slot keeps none of it.
		slot.Sound = null;
		slot.LowpassNode = null;
		slot.SplitterNode = null;
		ClearSlot(slot);
	}

	private void ReapDyingVoice(int index)
	{
		let dying = mDyingVoices[index];
		if (dying.Sound != null)
			mab_sound_destroy(dying.Sound);
		if (dying.Lowpass != null)
			mab_lpf_node_destroy(dying.Lowpass);
		if (dying.Splitter != null)
			mab_splitter_node_destroy(dying.Splitter);

		delete dying;
		mDyingVoices.RemoveAt(index);
	}

	private void ReleaseSlot(VoiceSlot slot)
	{
		if (slot.Sound != null)
		{
			mab_sound_destroy(slot.Sound);
			slot.Sound = null;
		}
		if (slot.LowpassNode != null)
		{
			mab_lpf_node_destroy(slot.LowpassNode);
			slot.LowpassNode = null;
		}
		if (slot.SplitterNode != null)
		{
			mab_splitter_node_destroy(slot.SplitterNode);
			slot.SplitterNode = null;
		}
		ClearSlot(slot);
	}

	/// Frees the slot and BUMPS ITS GENERATION, which is what makes every handle to what was
	/// there answer no from now on.
	private void ClearSlot(VoiceSlot slot)
	{
		slot.LowpassFloorHz = 0.0f;
		slot.LowpassCutoffHz = 0.0f;
		slot.ReverbSend = 0.0f;
		slot.State = .Free;
		slot.Clip = null;
		slot.SceneGroup = 0;
		slot.RunGroup = 0;
		slot.CustomBusName.Clear();
		slot.Generation++;
	}

	private uint64 FadeMilliseconds =>
		(uint64)((mSettings.StopFadeSeconds > 0.0f ? mSettings.StopFadeSeconds : 0.0f)
			* 1000.0f + 0.5f);

	private uint64 StealFadeMilliseconds =>
		(uint64)((mSettings.StealFadeSeconds > 0.0f ? mSettings.StealFadeSeconds : 0.0f)
			* 1000.0f + 0.5f);

	/// Glides the cutoff: fully open within the near distance, falling to the voice's floor by
	/// the far one.
	///
	/// It is only reconfigured on an AUDIBLE change, since reconfiguring a filter is not free
	/// and a voice moving a millimetre does not need one.
	private void UpdateVoiceLowpass(VoiceSlot slot)
	{
		if (slot.LowpassNode == null)
			return;

		let delta = slot.Position - mListenerPosition;
		let distance = Sqrt(Dot(delta, delta));
		let range = Max(slot.LowpassMaxDistance - slot.LowpassMinDistance, 0.001f);
		let t = Clamp((distance - slot.LowpassMinDistance) / range, 0.0f, 1.0f);
		let open = OpenCutoffHz;
		let cutoff = open + (slot.LowpassFloorHz - open) * t;

		if ((slot.LowpassCutoffHz > 0.0f)
			&& (Abs(cutoff - slot.LowpassCutoffHz) < (slot.LowpassCutoffHz * 0.01f)))
			return;

		if (mab_lpf_node_set_cutoff(slot.LowpassNode, mEngine, cutoff, cLowpassOrder) == 0)
			slot.LowpassCutoffHz = cutoff;
	}

	// ==================== registration ====================

	/// Registers a clip's payload with the resource manager, decoding it once unless it was
	/// asked to stay compressed.
	///
	/// The manager holds it BY REFERENCE, so the entry owns the frames and keeps the clip
	/// alive for as long as anything can play it.
	private RegisteredClip EnsureRegistered(AudioClip clip, bool wantMono)
	{
		let key = (int)(void*)Internal.UnsafeCastToPtr(clip);

		RegisteredClip entry;
		if (!mRegisteredClips.TryGetValue(key, out entry))
		{
			entry = new RegisteredClip();
			entry.KeepAlive = clip;
			mRegisteredClips[key] = entry;
		}

		if (!entry.Registered)
		{
			let name = scope String();
			name.AppendF("dclip:{:X}", key);

			var result = -1;
			if (clip.KeepCompressed)
			{
				// Compressed in memory: decoded as it plays rather than up front.
				result = mab_register_encoded_data(mEngine, name, clip.EncodedData.Ptr,
					(uint)clip.EncodedData.Count);
			}
			else if (AudioCodec.DecodeToFloat(clip.EncodedBytes, 0, entry.DecodedFrames,
				let channels, let frames))
			{
				entry.DecodedChannels = channels;
				entry.DecodedFrameCount = frames;
				result = mab_register_decoded_data(mEngine, name, entry.DecodedFrames.Ptr,
					frames, (uint32)mab_format.F32, channels, clip.SampleRate);
			}

			entry.Registered = (result == 0);
			if (!entry.Registered)
			{
				Console.Error.WriteLine("Audio: a clip failed to decode or register, so it is not playable");
				return null;
			}
		}

		if (wantMono && !entry.MonoRegistered)
		{
			let name = scope String();
			name.AppendF("dclipm:{:X}", key);

			if (AudioCodec.DecodeToFloat(clip.EncodedBytes, 1, entry.MonoFrames, let channels,
				let frames))
			{
				entry.MonoFrameCount = frames;
				entry.MonoRegistered = mab_register_decoded_data(mEngine, name,
					entry.MonoFrames.Ptr, frames, (uint32)mab_format.F32, 1, clip.SampleRate) == 0;
			}
		}

		return entry;
	}

	// ==================== the graph's shape ====================

	/// Where the filter sits with no muffling at all: just under Nyquist, with a ceiling at
	/// twenty kilohertz on the high rates.
	private float OpenCutoffHz =>
		Min(20000.0f, (float)mab_engine_get_sample_rate(mEngine) * 0.45f);

	/// The node a bus's output feeds when it carries NO effects: Master for the leaves, and
	/// the graph's endpoint for Master itself.
	private mab_node* BusParentNode(int bus)
	{
		if (bus == (int)AudioBus.Master)
			return mab_engine_get_endpoint(mEngine);
		let master = mBusGroups[(int)AudioBus.Master];
		return (master != null) ? mab_sound_group_get_node(master) : null;
	}

	/// The voice chain's LAST node, which is what attaches to the group: the splitter's dry
	/// output if there is one, else the distance filter, else the sound itself.
	private static mab_node* VoiceOutputNode(VoiceSlot slot)
	{
		if (slot.SplitterNode != null)
			return slot.SplitterNode;
		if (slot.LowpassNode != null)
			return slot.LowpassNode;
		return mab_sound_get_node(slot.Sound);
	}

	private void InitializeBusGroups()
	{
		// Master first, since the leaves parent to it.
		for (int bus = 0; bus < AudioBus.Count; bus++)
		{
			let parent = (bus == (int)AudioBus.Master)
				? null
				: mab_sound_group_get_node(mBusGroups[(int)AudioBus.Master]);
			mBusGroups[bus] = mab_sound_group_create(mEngine, 0, parent);
		}
	}

	private bool InitializeEngine(bool withoutDevice)
	{
		mVfsCallbacks.OnOpen = => VfsOpen;
		mVfsCallbacks.OnClose = => VfsClose;
		mVfsCallbacks.OnRead = => VfsRead;
		mVfsCallbacks.OnSeek = => VfsSeek;
		mVfsCallbacks.OnTell = => VfsTell;
		mVfsCallbacks.OnSize = => VfsSize;
		if (mVfs == null)
			mVfs = mab_vfs_create(&mVfsCallbacks, Internal.UnsafeCastToPtr(this));

		let listeners = Clamp(mSettings.ListenerCount, (uint32)1, (uint32)4);
		let sampleRate = (mSettings.SampleRate != 0) ? mSettings.SampleRate : 48000;

		mEngine = withoutDevice
			? mab_engine_create(mVfs, listeners, 1, 2, sampleRate)
			: mab_engine_create(mVfs, listeners, 0, 0, 0);

		mInitialized = (mEngine != null);
		// A master volume set before the engine came up still has to land.
		if (mInitialized && (mMasterVolume != 1.0f))
			mab_engine_set_volume(mEngine, mMasterVolume);
		return mInitialized;
	}

	/// Tears the graph down from the leaves up, so nothing is destroyed while something else
	/// still feeds it.
	private void Shutdown()
	{
		if (mInitialized)
		{
			while (!mDyingVoices.IsEmpty)
				ReapDyingVoice(mDyingVoices.Count - 1);

			for (var slot in mVoices)
				ReleaseSlot(slot);

			let groupIds = scope List<uint64>();
			for (let entry in mSceneGroups)
				groupIds.Add(entry.key);
			for (let id in groupIds)
				DestroySceneGroupData(id);

			let runIds = scope List<uint64>();
			for (let entry in mRunGroups)
				runIds.Add(entry.key);
			for (let id in runIds)
				DestroyRunGroupData(id);

			for (let bus in mCustomBuses)
				DestroyCustomBus(bus);
			mCustomBuses.Clear();

			for (int bus = 0; bus < AudioBus.Count; bus++)
				ClearBusEffects(bus);
			for (int bus = AudioBus.Count - 1; bus >= 0; bus--)
			{
				if (mBusGroups[bus] != null)
				{
					mab_sound_group_destroy(mBusGroups[bus]);
					mBusGroups[bus] = null;
				}
			}

			mab_engine_destroy(mEngine);
			mEngine = null;
			mInitialized = false;
		}

		if (mVfs != null)
		{
			mab_vfs_destroy(mVfs);
			mVfs = null;
		}

		// The payloads outlive the engine by exactly this much: they are freed once nothing
		// can be reading them.
		for (let entry in mRegisteredClips)
			delete entry.value;
		mRegisteredClips.Clear();
	}

	// ==================== the reverb node ====================

	/// One block of the reverb, ON THE AUDIO THREAD.
	///
	/// Anything but stereo passes straight through: Freeverb's topology IS a stereo one, and
	/// a wrong-width guess is worse than no reverb.
	private static void ReverbProcess(void* user, float* framesIn, float* framesOut,
		uint32 frameCount, uint32 channels)
	{
		let reverb = (ReverbNode)Internal.UnsafeCastToObject(user);
		if ((channels == 2) && reverb.State.IsInitialized)
			reverb.State.ProcessStereo(framesIn, framesOut, frameCount);
		else
			Internal.MemCpy(framesOut, framesIn, (int)frameCount * (int)channels * sizeof(float));
	}

	private ReverbNode CreateReverbNode(AudioReverbParams parameters)
	{
		let reverb = new ReverbNode();
		reverb.State.Initialize(mab_engine_get_sample_rate(mEngine));
		reverb.State.SetParams(parameters);
		reverb.Node = mab_custom_node_create(mEngine, => ReverbProcess,
			Internal.UnsafeCastToPtr(reverb));
		if (reverb.Node == null)
		{
			delete reverb;
			return null;
		}
		return reverb;
	}

	private void DestroyReverbNode(ReverbNode reverb)
	{
		if (reverb == null)
			return;
		if (reverb.Node != null)
			mab_custom_node_destroy(reverb.Node);
		delete reverb;
	}

	// ==================== effect chains ====================

	/// Frees every node in the chain. The caller re-attaches the source FIRST, so nothing is
	/// destroyed while the graph still points at it.
	private void ClearEffectChain(List<BusEffectNode> chain)
	{
		for (let effect in chain)
		{
			switch (effect.Kind)
			{
			case .Lowpass: mab_lpf_node_destroy(effect.Node);
			case .Highpass: mab_hpf_node_destroy(effect.Node);
			case .Delay: mab_delay_node_destroy(effect.Node);
			case .Reverb: DestroyReverbNode(effect.Reverb);
			case .None:
			}
		}
		chain.Clear();
	}

	private void ClearBusEffects(int bus)
	{
		if (mBusGroups[bus] != null)
			mab_node_attach_output_bus(mab_sound_group_get_node(mBusGroups[bus]), 0,
				BusParentNode(bus), 0);
		ClearEffectChain(mBusEffects[bus]);
	}

	/// Rebuilds one bus's chain: group, then each effect in order, then the parent.
	private void BuildBusEffects(int bus, List<AudioBusEffectDesc> effects)
	{
		ClearBusEffects(bus);
		if (mBusGroups[bus] == null)
			return;
		BuildEffectChain(mab_sound_group_get_node(mBusGroups[bus]), mBusEffects[bus],
			BusParentNode(bus), effects);
	}

	/// The generic splice, shared by the fixed buses and the named ones: source, then each
	/// effect in order, then the parent. The chain must be empty on entry.
	///
	/// An effect that fails to build is SKIPPED rather than breaking the chain, so a bad
	/// parameter costs its own effect and nothing downstream of it.
	private void BuildEffectChain(mab_node* source, List<BusEffectNode> chain, mab_node* parent,
		List<AudioBusEffectDesc> effects)
	{
		let sampleRate = mab_engine_get_sample_rate(mEngine);

		var upstream = source;
		for (let desc in effects)
		{
			var effect = BusEffectNode();
			effect.Kind = desc.Kind;

			switch (desc.Kind)
			{
			case .Lowpass:
				effect.Node = mab_lpf_node_create(mEngine, Max(desc.FrequencyHz, 10.0f),
					cLowpassOrder);
			case .Highpass:
				effect.Node = mab_hpf_node_create(mEngine, Max(desc.FrequencyHz, 10.0f),
					cLowpassOrder);
			case .Delay:
				let delayFrames = (uint32)(Max(desc.DelaySeconds, 0.001f) * (float)sampleRate);
				effect.Node = mab_delay_node_create(mEngine, delayFrames,
					Clamp(desc.DelayDecay, 0.0f, 0.99f));
			case .Reverb:
				var parameters = AudioReverbParams();
				parameters.RoomSize = desc.RoomSize;
				parameters.Damping = desc.Damping;
				parameters.Wet = desc.WetLevel;
				effect.Reverb = CreateReverbNode(parameters);
				if (effect.Reverb != null)
					effect.Node = effect.Reverb.Node;
			case .None:
				continue;
			}

			if (effect.Node == null)
				continue;

			mab_node_attach_output_bus(upstream, 0, effect.Node, 0);
			upstream = effect.Node;
			chain.Add(effect);
		}

		mab_node_attach_output_bus(upstream, 0, parent, 0);
	}

	// ==================== named custom buses ====================

	private int FindCustomBus(StringView name)
	{
		for (int i = 0; i < mCustomBuses.Count; i++)
		{
			if (mCustomBuses[i].Name == name)
				return i;
		}
		return -1;
	}

	private mab_node* CustomBusParentNode(CustomBusData bus)
	{
		if ((bus.ParentCustom >= 0) && (bus.ParentCustom < (int32)mCustomBuses.Count)
			&& (mCustomBuses[bus.ParentCustom].Group != null))
			return mab_sound_group_get_node(mCustomBuses[bus.ParentCustom].Group);

		let fixedIndex = (int)bus.FixedParent;
		return (mBusGroups[fixedIndex] != null)
			? mab_sound_group_get_node(mBusGroups[fixedIndex])
			: BusParentNode((int)AudioBus.Master);
	}

	/// A removed bus hands its live voices back to their fixed fallback: a voice SURVIVES a
	/// layout rebuild, and only its routing changes.
	private void DetachVoicesFromCustomBus(CustomBusData bus)
	{
		for (var slot in mVoices)
		{
			if ((slot.State == .Free) || (slot.CustomBusName != bus.Name))
				continue;

			let fallback = GroupFor(slot.SceneGroup, slot.RunGroup, slot.Bus);
			if (fallback != null)
				mab_node_attach_output_bus(VoiceOutputNode(slot), 0,
					mab_sound_group_get_node(fallback), 0);
			slot.CustomBusName.Clear();
		}
	}

	private void DestroyCustomBus(CustomBusData bus)
	{
		DetachVoicesFromCustomBus(bus);
		// The scenes' children first, which may hang under the runs', then the runs'.
		for (let child in bus.SceneChildren.Values)
			mab_sound_group_destroy(child);
		bus.SceneChildren.Clear();
		for (let child in bus.RunChildren.Values)
			mab_sound_group_destroy(child);
		bus.RunChildren.Clear();
		ClearEffectChain(bus.Effects);
		if (bus.Group != null)
			mab_sound_group_destroy(bus.Group);
		delete bus;
	}

	/// Reconciles the live set with the layout BY NAME: a kept bus updates in place and its
	/// voices keep playing, a removed one falls its voices back, a new one splices in.
	///
	/// A parent cycle is defused to Master. The cooker rejects one, so this is the runtime's
	/// backstop rather than its first line.
	private void RebuildCustomBuses(List<AudioNamedBus> desired)
	{
		// The filter: named, and the first occurrence of a name wins.
		let wanted = scope List<AudioNamedBus>();
		for (let named in desired)
		{
			if (named.Name.IsEmpty)
				continue;

			var duplicate = false;
			for (let seen in wanted)
			{
				if (seen.Name == named.Name)
				{
					duplicate = true;
					break;
				}
			}
			if (duplicate)
			{
				Console.Error.WriteLine(scope $"Audio: the bus layout names the custom bus '{named.Name}' twice, so the repeat is ignored");
				continue;
			}
			if (AudioBusNames.TryParse(named.Name, let alias))
			{
				Console.Error.WriteLine(scope $"Audio: the custom bus '{named.Name}' shadows a fixed bus, so it is ignored");
				continue;
			}
			wanted.Add(named);
		}

		// The buses the layout no longer names.
		for (int i = mCustomBuses.Count - 1; i >= 0; i--)
		{
			var keep = false;
			for (let named in wanted)
			{
				if (named.Name == mCustomBuses[i].Name)
				{
					keep = true;
					break;
				}
			}
			if (!keep)
			{
				DestroyCustomBus(mCustomBuses[i]);
				mCustomBuses.RemoveAt(i);
			}
		}

		// The missing groups, parented to Master and re-parented below.
		for (let named in wanted)
		{
			if (FindCustomBus(named.Name) >= 0)
				continue;

			let bus = new CustomBusData();
			bus.Name.Set(named.Name);
			bus.Group = mab_sound_group_create(mEngine, 0,
				mab_sound_group_get_node(mBusGroups[(int)AudioBus.Master]));
			mCustomBuses.Add(bus);
		}

		// The parents: a fixed bus name, another custom bus's name, or nothing, which is
		// Master.
		for (let named in wanted)
		{
			let index = FindCustomBus(named.Name);
			if (index < 0)
				continue;

			let bus = mCustomBuses[index];
			bus.FixedParent = .Master;
			bus.ParentCustom = -1;
			if (named.Parent.IsEmpty)
				continue;

			if (AudioBusNames.TryParse(named.Parent, let fixedBus))
			{
				bus.FixedParent = fixedBus;
			}
			else
			{
				let parent = FindCustomBus(named.Parent);
				if ((parent >= 0) && (parent != index))
					bus.ParentCustom = (int32)parent;
				else
					Console.Error.WriteLine(scope $"Audio: the custom bus '{named.Name}' names the unknown parent '{named.Parent}', so it is parented to Master");
			}
		}

		// The cycles, each broken at the first member that sees itself.
		for (int i = 0; i < mCustomBuses.Count; i++)
		{
			var cursor = mCustomBuses[i].ParentCustom;
			var steps = 0;
			while ((cursor >= 0) && (steps <= mCustomBuses.Count))
			{
				if (cursor == (int32)i)
				{
					Console.Error.WriteLine(scope $"Audio: the custom bus '{mCustomBuses[i].Name}' is part of a parent CYCLE, so it is parented to Master");
					mCustomBuses[i].ParentCustom = -1;
					mCustomBuses[i].FixedParent = .Master;
					break;
				}
				cursor = mCustomBuses[cursor].ParentCustom;
				steps++;
			}
		}

		// The settings, and each bus's chain into its parent.
		for (let named in wanted)
		{
			let index = FindCustomBus(named.Name);
			if (index < 0)
				continue;

			let bus = mCustomBuses[index];
			bus.Volume = (named.Settings.Volume < 0.0f) ? 0.0f : named.Settings.Volume;
			bus.Muted = named.Settings.Muted;
			if (bus.Group == null)
				continue;

			mab_sound_group_set_volume(bus.Group, bus.Muted ? 0.0f : bus.Volume);
			let groupNode = mab_sound_group_get_node(bus.Group);
			mab_node_attach_output_bus(groupNode, 0, CustomBusParentNode(bus), 0);
			ClearEffectChain(bus.Effects);
			BuildEffectChain(groupNode, bus.Effects, CustomBusParentNode(bus),
				named.Settings.Effects);
		}

		// A re-parented bus changes each run's gain down its chain: they are applied again.
		for (let entry in mRunGroups)
			ApplyRunGains(entry.key, entry.value);
	}

	// ==================== scene groups ====================

	private static int BusIndex(AudioBus bus) => ((int)bus < AudioBus.Count) ? (int)bus : (int)AudioBus.Effects;

	/// The group a voice on this bus, in this scene or run, belongs to: the scene's child (under
	/// its run's child, or the bus outside a run), else the run's child, else the bus. The child
	/// groups are created LAZILY, so a scene or run that never plays on a bus never pays for one.
	private mab_sound_group* GroupFor(uint64 sceneGroup, uint64 runGroup, AudioBus bus)
	{
		let busIndex = BusIndex(bus);

		if (sceneGroup != 0)
		{
			if (mSceneGroups.TryGetValue(sceneGroup, let groups))
			{
				if (groups.Groups[busIndex] == null)
				{
					let parent = RunParentFor(groups.RunGroup, busIndex);
					if (parent != null)
						groups.Groups[busIndex] = mab_sound_group_create(mEngine, 0, mab_sound_group_get_node(parent));
					// A group born into a paused scene starts halted, or it would play.
					if ((groups.Groups[busIndex] != null) && groups.Paused)
						mab_sound_group_stop(groups.Groups[busIndex]);
				}
				if (groups.Groups[busIndex] != null)
					return groups.Groups[busIndex];
			}
		}
		return RunParentFor(runGroup, busIndex);
	}

	// ==================== run groups ====================

	/// A run's effective gain on one of its bus groups: the run's gain for that bus times its
	/// Master gain (once, not twice, on the Master group itself), its volume and its mute ramp.
	private static float RunGroupGain(RunGroupData run, int busIndex)
	{
		let master = (int)AudioBus.Master;
		let masterGain = run.BusMuted[master] ? 0.0f : run.BusGain[master];
		if (busIndex == master)
			return masterGain * run.Volume * run.MuteFactor;
		let busGain = run.BusMuted[busIndex] ? 0.0f : run.BusGain[busIndex];
		return busGain * masterGain * run.Volume * run.MuteFactor;
	}

	/// The run wide part of every gain the run carries: its Master gain, volume and mute ramp.
	private static float RunVoiceGain(RunGroupData run)
	{
		let master = (int)AudioBus.Master;
		return (run.BusMuted[master] ? 0.0f : run.BusGain[master]) * run.Volume * run.MuteFactor;
	}

	private RunGroupData FindRun(uint64 runGroup)
	{
		if (runGroup == 0)
			return null;
		return mRunGroups.TryGetValue(runGroup, let run) ? run : null;
	}

	/// The run's child group under a bus, made lazily, or the bus itself outside a run.
	private mab_sound_group* RunParentFor(uint64 runGroup, int busIndex)
	{
		if (let run = FindRun(runGroup))
		{
			if ((run.Groups[busIndex] == null) && (mBusGroups[busIndex] != null))
			{
				run.Groups[busIndex] = mab_sound_group_create(mEngine, 0, mab_sound_group_get_node(mBusGroups[busIndex]));
				if (run.Groups[busIndex] != null)
				{
					mab_sound_group_set_volume(run.Groups[busIndex], RunGroupGain(run, busIndex));
					// A group born into a paused run starts halted, or it would play.
					if (run.Paused)
						mab_sound_group_stop(run.Groups[busIndex]);
				}
			}
			if (run.Groups[busIndex] != null)
				return run.Groups[busIndex];
		}
		return mBusGroups[busIndex];
	}

	/// A run's gain on its child under custom bus `index`: its own gains down the bus's chain
	/// (each custom ancestor's by name, then the fixed bus the chain roots in) under its Master
	/// gain, volume and mute ramp, which is what its children under the fixed buses carry.
	private float RunCustomGain(RunGroupData run, int32 index)
	{
		var gain = 1.0f;
		var root = AudioBus.Master;
		var cursor = index;
		var steps = 0;
		while ((cursor >= 0) && (cursor < mCustomBuses.Count) && (steps++ <= mCustomBuses.Count))
		{
			let bus = mCustomBuses[cursor];
			if (let named = run.FindNamed(bus.Name))
				gain *= named.Muted ? 0.0f : named.Gain;
			root = bus.FixedParent;
			cursor = bus.ParentCustom;
		}
		if (root != .Master)
			gain *= run.BusMuted[(int)root] ? 0.0f : run.BusGain[(int)root];
		return gain * RunVoiceGain(run);
	}

	private void ApplyRunGains(uint64 runGroup, RunGroupData run)
	{
		for (int bus < AudioBus.Count)
		{
			if (run.Groups[bus] != null)
				mab_sound_group_set_volume(run.Groups[bus], RunGroupGain(run, bus));
		}
		for (int i < mCustomBuses.Count)
		{
			if (mCustomBuses[i].RunChildren.TryGetValue(runGroup, let child))
				mab_sound_group_set_volume(child, RunCustomGain(run, (int32)i));
		}
	}

	/// The run's child under custom bus `index`, made lazily; the bus itself outside a run.
	private mab_sound_group* CustomRunChild(uint64 runGroup, int32 index)
	{
		let bus = mCustomBuses[index];
		let run = FindRun(runGroup);
		if ((run == null) || (bus.Group == null))
			return bus.Group;
		if (bus.RunChildren.TryGetValue(runGroup, let found))
			return found;
		let child = mab_sound_group_create(mEngine, 0, mab_sound_group_get_node(bus.Group));
		if (child == null)
			return bus.Group;
		mab_sound_group_set_volume(child, RunCustomGain(run, index));
		if (run.Paused)
			mab_sound_group_stop(child);
		bus.RunChildren[runGroup] = child;
		return child;
	}

	/// The group a voice on custom bus `index` attaches to: its scene's child (under its run's
	/// child, or the bus outside a run), else its run's child, else the bus itself.
	private mab_sound_group* CustomGroupFor(uint64 sceneGroup, uint64 runGroup, int32 index)
	{
		let bus = mCustomBuses[index];
		if (bus.Group == null)
			return null;
		let runParent = CustomRunChild(runGroup, index);
		SceneGroupData sceneData = null;
		if ((sceneGroup == 0) || !mSceneGroups.TryGetValue(sceneGroup, out sceneData))
			return runParent;
		if (bus.SceneChildren.TryGetValue(sceneGroup, let found))
			return found;
		let child = mab_sound_group_create(mEngine, 0, mab_sound_group_get_node(runParent));
		if (child == null)
			return runParent;
		if (sceneData.Paused)
			mab_sound_group_stop(child);
		bus.SceneChildren[sceneGroup] = child;
		return child;
	}

	/// Pauses or resumes a group with the declick a scene group's pause uses.
	private void SetGroupPaused(mab_sound_group* group, bool paused)
	{
		if (paused)
		{
			mab_sound_group_stop_with_fade_ms(group, FadeMilliseconds);
		}
		else
		{
			mab_sound_group_reset_stop_time_and_fade(group);
			mab_sound_group_set_fade_in_ms(group, 0.0f, 1.0f, FadeMilliseconds);
			mab_sound_group_start(group);
		}
	}

	private void DestroyRunGroupData(uint64 runGroup)
	{
		if (!mRunGroups.TryGetValue(runGroup, let run))
			return;

		// Its scenes' groups first: they are children of the run's.
		let scenes = scope List<uint64>();
		for (let entry in mSceneGroups)
		{
			if (entry.value.RunGroup == runGroup)
				scenes.Add(entry.key);
		}
		for (let id in scenes)
			DestroySceneGroupData(id);

		for (var slot in mVoices)
		{
			if ((slot.State != .Free) && (slot.RunGroup == runGroup))
				ReleaseSlot(slot);
		}
		for (let bus in mCustomBuses)
		{
			if (bus.RunChildren.GetAndRemove(runGroup) case .Ok(let child))
				mab_sound_group_destroy(child.value);
		}
		for (int bus < AudioBus.Count)
		{
			if (run.Groups[bus] != null)
				mab_sound_group_destroy(run.Groups[bus]);
		}
		delete run;
		mRunGroups.Remove(runGroup);
	}

	private void DestroySceneGroupData(uint64 sceneGroup)
	{
		if (!mSceneGroups.TryGetValue(sceneGroup, let data))
			return;

		for (var slot in mVoices)
		{
			if ((slot.State != .Free) && (slot.SceneGroup == sceneGroup))
				ReleaseSlot(slot);
		}
		for (let bus in mCustomBuses)
		{
			if (bus.SceneChildren.GetAndRemove(sceneGroup) case .Ok(let child))
				mab_sound_group_destroy(child.value);
		}

		DestroyReverbNode(data.Reverb);
		DestroyReverbNode(data.SendReverb);
		for (int bus = 0; bus < AudioBus.Count; bus++)
		{
			if (data.Groups[bus] != null)
				mab_sound_group_destroy(data.Groups[bus]);
		}
		delete data;
		mSceneGroups.Remove(sceneGroup);
	}

	/// The scene's send target, created on first use: a WET ONLY reverb straight into the
	/// Effects bus, fed by the voices' own splitters.
	private ReverbNode EnsureSceneSendReverb(uint64 sceneGroup)
	{
		if (!mSceneGroups.TryGetValue(sceneGroup, let data))
			return null;

		if (data.SendReverb == null)
		{
			var parameters = AudioReverbParams();
			// A full tail, because the SEND level is the voice's own knob; and no dry at all,
			// because the dry path already reaches the bus.
			parameters.Wet = 1.0f;
			parameters.Dry = 0.0f;
			data.SendReverb = CreateReverbNode(parameters);
			if ((data.SendReverb != null) && (mBusGroups[(int)AudioBus.Effects] != null))
				mab_node_attach_output_bus(data.SendReverb.Node, 0,
					mab_sound_group_get_node(mBusGroups[(int)AudioBus.Effects]), 0);
		}
		return data.SendReverb;
	}

	// ==================== the file system bridge ====================
	//
	// These are called from the BACKEND'S OWN THREADS, which page a streamed voice in, so
	// nothing here may touch anything the caller's thread mutates.

	private static void* VfsOpen(void* user, char8* path)
	{
		let engine = (AudioEngine)Internal.UnsafeCastToObject(user);
		let stream = engine.OpenBridgedStream(StringView(path));
		if (stream == null)
			return null;

		let file = new BridgedFile();
		file.Stream = stream;
		return Internal.UnsafeCastToPtr(file);
	}

	private static void VfsClose(void* user, void* file)
	{
		delete (BridgedFile)Internal.UnsafeCastToObject(file);
	}

	private static uint VfsRead(void* user, void* file, void* destination, uint bytes)
	{
		let bridged = (BridgedFile)Internal.UnsafeCastToObject(file);
		let read = bridged.Stream.Read(.((uint8*)destination, (int)bytes));
		return (read > 0) ? (uint)read : 0;
	}

	private static int32 VfsSeek(void* user, void* file, int64 offset, int32 origin)
	{
		let bridged = (BridgedFile)Internal.UnsafeCastToObject(file);
		SeekOrigin mapped;
		switch ((mab_seek_origin)origin)
		{
		case .Start: mapped = .Begin;
		case .Current: mapped = .Current;
		default: mapped = .End;
		}
		return (bridged.Stream.Seek(offset, mapped) < 0) ? 1 : 0;
	}

	private static int64 VfsTell(void* user, void* file)
	{
		return ((BridgedFile)Internal.UnsafeCastToObject(file)).Stream.Tell();
	}

	private static int64 VfsSize(void* user, void* file)
	{
		return ((BridgedFile)Internal.UnsafeCastToObject(file)).Stream.Size();
	}

	/// Resolves a name the backend asked for.
	///
	/// A "dstream:" prefix names a registered stream clip, whose source opens a FRESH stream
	/// per voice; anything else goes through the optional mount, so a game may stream music
	/// straight off the virtual file system.
	private IStream OpenBridgedStream(StringView path)
	{
		if (path.StartsWith("dstream:"))
		{
			let key = int.Parse(path.Substring(8), .Hex);
			if (key case .Err)
				return null;
			if (!mStreamClips.TryGetValue(key.Value, let clip))
				return null;
			if ((clip == null) || (clip.StreamSource == null))
				return null;
			return clip.StreamSource.OpenStream();
		}

		if (mSettings.FileSystem != null)
			return mSettings.FileSystem.Open(path, .Read);
		return null;
	}

	// ==================== the listener ====================

	public void SetListenerTransform(Float3 position, Float3 forward, Float3 up, Float3 velocity)
	{
		SetListenerTransformIndexed(0, position, forward, up, velocity);
	}

	/// Moves one listener, for split screen. A spatial voice attenuates and pans against the
	/// CLOSEST enabled listener.
	public void SetListenerTransformIndexed(uint32 index, Float3 position, Float3 forward,
		Float3 up, Float3 velocity)
	{
		if (!mInitialized || (index >= mab_engine_get_listener_count(mEngine)))
			return;

		// The steal heuristic and the distance filter both track listener nought.
		if (index == 0)
			mListenerPosition = position;

		mab_engine_listener_set_position(mEngine, index, position.X, position.Y, position.Z);
		mab_engine_listener_set_direction(mEngine, index, forward.X, forward.Y, forward.Z);
		mab_engine_listener_set_world_up(mEngine, index, up.X, up.Y, up.Z);
		mab_engine_listener_set_velocity(mEngine, index, velocity.X, velocity.Y, velocity.Z);
	}

	public void SetListenerEnabled(uint32 index, bool enabled)
	{
		if (!mInitialized || (index >= mab_engine_get_listener_count(mEngine)))
			return;
		mab_engine_listener_set_enabled(mEngine, index, enabled ? 1 : 0);
	}

	public uint32 ListenerCount => mInitialized ? mab_engine_get_listener_count(mEngine) : 0;

	// ==================== master and buses ====================

	/// The engine's own output gain, above every bus.
	///
	/// It is the editor's knob for auditioning at a comfortable level; a game reaches for the
	/// bus volumes instead.
	public void SetMasterVolume(float volume)
	{
		mMasterVolume = (volume < 0.0f) ? 0.0f : volume;
		if (mInitialized)
			mab_engine_set_volume(mEngine, mMasterVolume);
	}

	public float MasterVolume => mMasterVolume;

	public void SetBusVolume(AudioBus bus, float volume)
	{
		let index = (int)bus;
		if (index >= AudioBus.Count)
			return;

		mBusVolume[index] = (volume < 0.0f) ? 0.0f : volume;
		// A muted bus keeps its volume as the level it will come back to.
		if ((mBusGroups[index] != null) && !mBusMuted[index])
			mab_sound_group_set_volume(mBusGroups[index], mBusVolume[index]);
	}

	public float BusVolume(AudioBus bus)
	{
		let index = (int)bus;
		return (index < AudioBus.Count) ? mBusVolume[index] : 0.0f;
	}

	public void SetBusMuted(AudioBus bus, bool muted)
	{
		let index = (int)bus;
		if (index >= AudioBus.Count)
			return;

		mBusMuted[index] = muted;
		if (mBusGroups[index] != null)
			mab_sound_group_set_volume(mBusGroups[index], muted ? 0.0f : mBusVolume[index]);
	}

	public bool BusMuted(AudioBus bus)
	{
		let index = (int)bus;
		return (index < AudioBus.Count) && mBusMuted[index];
	}

	/// Applies a whole layout: the fixed buses' tuning and chains, then the named ones.
	public void ApplyBusLayout(AudioBusLayout layout)
	{
		if (!mInitialized)
			return;

		for (int bus = 0; bus < AudioBus.Count; bus++)
		{
			let settings = layout.Buses[bus];
			SetBusVolume((AudioBus)bus, settings.Volume);
			SetBusMuted((AudioBus)bus, settings.Muted);
			BuildBusEffects(bus, settings.Effects);
		}

		RebuildCustomBuses(layout.CustomBuses);
	}

	/// The live effect count on a fixed bus, which is what a test and a diagnostic read.
	public uint32 BusEffectCount(AudioBus bus)
	{
		let index = (int)bus;
		return (index < AudioBus.Count) ? (uint32)mBusEffects[index].Count : 0;
	}

	// ==================== named buses ====================

	public bool HasNamedBus(StringView name) => FindCustomBus(name) >= 0;

	public uint32 NamedBusCount => (uint32)mCustomBuses.Count;

	public void SetNamedBusVolume(StringView name, float volume)
	{
		let index = FindCustomBus(name);
		if (index < 0)
			return;

		let bus = mCustomBuses[index];
		bus.Volume = (volume < 0.0f) ? 0.0f : volume;
		if ((bus.Group != null) && !bus.Muted)
			mab_sound_group_set_volume(bus.Group, bus.Volume);
	}

	/// Nought when the name is not one of ours, which is also a silent bus's answer: the
	/// caller that must tell them apart asks whether the bus exists.
	public float NamedBusVolume(StringView name)
	{
		let index = FindCustomBus(name);
		return (index >= 0) ? mCustomBuses[index].Volume : 0.0f;
	}

	public void SetNamedBusMuted(StringView name, bool muted)
	{
		let index = FindCustomBus(name);
		if (index < 0)
			return;

		let bus = mCustomBuses[index];
		bus.Muted = muted;
		if (bus.Group != null)
			mab_sound_group_set_volume(bus.Group, muted ? 0.0f : bus.Volume);
	}

	public bool NamedBusMuted(StringView name)
	{
		let index = FindCustomBus(name);
		return (index >= 0) && mCustomBuses[index].Muted;
	}

	public uint32 NamedBusEffectCount(StringView name)
	{
		let index = FindCustomBus(name);
		return (index >= 0) ? (uint32)mCustomBuses[index].Effects.Count : 0;
	}

	// ==================== music ====================

	/// Starts a track on the Music bus, cross fading the one already going.
	///
	/// Music carries NO scene group, so it survives a scene swap; and it runs through the
	/// same graph as everything else rather than around it. Each run has its own music slot
	/// (run nought is the one outside every run), so two runs never cross fade each other's.
	public VoiceHandle PlayMusic(AudioClip clip, float crossFadeSeconds = 1.0f,
		float volume = 1.0f, uint64 runGroup = 0)
	{
		let fadeMs = (uint64)(Max(crossFadeSeconds, 0.0f) * 1000.0f + 0.5f);
		let run = FindRun(runGroup);

		// The incumbent fades out over the SAME window the newcomer fades in.
		let current = Resolve((run != null) ? run.MusicVoice : mMusicVoice);
		if ((current != null) && (current.State != .Stopping))
		{
			mab_sound_stop_with_fade_ms(current.Sound, fadeMs);
			current.State = .Stopping;
		}
		SetMusicVoice(run, .());

		var parameters = AudioPlayParams();
		parameters.Bus = .Music;
		parameters.Loop = true;
		parameters.Volume = volume;
		// Replaying the same track RESTARTS it rather than merging into what is playing.
		parameters.AllowDedupe = false;
		parameters.RunGroup = (run != null) ? runGroup : 0;

		let handle = Play(clip, parameters);
		let slot = Resolve(handle);
		if ((slot != null) && (fadeMs > 0))
			mab_sound_set_fade_in_ms(slot.Sound, 0.0f, 1.0f, fadeMs);

		SetMusicVoice(run, handle);
		return handle;
	}

	public void StopMusic(float fadeSeconds = 1.0f, uint64 runGroup = 0)
	{
		let run = FindRun(runGroup);
		let slot = Resolve((run != null) ? run.MusicVoice : mMusicVoice);
		if ((slot != null) && (slot.State != .Stopping))
		{
			mab_sound_stop_with_fade_ms(slot.Sound,
				(uint64)(Max(fadeSeconds, 0.0f) * 1000.0f + 0.5f));
			slot.State = .Stopping;
		}
		SetMusicVoice(run, .());
	}

	/// The music voice of a run, or of the slot outside every run.
	public VoiceHandle MusicVoice(uint64 runGroup = 0)
	{
		let run = FindRun(runGroup);
		return (run != null) ? run.MusicVoice : mMusicVoice;
	}

	private void SetMusicVoice(RunGroupData run, VoiceHandle handle)
	{
		if (run != null)
			run.MusicVoice = handle;
		else
			mMusicVoice = handle;
	}

	// ==================== scenes ====================

	/// A scene's groups; a scene of a run nests under the run's groups.
	public uint64 CreateSceneGroup(uint64 runGroup = 0)
	{
		if (!mInitialized)
			return 0;

		let id = mNextSceneGroupId++;
		let data = new SceneGroupData();
		data.RunGroup = (FindRun(runGroup) != null) ? runGroup : 0;
		mSceneGroups[id] = data;
		return id;
	}

	// ==================== runs ====================
	//
	// Everything one running game plays (a GameInstance: the player's, each play in editor
	// Game tab's), one level above its scenes' groups. A run has its own child group under
	// each bus, carrying the run's own bus gains (a game's volume sliders never touch the
	// editor's or another run's buses), its music slot, and stop, pause, mute and volume for
	// the whole run.

	public uint64 CreateRunGroup()
	{
		if (!mInitialized)
			return 0;
		let id = mNextRunGroupId++;
		mRunGroups[id] = new RunGroupData();
		return id;
	}

	/// Stops and frees every voice of the run and its scene groups at once, then drops it.
	public void DestroyRunGroup(uint64 runGroup)
	{
		if (runGroup != 0)
			DestroyRunGroupData(runGroup);
	}

	/// Fade stops every voice of the run, its scenes' and its music included.
	public void StopRunGroup(uint64 runGroup, float fadeSeconds = 0.1f)
	{
		let run = FindRun(runGroup);
		if (run == null)
			return;
		let fadeMs = (uint64)(Max(fadeSeconds, 0.0f) * 1000.0f + 0.5f);
		for (var slot in mVoices)
		{
			if ((slot.State == .Free) || (slot.RunGroup != runGroup))
				continue;
			if (slot.State == .Paused)
			{
				ReleaseSlot(slot); // silent already
			}
			else if (slot.State != .Stopping)
			{
				mab_sound_stop_with_fade_ms(slot.Sound, fadeMs);
				slot.State = .Stopping;
			}
		}
		run.MusicVoice = .();
		// A paused run's group nodes are halted, so its voices' fades would never land: the
		// groups resume (silently, since the voices are fading) so the reap can finish.
		if (run.Paused)
			SetRunGroupPaused(runGroup, false);
	}

	/// Halts the run in place (its voices freeze with their cursors); resuming fades it back.
	public void SetRunGroupPaused(uint64 runGroup, bool paused)
	{
		let run = FindRun(runGroup);
		if ((run == null) || (run.Paused == paused))
			return;
		run.Paused = paused;
		// Halting the run's group node freezes every voice beneath it in place, its scenes'
		// included, with the same declick as a scene group's pause.
		for (int bus < AudioBus.Count)
		{
			if (run.Groups[bus] != null)
				SetGroupPaused(run.Groups[bus], paused);
		}
		// Its children under the custom buses halt the same way.
		for (let bus in mCustomBuses)
		{
			if (bus.RunChildren.TryGetValue(runGroup, let child))
				SetGroupPaused(child, paused);
		}
	}

	public bool IsRunGroupPaused(uint64 runGroup) => (FindRun(runGroup) != null) && FindRun(runGroup).Paused;

	/// Silences the run while its voices keep advancing (an unfocused Game tab); muting and
	/// unmuting ramp over a short cross fade, advanced by Update.
	public void SetRunGroupMuted(uint64 runGroup, bool muted)
	{
		if (let run = FindRun(runGroup))
			run.Muted = muted;
	}

	public bool IsRunGroupMuted(uint64 runGroup) => (FindRun(runGroup) != null) && FindRun(runGroup).Muted;

	public void SetRunGroupVolume(uint64 runGroup, float volume)
	{
		if (let run = FindRun(runGroup))
		{
			run.Volume = Max(volume, 0.0f);
			ApplyRunGains(runGroup, run);
		}
	}

	/// The run's own gain for a bus; its Master gain scales every bus of the run.
	public void SetRunBusVolume(uint64 runGroup, AudioBus bus, float volume)
	{
		let run = FindRun(runGroup);
		if ((run == null) || ((int)bus >= AudioBus.Count))
			return;
		run.BusGain[(int)bus] = Max(volume, 0.0f);
		ApplyRunGains(runGroup, run);
	}

	/// One when the run is unknown.
	public float RunBusVolume(uint64 runGroup, AudioBus bus)
	{
		let run = FindRun(runGroup);
		return ((run == null) || ((int)bus >= AudioBus.Count)) ? 1.0f : run.BusGain[(int)bus];
	}

	public void SetRunBusMuted(uint64 runGroup, AudioBus bus, bool muted)
	{
		let run = FindRun(runGroup);
		if ((run == null) || ((int)bus >= AudioBus.Count))
			return;
		run.BusMuted[(int)bus] = muted;
		ApplyRunGains(runGroup, run);
	}

	public bool RunBusMuted(uint64 runGroup, AudioBus bus)
	{
		let run = FindRun(runGroup);
		return (run != null) && ((int)bus < AudioBus.Count) && run.BusMuted[(int)bus];
	}

	/// The run's own gain for a layout's custom bus, by name: kept across a layout rebuild,
	/// and folded into the run's gains for the bus's descendants.
	public void SetRunNamedBusVolume(uint64 runGroup, StringView name, float volume)
	{
		if (let run = FindRun(runGroup))
		{
			run.EnsureNamed(name).Gain = Max(volume, 0.0f);
			ApplyRunGains(runGroup, run);
		}
	}

	public float RunNamedBusVolume(uint64 runGroup, StringView name)
	{
		let named = FindRun(runGroup)?.FindNamed(name);
		return (named != null) ? named.Gain : 1.0f;
	}

	public void SetRunNamedBusMuted(uint64 runGroup, StringView name, bool muted)
	{
		if (let run = FindRun(runGroup))
		{
			run.EnsureNamed(name).Muted = muted;
			ApplyRunGains(runGroup, run);
		}
	}

	public bool RunNamedBusMuted(uint64 runGroup, StringView name)
	{
		let named = FindRun(runGroup)?.FindNamed(name);
		return (named != null) && named.Muted;
	}

	/// Stops and frees every voice in the group at once, then drops the group.
	public void DestroySceneGroup(uint64 sceneGroup)
	{
		if (sceneGroup != 0)
			DestroySceneGroupData(sceneGroup);
	}

	/// Fades the group's output and halts its voices in place; resuming fades them back.
	public void SetSceneGroupPaused(uint64 sceneGroup, bool paused)
	{
		if (!mSceneGroups.TryGetValue(sceneGroup, let data) || (data.Paused == paused))
			return;

		data.Paused = paused;
		for (int bus = 0; bus < AudioBus.Count; bus++)
		{
			let group = data.Groups[bus];
			if (group == null)
				continue;

			if (paused)
			{
				// A group IS a sound, so the same fade then stop declick applies: halting the
				// group node freezes every voice routed through it in place.
				mab_sound_group_stop_with_fade_ms(group, FadeMilliseconds);
			}
			else
			{
				mab_sound_group_reset_stop_time_and_fade(group);
				mab_sound_group_set_fade_in_ms(group, 0.0f, 1.0f, FadeMilliseconds);
				mab_sound_group_start(group);
			}
		}

		// Its children under the custom buses halt the same way: a voice on a named bus routes
		// through the scene's child of that bus.
		for (let bus in mCustomBuses)
		{
			if (bus.SceneChildren.TryGetValue(sceneGroup, let child))
				SetGroupPaused(child, paused);
		}
	}

	public bool IsSceneGroupPaused(uint64 sceneGroup)
	{
		return mSceneGroups.TryGetValue(sceneGroup, let data) && data.Paused;
	}

	/// Fade stops every voice in the group; they reap as their fades land.
	public void StopSceneGroup(uint64 sceneGroup)
	{
		if (sceneGroup == 0)
			return;

		for (int i = 0; i < mVoices.Count; i++)
		{
			if ((mVoices[i].State != .Free) && (mVoices[i].SceneGroup == sceneGroup))
				Stop(VoiceHandle((uint32)i, mVoices[i].Generation));
		}
	}

	/// The scene's zone reverb, spliced on its Effects child group.
	///
	/// A wet of nought before anything is built stays a bypass: the node is only created when
	/// there is something to hear, and once created it STAYS spliced and its parameters update
	/// live rather than being torn down and rebuilt.
	public void SetSceneReverb(uint64 sceneGroup, AudioReverbParams parameters)
	{
		if (!mSceneGroups.TryGetValue(sceneGroup, let data))
			return;

		if (data.Reverb == null)
		{
			if (parameters.Wet <= 0.0f)
			{
				data.ReverbWet = 0.0f;
				return;
			}

			// The splice is on the scene's own child group: group, reverb, then the bus.
			let group = GroupFor(sceneGroup, 0, .Effects);
			if ((group == null) || (group == mBusGroups[(int)AudioBus.Effects]))
				return;

			data.Reverb = CreateReverbNode(parameters);
			if (data.Reverb == null)
				return;

			let effectsNode = mab_sound_group_get_node(mBusGroups[(int)AudioBus.Effects]);
			mab_node_attach_output_bus(data.Reverb.Node, 0, effectsNode, 0);
			mab_node_attach_output_bus(mab_sound_group_get_node(group), 0, data.Reverb.Node, 0);
		}

		data.ReverbWet = Clamp(parameters.Wet, 0.0f, 1.0f);
		var applied = AudioReverbParams();
		applied.RoomSize = parameters.RoomSize;
		applied.Damping = parameters.Damping;
		applied.Dry = parameters.Dry;
		applied.Wet = data.ReverbWet;
		data.Reverb.State.SetParams(applied);

		// The send reverb shares the room's character but stays wet only and fully open: the
		// send level lives on each voice's own splitter.
		if (data.SendReverb != null)
		{
			var sendParams = AudioReverbParams();
			sendParams.RoomSize = parameters.RoomSize;
			sendParams.Damping = parameters.Damping;
			sendParams.Wet = 1.0f;
			sendParams.Dry = 0.0f;
			data.SendReverb.State.SetParams(sendParams);
		}
	}

	public float SceneReverbWet(uint64 sceneGroup)
	{
		return mSceneGroups.TryGetValue(sceneGroup, let data) ? data.ReverbWet : 0.0f;
	}
}
