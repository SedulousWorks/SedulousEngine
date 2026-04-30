# Audio Roadmap

Gap analysis and redesign plan for the Sedulous audio system. Informed by
studying Traktor Engine and Zero Engine audio architectures.

## Current State - DONE

### Original Foundation
- ~~**IAudioSystem / IAudioSource / IAudioStream**~~ - clean interface abstraction
- ~~**SDL3 backend**~~ - device management, WAV loading, file streaming
- ~~**Decoders**~~ - WAV, MP3, OGG Vorbis, FLAC (via dr_libs / stb_vorbis)
- ~~**3D audio**~~ - configurable distance attenuation + constant-power stereo panning
- ~~**Music streaming**~~ - 16KB chunk streaming from disk (WAV only)
- ~~**Fire-and-forget**~~ - PlayOneShot / PlayOneShot3D / PlayCue / PlayCue3D
- ~~**Engine integration**~~ - AudioSourceComponent, AudioListenerComponent, AudioSubsystem
- ~~**Resource system**~~ - AudioClipResource, SoundCueResource with hot-reload support

### Audio Node Graph (completed)
- ~~**AudioNode base**~~ - inputs/outputs, mix-version caching, lazy evaluation
  - ~~SourceNode~~ - reads AudioClip, converts to float32 stereo, looping, volume
  - ~~CombineNode~~ - sums all inputs
  - ~~VolumeNode~~ - gain with smooth interpolation
  - ~~EffectNode~~ - wraps IAudioEffect for in-place processing
  - ~~PanNode~~ - constant-power stereo panning
  - ~~SplitNode~~ - routes signal to multiple outputs (sends/side-chains)
  - ~~OutputNode~~ - graph evaluation root
  - ~~AudioGraph~~ - owns OutputNode, evaluates by pulling recursively

### Mixer Architecture (completed)
- ~~**AudioMixer (abstract)**~~ - owns AudioGraph + AudioBusSystem, evaluates graph, calls OutputMix()
- ~~**SDL3AudioMixer**~~ - converts float32->int16, pushes to SDL device stream
- ~~**AudioSource**~~ - platform-independent IAudioSource with SourceNode->PanNode chain
- ~~**SDL3AudioSystem**~~ - SDL device management, uses SDL3AudioMixer

### Bus System (completed)
- ~~**IAudioEffect**~~ - in-place float32 stereo processing interface
- ~~**IAudioBus / IAudioBusSystem**~~ - bus interfaces with effects chain + advanced graph access
- ~~**AudioBus**~~ - owns CombineNode -> [EffectNodes] -> VolumeNode, manages lifetime
- ~~**AudioBusSystem**~~ - Master/SFX/Music defaults, create/destroy/reparent
- ~~**Bus routing**~~ - sources route to buses by BusName, runtime re-routing
- ~~**AudioSubsystem**~~ - SFXVolume/MusicVolume/MasterVolume backed by bus system

### Effects (completed, Sedulous.Audio.Effects module)
- ~~LowPassFilter~~ - biquad 2nd-order IIR
- ~~HighPassFilter~~ - biquad 2nd-order IIR
- ~~ReverbEffect~~ - Schroeder (4 comb + 2 allpass, per-channel stereo offset)
- ~~DelayEffect~~ - circular buffer with feedback
- ~~CompressorEffect~~ - envelope follower + gain reduction
- ~~ParametricEQ~~ - 3-band (low shelf, mid peak, high shelf) cascaded biquads
- ~~FadeEffect~~ - volume interpolation with linear/ease-in/ease-out curves
- ~~DistanceLowPassFilter~~ - externally driven cutoff for 3D muffling

### Improved 3D Audio (completed)
- ~~SoundAttenuator~~ - configurable curves (Linear, InverseDistance, Logarithmic, InverseDistanceSquared)
- ~~Distance-based low-pass~~ - logarithmic cutoff interpolation
- ~~Emission cones~~ - inner/outer angle with gain interpolation
- ~~Doppler~~ - factor-based pitch adjustment
- ~~IAudioSource.Direction~~ - forward vector for cone attenuation
- ~~IAudioSource.Attenuator~~ - optional SoundAttenuator per source

