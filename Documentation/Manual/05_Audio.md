# Audio

Sedulous provides a full audio system with 3D spatialization, a mixing bus hierarchy, audio effects, sound cues, and engine-level components for scene integration.

## Architecture

```
Sedulous.Audio             -- Core: AudioClip, IAudioSystem, IAudioSource, bus system, mixer, effects
Sedulous.Audio.SDL3        -- SDL3 backend implementation
Sedulous.Audio.Decoders    -- Format decoders (WAV, OGG, MP3, FLAC)
Sedulous.Audio.Effects     -- DSP effects (reverb, delay, EQ, compressor, filters)
Sedulous.Audio.Resources   -- Resource wrappers (AudioClipResource, SoundCueResource)
Sedulous.Audio.Importer    -- Import pipeline for editor/tooling
Sedulous.Engine.Audio      -- Engine integration (AudioSubsystem, components)
```

## Setup

Register the audio subsystem and initialize decoders:

```beef
using Sedulous.Engine.Audio;
using Sedulous.Audio.Decoders;

protected override void OnConfigure(Context context)
{
    context.RegisterSubsystem(new AudioSubsystem(ResourceSystem));
}

```

## Audio Clips

An `AudioClip` holds decoded PCM audio data. Decode from file using an `AudioDecoderFactory`:

```beef
using Sedulous.Audio.Decoders;

let decoder = scope AudioDecoderFactory();
decoder.RegisterDefaultDecoders();  // WAV, OGG, MP3, FLAC

if (decoder.DecodeFile("audio/explosion.wav") case .Ok(let clip))
{
    // clip.SampleRate, clip.Channels, clip.Duration, clip.Data
}
```

Supported formats: `.wav`, `.ogg` (Vorbis), `.mp3`, `.flac`.

### Audio Format

`AudioFormat` is an enum describing the PCM sample format:

```beef
enum AudioFormat
{
    Int16,    // Signed 16-bit integer (2 bytes per sample)
    Int32,    // Signed 32-bit integer (4 bytes per sample)
    Float32   // 32-bit float (4 bytes per sample)
}
```

## Audio Sources

An `IAudioSource` plays audio clips with volume, pitch, panning, looping, and 3D spatialization.

### Engine Component

The easiest way to play positioned audio is via `AudioSourceComponent`:

```beef
let audioMgr = scene.GetModule<AudioSourceComponentManager>();
if (let source = audioMgr.Get(audioMgr.CreateComponent(entity)))
{
    var clipRef = ResourceRef(.Empty, "project://audio/explosion.audioclip");
    defer clipRef.Dispose();
    source.SetClipRef(clipRef);

    source.Volume = 0.8f;
    source.Pitch = 1.0f;
    source.Loop = false;
    source.AutoPlay = true;

    // 3D spatialization
    source.Spatial = true;
    source.MinDistance = 1.0f;    // Full volume within this range
    source.MaxDistance = 50.0f;   // Inaudible beyond this range
}
```

The entity's transform position is used for 3D spatialization each frame.

### Sound Cue Component

For sounds with variation, use a `SoundCueResource`. A sound cue selects randomly from a pool of clips with configurable pitch/volume ranges:

```beef
var cueRef = ResourceRef(.Empty, "project://audio/footstep.soundcue");
defer cueRef.Dispose();
source.SetCueRef(cueRef);
```

## Audio Listener

One entity should have an `AudioListenerComponent` -- typically the camera or player. This determines the "ear" position for 3D audio.

```beef
let listenerMgr = scene.GetModule<AudioListenerComponentManager>();
listenerMgr.CreateComponent(cameraEntity);
```

## Direct Playback

For sounds not tied to an entity (UI clicks, one-shots):

```beef
let audioSub = Context.GetSubsystem<AudioSubsystem>();

// One-shot (fire-and-forget)
audioSub.PlayOneShot(clip, 0.5f);

// Music (streaming from file)
audioSub.PlayMusic("audio/music/theme.ogg", loop: true, volume: 0.5f);
audioSub.StopMusic();
```

## 3D Spatialization

3D audio uses distance-based attenuation. Configure the model per source:

| Property | Description |
|----------|-------------|
| `MinDistance` | Distance at which volume is 100% |
| `MaxDistance` | Distance at which volume reaches 0% |
| `AttenuationCurve` | `.Linear`, `.InverseDistance`, `.Logarithmic`, `.InverseDistanceSquared` |

Attenuation is configured via a `SoundAttenuator` struct on the source, which also supports cone emission angles, distance-based low-pass filtering, and doppler.

The listener's position and orientation (from its entity transform) determine the perceived direction and distance of each source.

## Audio Bus System

Audio buses allow grouping and controlling volume for categories of sounds:

```beef
let busSystem = audioSub.AudioSystem.BusSystem;

// Default buses (SFX and Music) are created automatically.
// Create additional buses as needed:
let uiBus = busSystem.CreateBus("UI");

// Access existing buses by name
let sfxBus = busSystem.GetBus("SFX");
let musicBus = busSystem.GetBus("Music");

// Route sources to buses via name
source.BusName = "SFX";  // default for AudioSourceComponent

// Control volume per bus
sfxBus.Volume = 0.8f;
musicBus.Volume = 0.5f;

// Mute a bus (affects all children)
sfxBus.Muted = true;
```

Bus hierarchy:
```
Master (1.0)
  SFX (0.8)
  Music (0.5)
  UI (1.0)
```

Child bus volumes multiply with parent volumes.

## Audio Effects

DSP effects can be applied to buses or individual sources:

### Available Effects

| Effect | Description |
|--------|-------------|
| `ReverbEffect` | Room ambience simulation. Parameters: decay, wet/dry, room size. |
| `DelayEffect` | Echo/delay. Parameters: delay time, feedback, wet/dry. |
| `LowPassFilter` | Attenuates high frequencies. Parameters: cutoff frequency. |
| `HighPassFilter` | Attenuates low frequencies. Parameters: cutoff frequency. |
| `DistanceLowPassFilter` | Low-pass filter that increases with distance (occlusion simulation). |
| `CompressorEffect` | Dynamic range compression. Parameters: threshold, ratio, attack, release. |
| `ParametricEQ` | Multi-band equalizer. Per-band frequency, gain, Q. |
| `FadeEffect` | Volume fade in/out over time. |

### Applying Effects

```beef
using Sedulous.Audio.Effects;

// Apply reverb to the SFX bus
let reverb = new ReverbEffect();
reverb.RoomSize = 0.7f;
reverb.WetDryMix = 0.3f;
sfxBus.AddEffect(reverb);

// Low-pass filter on a bus
let lowPass = new LowPassFilter();
lowPass.CutoffHz = 2000.0f;
sfxBus.AddEffect(lowPass);
```

## Audio Graph

For advanced routing, the audio graph provides a node-based processing pipeline:

```
SourceNode -> VolumeNode -> EffectNode -> PanNode -> OutputNode
                              |
                         CombineNode <- SourceNode (layer multiple sources)
                              |
                         SplitNode -> EffectNode (per-channel processing)
```

Node types:
- `SourceNode` -- reads from an AudioClip
- `VolumeNode` -- amplitude control
- `EffectNode` -- applies an IAudioEffect
- `PanNode` -- stereo panning
- `CombineNode` -- mixes multiple inputs
- `SplitNode` -- splits to multiple outputs
- `OutputNode` -- final output to device

## Audio Mixer

The `AudioMixer` manages the master output and processes the bus hierarchy each frame. It's owned by the audio system and updated automatically.

## Resource Types

| Type | Extension | Description |
|------|-----------|-------------|
| `AudioClipResource` | `.audioclip` | Decoded PCM audio data |
| `SoundCueResource` | `.soundcue` | Playback configuration with clip pool, pitch/volume variation |

## Importing Audio

The `AudioImporter` in `Sedulous.Audio.Importer` converts source audio files into `AudioClipResource`:

```beef
using Sedulous.Audio.Importer;

let importer = new AudioImporter(decoderFactory);
if (importer.Import("sounds/explosion.wav") case .Ok(let resource))
{
    // resource is an AudioClipResource ready for registration
    ResourceSystem.AddResource<AudioClipResource>(resource);
}
```

## Next Steps

- [Animation](06_Animation.md) -- skeletal, property, and graph animation