### Sound Cues (completed)
- ~~SoundCue~~ - weighted entries with volume/pitch randomization
- ~~CueSelectionMode~~ - Random, Sequential, Shuffle
- ~~Voice limiting~~ - MaxInstances with cooldown
- ~~Priority~~ - for voice stealing
- ~~SoundCueResource~~ - serializable resource with clip refs
- ~~SoundCueResourceManager~~ - LoadFromFile with SerializerProvider, hot-reload
- ~~PlayCue / PlayCue3D~~ - on IAudioSystem and AudioSubsystem

### Engine Integration (completed)
- ~~AudioSourceComponent~~ - BusName, CueRef, UseAttenuator, AttenuatorConfig, Direction
- ~~AudioSourceComponentManager~~ - resolves cue refs, applies attenuator, syncs direction from transform
- ~~AudioSubsystem~~ - registers SoundCueResourceManager, PlayCue/PlayCue3D convenience methods

### Ownership Model
- AudioGraph only owns the OutputNode it creates
- AudioMixer owns AudioGraph + AudioBusSystem
- Buses own their own nodes (CombineNode, VolumeNode, EffectNodes)
- Sources own their nodes (SourceNode, PanNode)
- Clear single-owner per node, no split ownership

### Module Layout
```
Sedulous.Audio (core, platform-independent)
  src/
    Interfaces: IAudioSource, IAudioSystem, IAudioStream, IAudioBus, IAudioBusSystem, IAudioEffect
    Implementations: AudioSource, AudioBus, AudioBusSystem, AudioMixer (abstract),
                     AudioClip, AudioListener, SoundCue, AttenuationModel
    Graph/: AudioGraph, AudioNode, SourceNode, CombineNode, VolumeNode,
            EffectNode, PanNode, SplitNode, OutputNode

Sedulous.Audio.SDL3 (backend, SDL-specific - 3 files)
  src/: SDL3AudioMixer, SDL3AudioStream, SDL3AudioSystem

Sedulous.Audio.Effects (DSP, platform-independent)
  src/: LowPassFilter, HighPassFilter, ReverbEffect, DelayEffect,
        CompressorEffect, ParametricEQ, FadeEffect, DistanceLowPassFilter

Sedulous.Audio.Resources (resource system integration)
  src/: AudioClipResource, AudioClipResourceManager,
        SoundCueResource, SoundCueResourceManager

Sedulous.Engine.Audio (engine subsystem layer)
  src/: AudioSubsystem, AudioSourceComponent, AudioSourceComponentManager,
        AudioListenerComponent, AudioListenerComponentManager
```

---

## Reference Engines

### What was taken from Traktor
- Dedicated mixer thread model (architecture ready, not yet threaded)
- Float32 mixing with additive accumulation
- Category/group volume with handle-based lookup -> bus system

### What was taken from Zero Engine
- Audio bus hierarchy -> IAudioBus/IAudioBusSystem
- SoundCue resource with weighted selection, pitch/volume randomization
- SoundAttenuator with configurable curves + distance-based low-pass muffling
- Rich DSP effects (reverb, delay, compressor, EQ)
- Voice limiting per cue with priority

### What was taken from both
- Audio node graph as foundation with public API for advanced users
- Simple bus API on top for common use cases

---

## Remaining Work

### Phase 5: Dedicated Mixer Thread (not scheduled)
- Move Mix() into SDL audio callback or dedicated thread
- Command queue for main thread -> mix thread operations (create/destroy source, connect/disconnect)
- Double-buffer or lock-free queue for source state updates
- Effect parameter changes already safe (single-word float writes)
- Bus hierarchy mutations deferred to start of next mix cycle

### Phase 6: HRTF Spatial Audio (not scheduled)

Binaural 3D audio for headphone users. Replaces stereo panning with
per-ear FIR convolution based on source direction relative to listener.

**What it is:**
- A pair of FIR filters per ear that change based on azimuth/elevation
- Encodes head/ear/torso acoustic effects (shadowing, reflections, delays)
- Typical datasets: 128-512 tap filters for ~700+ directions

**Recommended approach:**
- Use **libmysofa** (BSD, ~2000 lines C) to load standard SOFA HRTF datasets
- Implement `HrtfNode : AudioNode` that replaces PanNode for headphone output
- Per-source: compute azimuth/elevation, lookup nearest HRTF pair, convolve
- Interpolate between adjacent HRTF directions to avoid clicking
- Keep regular PanNode path for speaker output, let user choose mode

**Graph integration:**
```
SourceNode -> HrtfNode -> bus CombineNode   (headphone mode)
SourceNode -> PanNode  -> bus CombineNode   (speaker mode)
```

**Effort:** ~3-5 days with libmysofa, ~5-8 days fully custom

**Dependencies:** libmysofa for SOFA dataset parsing, or raw MIT KEMAR binary

### Phase 7: Additional Effects (not scheduled)
- Chorus, Flanger, Phaser, Distortion, Limiter, Pitch Shift
- Each is a self-contained IAudioEffect implementation
- Add as needed based on game requirements

### Phase 8: Interactive Music (not scheduled)
- Music state machine with branching/transitions
- Beat-synced crossfading between tracks
- Tempo and time signature tracking
- Music timing events (beat, bar, note callbacks)

### Phase 9: Surround Sound (not scheduled)
- VBAP (Vector Base Amplitude Panning) for multi-speaker configurations
- Speaker configuration detection from SDL3
- Extend AudioNode buffers from stereo to N-channel
- Combination matrix for channel-to-speaker mapping

---

## Architecture Overview

Two API layers - a simple high-level API for common use, and a public audio
node graph for advanced users who need side-chains, sends, or custom DSP.

### Layer 1: Audio Node Graph (foundation, public)

The core audio engine is a directed acyclic graph (DAG) of `AudioNode` objects.
Each node has inputs and outputs, processes float32 stereo buffers, and routes
audio through the graph. The graph is evaluated by pulling from the OutputNode,
which recursively pulls inputs. Mix-version caching prevents redundant evaluation.

```
 AudioSource
 [SourceNode -> PanNode] --> CombineNode ("SFX") --+
 AudioSource                   /                    |
 [SourceNode -> PanNode] -----/                     v
                                           VolumeNode (Master) --> OutputNode
 AudioSource                               ^                       |
 [SourceNode -> PanNode] --> CombineNode ("Music") -/         SDL3AudioMixer
                                                          float32->int16->device
```

**Graph manipulation API (advanced users):**
- `node.AddInput(other)` / `node.RemoveInput(other)`
- `node.InsertBefore(newNode)` / `node.InsertAfter(newNode)`
- Subclass `AudioNode` for custom DSP

### Layer 2: Bus API (high-level, built on the graph)

A bus is internally: inputs -> CombineNode -> [EffectNodes] -> VolumeNode -> parent bus

**High-level API:**
- `bus.AddEffect(new ReverbEffect())` -> inserts EffectNode in bus chain
- `source.BusName = "SFX"` -> routes source into SFX combine node
- `audioSystem.PlayCue(footstepCue)` -> picks variant, creates source, routes to bus

**Advanced API (drop down to graph):**
- Side-chain: compressor on Music bus with side-chain input from Voice bus
- Send/return: SplitNode on source -> dry to SFX bus, wet to shared reverb bus
- Custom DSP: subclass AudioNode with custom ProcessAudio()

---

## Thread Safety Strategy

Current: all on main thread. Design is thread-safety-ready:

- Mix buffers are fixed-size, allocated at init (no dynamic allocation during mixing)
- Bus hierarchy mutations use two-pass teardown (disconnect all, then delete)
- Effect parameters are simple float/int32 fields (atomic on aligned modern CPUs)
- Source/stream lists guarded by single access point
- Abstract AudioMixer / SDL3AudioMixer split makes threading a backend concern
