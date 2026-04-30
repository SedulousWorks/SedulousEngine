# Audio Roadmap

Gap analysis and redesign plan for the Sedulous audio system. Informed by
studying Traktor Engine and Zero Engine audio architectures.

## Current State - DONE

- ~~**IAudioSystem / IAudioSource / IAudioStream**~~ - clean interface abstraction
- ~~**SDL3 backend**~~ - chunk-based playback to device
- ~~**Decoders**~~ - WAV, MP3, OGG Vorbis, FLAC (via dr_libs / stb_vorbis)
- ~~**3D audio**~~ - linear distance attenuation + constant-power stereo panning
- ~~**Volume hierarchy**~~ - Master × Category (SFX/Music) × Component volume
- ~~**Music streaming**~~ - 16KB chunk streaming from disk (WAV only)
- ~~**Fire-and-forget**~~ - PlayOneShot / PlayOneShot3D
- ~~**Engine integration**~~ - AudioSourceComponent, AudioListenerComponent, AudioSubsystem
- ~~**Resource system**~~ - AudioClipResource with hot-reload support
- ~~**Tests**~~ - 7 test files covering core functionality

## Current Weaknesses

- No audio bus/group system (flat SFX/Music categories only)
- No effects/DSP (no reverb, EQ, delay, filter, compression)
- No dedicated mix thread (all processing on main thread via SDL3)
- No surround sound (stereo only)
- No Doppler effect
- No directional sources (emission cones)
- No configurable attenuation curves (linear only)
- No priority system for voice management
- No fade/crossfade support
- No sound cue system (randomization, variations)

## Reference Engines

### What to take from Traktor
- Dedicated mixer thread model with fixed-size frame processing
- IAudioFilter with per-instance state pattern
- SIMD-optimized float32 mixing (additive MixIn)
- Category/group volume with handle-based lookup
- GroupFilter for chaining effects

### What to take from Zero Engine
- Audio bus hierarchy (SoundSpace/Tag -> simplified to named buses)
- SoundCue resource with weighted random/sequential selection, pitch/volume randomization
- SoundAttenuator with configurable curves + distance-based low-pass muffling
- Rich DSP effects (reverb, delay, compressor, EQ, flanger/chorus)
- Per-listener spatial calculations + VBAP for surround
- Voice limiting per cue with priority-based stealing
- Smooth interpolation on all property changes

### What to take from both
- Audio node graph as the internal foundation (both engines converge on this)
  - Traktor: Graph with Node/Edge/InputPin/OutputPin, GraphEvaluator
  - Zero: SoundNode with AddInputNode/RemoveInputNode, lazy evaluation
  - Ours: public graph for advanced users, simple bus/PlayCue API on top

### What NOT to take
- Granular/additive synthesis (Zero Engine) - niche, add later if needed
- Tracker/song system (Traktor) - not relevant

---

## Architecture Overview

Two API layers — a simple high-level API for common use, and a public audio
node graph for advanced users who need side-chains, sends, or custom DSP.

### Layer 1: Audio Node Graph (foundation, public)

The core audio engine is a directed acyclic graph (DAG) of `AudioNode` objects.
Each node has inputs and outputs, processes float32 stereo buffers, and routes
audio through the graph. The graph is evaluated bottom-up (leaves first) each
mix cycle with lazy evaluation and mix-version caching.

```
                        ┌─────────┐
 SourceNode ──> EffectNode ──> CombineNode ("SFX" bus) ──┐
 SourceNode ──────────────────────┘                      │
                                                         v
 SourceNode ──> CombineNode ("Music" bus) ──────> CombineNode (Master) ──> OutputNode
                                                         ^
 SourceNode ──> CombineNode ("UI" bus) ─────────────────┘
```

**Core node types:**
- `AudioNode` - base class: inputs/outputs, GetOutputSamples(), mix-version caching
- `SourceNode` - reads from AudioClip, applies pitch/playback position
- `CombineNode` - sums all inputs (basis for bus grouping)
- `VolumeNode` - gain control with interpolation
- `EffectNode` - wraps an IAudioEffect for in-place processing
- `PanNode` - stereo/surround panning
- `OutputNode` - final device output
- `SplitNode` - sends signal to multiple outputs (for sends/side-chains)

**Graph manipulation API (advanced users):**
- `node.AddInput(other)` / `node.RemoveInput(other)`
- `node.InsertBefore(newNode)` / `node.InsertAfter(newNode)`
- `AudioGraph.AddNode(node)` / `AudioGraph.RemoveNode(node)`

### Layer 2: Bus API (high-level, built on the graph)

The bus API is a convenience layer that creates and manages graph nodes
under the hood. Most users only interact with this layer.

A bus is internally: inputs -> CombineNode -> EffectNodes -> VolumeNode -> parent bus

```
Sources render Float32 stereo into buffers
    |
Route to named AudioBus (SFX, Music, UI, Ambient, Voice, etc.)
    |
Bus effects chain: [LowPass] -> [Reverb] -> [Compressor] -> ...
    |
Apply bus volume, route to parent bus
    |
Master bus -> OutputNode -> device
```

**High-level API examples:**
- `bus.AddEffect(new ReverbEffect())` -> inserts EffectNode in bus chain
- `source.BusName = "SFX"` -> routes source into SFX combine node
- `audioSystem.PlayCue(footstepCue)` -> picks variant, creates source, routes to bus

**Advanced API examples (drop down to graph):**
- Side-chain: compressor node on Music bus with side-chain input from Voice bus
- Send/return: SplitNode on source -> dry to SFX bus, wet to shared reverb bus
- Custom DSP: user subclass of AudioNode with custom GetOutputSamples()

Key architectural shift: move from per-source SDL streams to a single centralized
AudioMixer that evaluates the audio graph, and outputs one stream to the device.

---

## Phase 1 - Audio Node Graph + Bus System

### Step 1a: Audio Node Graph (Sedulous.Audio)

**AudioNode** - base class for all audio graph nodes:
- `GetOutputSamples(float* buffer, int32 frameCount, int32 sampleRate)` - produce/process audio
- Input/output connections: `AddInput(node)`, `RemoveInput(node)`
- `InsertBefore(node)` / `InsertAfter(node)` for chain manipulation
- Mix-version tracking for lazy evaluation (don't recompute if already evaluated this frame)
- `AccumulateInputSamples()` - sums all input buffers

**Built-in node types:**
- `SourceNode` - reads from AudioClip, handles pitch/position/looping
- `CombineNode` - sums all inputs (auto-collapses when last input removed)
- `VolumeNode` - gain multiplier with smooth interpolation
- `EffectNode` - wraps an IAudioEffect, processes in-place
- `PanNode` - stereo panning (constant-power)
- `OutputNode` - final graph output, feeds device stream
- `SplitNode` - routes one signal to multiple destinations (sends)

**AudioGraph** - owns and evaluates the node DAG:
- `AddNode(node)` / `RemoveNode(node)`
- `OutputNode` property (root of evaluation)
- `Evaluate(frameCount, sampleRate)` - bottom-up traversal with mix-version caching
- Deferred mutations (add/remove queued, applied at start of next evaluation)

**IAudioEffect** - core DSP processing interface:
- `Process(float* buffer, int32 frameCount, int32 sampleRate)` - in-place float32 stereo
- `Reset()` - clear internal state (delay lines, filters)
- `Enabled` property for bypass

### Step 1b: Bus API (Sedulous.Audio, built on graph)

**IAudioBus** - named mixing bus (internally manages graph nodes):
- `Name`, `Volume` (0-1), `Muted` flag
- `Parent` bus (null for Master)
- Ordered effects chain: `AddEffect`, `InsertEffect`, `RemoveEffect`, `ClearEffects`
- `InputNode` - the CombineNode sources route into (advanced access)
- `OutputNode` - the VolumeNode at the end of the bus chain (advanced access)

**IAudioBusSystem** - bus hierarchy manager:
- `Master` property (always exists)
- `GetBus(name)`, `CreateBus(name, parent)`, `DestroyBus(bus)`
- `GetBusNames()` for enumeration/debugging
- `Graph` property - exposes the underlying AudioGraph for advanced users

### Step 1c: Mixer Implementation (Sedulous.Audio.SDL3)

**AudioMixer** - central mix dispatch:
- Owns the AudioGraph with OutputNode connected to single SDL_AudioStream
- Per-frame: render sources into SourceNodes -> evaluate graph -> push to device
- Fixed frame size (1024 frames = ~21ms at 48kHz)

**AudioBus** - concrete bus implementation:
- Internally creates: CombineNode -> [EffectNodes] -> VolumeNode
- `AddEffect(effect)` inserts an EffectNode in the chain
- `Volume` sets the VolumeNode gain
- Routing to parent connects this bus's VolumeNode output to parent's CombineNode input

### Changes to Existing Code

**SDL3AudioSource** - replace per-source SDL stream with buffer rendering:
- Remove own `SDL_AudioStream*`
- Add `RenderFrames(float* outBuffer, int32 frameCount) -> int32` - reads clip, converts
  to float32 stereo, applies source volume + 3D gains + pitch
- Keep `Update3D()` for spatial calculations

**IAudioSource** - add `BusName` property (default "SFX")

**IAudioSystem** - add `BusSystem` property

**AudioSubsystem** - replace flat SFXVolume/MusicVolume with bus volume accessors:
- `SFXVolume` -> `GetBusVolume("SFX")` / `SetBusVolume("SFX", value)`
- `MusicVolume` -> `GetBusVolume("Music")` / `SetBusVolume("Music", value)`
- `MasterVolume` -> Master bus volume

**AudioSourceComponent** - replace `AudioVolumeCategory` enum with `BusName` string

### Mix Pipeline Data Flow

```
1. Update3D on all sources (distance gain, pan, doppler)
2. AudioMixer.Mix():
   a. Drain deferred graph mutations (node add/remove)
   b. For each playing source: update SourceNode with current clip position/state
   c. AudioGraph.Evaluate(framesPerMix, sampleRate):
      - Bottom-up traversal from OutputNode
      - Each node checks mix-version, skips if already computed this frame
      - SourceNodes: read clip -> float32 stereo -> apply source volume + 3D
      - CombineNodes: sum all inputs
      - EffectNodes: process buffer in-place
      - VolumeNodes: apply gain with interpolation
      - OutputNode: final mixed buffer ready
   d. OutputNode buffer -> clamp [-1,1] -> convert to device format -> push to SDL
3. Clean up finished one-shots
```

### Backward Compatibility
- All existing IAudioSource/IAudioSystem methods unchanged
- SFXVolume/MusicVolume kept as convenience accessors
- AudioVolumeCategory maps to bus names ("SFX", "Music")
- Existing tests pass without changes

---

## Phase 2 - Effects

### New Module: Sedulous.Audio.Effects

Depends on Sedulous.Audio (for IAudioEffect) and corlib only.

All effects implement IAudioEffect, process float32 stereo buffers in-place.

**LowPassFilter** - biquad (2nd order IIR):
- Parameters: CutoffHz, Resonance (Q)
- State: previous sample values per channel

**HighPassFilter** - biquad:
- Parameters: CutoffHz, Resonance
- Same structure as LowPass with different coefficients

**ReverbEffect** - Schroeder-Moorer style:
- 4 parallel comb filters + 2 series allpass filters
- Parameters: RoomSize (0-1), Damping (0-1), WetDryMix (0-1), DecayTime (seconds)
- State: delay line buffers (allocated on first Process or parameter change)

**DelayEffect** - delay line with feedback:
- Parameters: DelayTime (0.01-2.0s), Feedback (0-0.95), WetDryMix (0-1)
- State: circular buffer

**CompressorEffect** - dynamics compressor:
- Parameters: ThresholdDb (-60 to 0), Ratio (1:1 to 20:1), AttackMs, ReleaseMs, MakeupGainDb
- State: envelope follower value

**ParametricEQ** - 3-band (low shelf, mid peak, high shelf):
- Each band: FrequencyHz, GainDb (-12 to +12), Q
- Implemented as 3 cascaded biquad filters
- State: biquad state per band per channel

**FadeEffect** - volume interpolation utility:
- Parameters: TargetVolume, Duration (seconds), curve type (linear, ease-in, ease-out)
- State: current volume, elapsed time
- Holds at target when complete
- Useful for bus-level fades, crossfades, ducking

---

## Phase 3 - Improved 3D Audio

### SoundAttenuator

Configurable distance attenuation (can be shared as a resource across sources):

```
AttenuationCurve enum:
  Linear        - gain = 1 - (d - min) / (max - min)
  InverseDistance - gain = min / d
  Logarithmic   - gain = 1 - log(d/min) / log(max/min)
  InverseDistanceSquared - gain = (min/d)^2

SoundAttenuator struct:
  MinDistance          = 1.0       (attenuation begins)
  MaxDistance          = 100.0     (sound inaudible)
  Curve                = InverseDistance
  MaxDistanceLowPassHz = 0.0      (0 = disabled; otherwise muffles with distance)
  ConeInnerAngle       = 360.0    (full volume inside this cone)
  ConeOuterAngle       = 360.0    (attenuated between inner/outer)
  ConeOuterGain        = 0.0      (volume at outer edge)
  DopplerFactor        = 0.0      (0 = disabled, 1 = realistic)
```

### Changes to SDL3AudioSource.Update3D

- Replace linear attenuation with `attenuator.CalculateGain(distance)`
- Add distance-based low-pass filter (per-source, driven by distance ratio)
- Add cone attenuation: dot(sourceForward, toListener) -> angle -> gain
- Add Doppler: track previous position, compute velocity, adjust pitch ratio

### Changes to IAudioSource

- Add `Direction` property (Vector3) for cone emission forward vector
- Add `SoundAttenuator?` optional attenuator field (null = use defaults)

---

## Phase 4 - Sound Cues

### SoundCue Resource

```
CueSelectionMode enum: Random, Sequential, Shuffle

SoundCueEntry struct:
  Clip         - AudioClip reference
  Weight       - selection weight for Random mode (default 1.0)
  VolumeMin/Max - per-play volume randomization range (default 1.0/1.0)
  PitchMin/Max  - per-play pitch randomization range (default 1.0/1.0)

SoundCue class:
  Name              - display name
  Entries           - list of SoundCueEntry
  SelectionMode     - Random / Sequential / Shuffle
  MaxInstances      - max simultaneous (0 = unlimited)
  Priority          - for voice stealing (higher = more important)
  Cooldown          - minimum seconds between plays
  BusName           - target bus
  SelectEntry(time) - picks next entry, returns null if limited/cooldown
```

### Integration

- Add `PlayCue(SoundCue, volume)` and `PlayCue3D(SoundCue, position, volume)` to IAudioSystem
- Add `SoundCueResource` and `SoundCueResourceManager` to Sedulous.Audio.Resources
- Add optional `CueRef` to AudioSourceComponent (overrides ClipRef for variation playback)
- Voice limiting: track active instances per cue, steal lowest priority when at limit

---

## Thread Safety Strategy

Current: all on main thread. Design is thread-safety-ready:

- Mix buffers are fixed-size, allocated at init (no dynamic allocation during mixing)
- Bus hierarchy mutations deferred to start of next mix cycle
- Effect parameters are simple float/int32 fields (atomic on aligned modern CPUs)
- Source/stream lists guarded by single access point

Future dedicated mixer thread (Phase 5, not scheduled):
- SDL3 audio callback drives mix on audio thread
- Source creation/destruction via command queue
- Effect parameter changes already safe (single-word writes)

---

## New File Summary

### Sedulous.Audio/src/ (new files)
- IAudioEffect.bf
- IAudioBus.bf
- IAudioBusSystem.bf
- AttenuationModel.bf (AttenuationCurve enum + SoundAttenuator struct)
- SoundCue.bf (SoundCue, SoundCueEntry, CueSelectionMode)

### Sedulous.Audio/src/Graph/ (new files)
- AudioNode.bf (base class + input/output management)
- SourceNode.bf
- CombineNode.bf
- VolumeNode.bf
- EffectNode.bf
- PanNode.bf
- OutputNode.bf
- SplitNode.bf
- AudioGraph.bf (owns nodes, evaluates DAG)

### Sedulous.Audio.SDL3/src/ (new files)
- AudioBus.bf (concrete bus, manages graph nodes internally)
- AudioBusSystem.bf
- AudioMixer.bf

### Sedulous.Audio.Effects/src/ (NEW MODULE)
- LowPassFilter.bf
- HighPassFilter.bf
- ReverbEffect.bf
- DelayEffect.bf
- CompressorEffect.bf
- ParametricEQ.bf
- FadeEffect.bf
- DistanceLowPassFilter.bf

### Sedulous.Audio.Resources/src/ (new files)
- SoundCueResource.bf
- SoundCueResourceManager.bf

---

## Implementation Order

1. **AudioNode base + core nodes** - AudioNode, SourceNode, CombineNode, VolumeNode, OutputNode, AudioGraph with evaluation
2. **Float32 pipeline** - modify SDL3AudioSource to render into SourceNodes; create AudioMixer with graph evaluation; single SDL output stream; verify existing audio still works
3. **Bus system** - IAudioBus, IAudioBusSystem, AudioBus (wrapping graph nodes), AudioBusSystem; add BusName to sources; migrate AudioSubsystem volume categories
4. **IAudioEffect + EffectNode** - IAudioEffect interface; EffectNode wrapping it; wire into bus chain; implement LowPassFilter + HighPassFilter to prove the chain
5. **Remaining effects** - Reverb, Delay, Compressor, ParametricEQ, Fade (each independent)
6. **Advanced graph nodes** - PanNode, SplitNode for sends/side-chains
7. **Improved 3D** - SoundAttenuator with curves, distance low-pass, cone attenuation, Doppler
8. **Sound cues** - SoundCue resource, PlayCue API, voice limiting, priority

Each step includes corresponding unit tests before moving to the next.

---

## Test Plan

Tests live in Sedulous.Audio.Tests (existing, extend) and Sedulous.Audio.Effects.Tests (new module).
All tests operate on in-memory float32 buffers — no SDL device needed.

### Step 1: Audio Node Graph Tests

**AudioNode base:**
- AddInput/RemoveInput updates connection lists
- InsertBefore/InsertAfter wires correctly
- Mix-version caching: GetOutputSamples only evaluates once per frame
- Double-evaluate in same frame returns cached result

**SourceNode:**
- Renders correct samples from AudioClip into float32 buffer
- Respects playback position (advancing each render)
- Handles end-of-clip (returns silence, marks finished)
- Looping wraps position back to start

**CombineNode:**
- Two inputs summed correctly (sample-by-sample addition)
- Three+ inputs summed correctly
- Single input passes through unchanged
- Zero inputs produces silence
- Auto-collapse behavior when last input removed (if enabled)

**VolumeNode:**
- Gain of 1.0 passes through unchanged
- Gain of 0.5 halves all samples
- Gain of 0.0 produces silence
- Interpolation: volume change ramps smoothly over frames

**OutputNode:**
- Returns accumulated input samples
- Works as graph evaluation root

**AudioGraph:**
- Evaluate traverses nodes in correct order (bottom-up from output)
- Deferred mutations: AddNode during evaluation applied next frame
- RemoveNode during evaluation applied next frame
- Cycle detection or prevention (optional, at least no infinite loop)
- Graph with no sources produces silence
- Complex graph: 3 sources -> 2 combines -> 1 master -> output

### Step 2: Float32 Pipeline Tests

- SDL3AudioSource.RenderFrames produces correct float32 stereo output
- Mono clip rendered as matching L/R channels
- Stereo clip passed through correctly
- Volume applied during render
- Finished source returns 0 frames
- Existing 3D tests still pass after refactor

### Step 3: Bus System Tests

**AudioBus:**
- Create bus with name and parent
- Bus volume applied to output
- Muted bus produces silence
- Effects chain order respected (effect A before B)
- AddEffect/InsertEffect/RemoveEffect/ClearEffects lifecycle
- Bus routes output to parent's CombineNode

**AudioBusSystem:**
- Master bus always exists, cannot be destroyed
- CreateBus with parent routes correctly
- CreateBus with null parent defaults to Master child
- GetBus by name returns correct bus
- DestroyBus re-routes children to destroyed bus's parent
- GetBusNames returns all registered names
- Duplicate bus name rejected

**Source routing:**
- Source with BusName="SFX" mixes into SFX bus
- Changing BusName at runtime re-routes
- Unknown bus name falls back to Master
- Multiple sources into same bus are summed

**AudioSubsystem migration:**
- SFXVolume getter/setter maps to SFX bus volume
- MusicVolume getter/setter maps to Music bus volume
- MasterVolume maps to Master bus volume

### Step 4: Effects Tests

**IAudioEffect / EffectNode:**
- EffectNode wraps IAudioEffect and calls Process
- Enabled=false bypasses processing (passthrough)
- Reset clears internal state
- Multiple effects in chain applied in order

**LowPassFilter:**
- High-frequency content attenuated above cutoff
- Low-frequency content passes through
- Cutoff at Nyquist is effectively passthrough
- Cutoff near 0 silences signal
- Reset zeroes filter state (no artifacts on restart)

**HighPassFilter:**
- Low-frequency content attenuated below cutoff
- High-frequency content passes through
- Mirror of LowPass behavior

### Step 5: Remaining Effects Tests

**ReverbEffect:**
- Dry input produces longer output (tail extends beyond input)
- WetDryMix=0 is passthrough
- WetDryMix=1 is fully wet
- Reset clears delay lines (no leftover tail)

**DelayEffect:**
- Output is input + delayed copy
- Delay time positions the echo correctly
- Feedback=0 produces single echo
- Feedback>0 produces repeating echoes (decaying)
- WetDryMix=0 is passthrough

**CompressorEffect:**
- Signal below threshold passes unchanged
- Signal above threshold reduced by ratio
- Attack time: compression ramps in (not instant)
- Release time: compression ramps out after signal drops
- MakeupGain boosts output

**ParametricEQ:**
- Flat gains (0 dB all bands) is passthrough
- Boosted band increases that frequency range
- Cut band decreases that frequency range
- Each band operates independently

**FadeEffect:**
- Linear fade from 1.0 to 0.0 over N frames
- Holds at target after completion
- Reset restarts the fade

### Step 6: Advanced Graph Node Tests

**PanNode:**
- Pan center (0.0) passes L/R equally
- Pan full left (-1.0) routes all to L channel
- Pan full right (1.0) routes all to R channel
- Constant-power panning: center is not -6dB (uses sin/cos)

**SplitNode:**
- Single output: passthrough
- Two outputs: both receive identical copy of input
- Removing one output doesn't affect the other
- Use case: dry/wet send routing verified end-to-end

**Side-chain scenario (integration test):**
- Music bus + Voice bus -> compressor on Music with side-chain from Voice
- When Voice signal is loud, Music volume ducks

### Step 7: Improved 3D Tests

**SoundAttenuator.CalculateGain:**
- Linear: gain=1 at MinDistance, gain=0 at MaxDistance, 0.5 at midpoint
- InverseDistance: gain=1 at MinDistance, decays as min/d
- Logarithmic: correct log curve values
- InverseDistanceSquared: correct squared falloff
- Distance < MinDistance clamps to gain=1
- Distance > MaxDistance clamps to gain=0

**Cone attenuation:**
- Inside inner cone: full volume
- Outside outer cone: ConeOuterGain applied
- Between inner/outer: interpolated
- ConeInnerAngle=360 disables cone (always full)

**Doppler:**
- Source moving toward listener: pitch increases
- Source moving away: pitch decreases
- DopplerFactor=0 disables effect
- Stationary source: no pitch change

**Distance low-pass:**
- At MinDistance: no filtering (full cutoff)
- At MaxDistance: MaxDistanceLowPassHz cutoff applied
- Between: interpolated cutoff frequency

### Step 8: Sound Cue Tests

**SoundCue.SelectEntry:**
- Sequential mode cycles through entries in order, wraps around
- Random mode respects weights (higher weight = more frequent over many calls)
- Shuffle mode avoids immediate repeats
- Returns null when MaxInstances reached
- Returns null when cooldown not elapsed
- NotifyInstanceStarted/Finished tracks count correctly

**Voice limiting:**
- MaxInstances=2: third play returns null
- After one finishes, next play succeeds
- Priority=0 instance stolen by Priority=1 when at limit

**Integration:**
- PlayCue selects entry, creates source, routes to correct bus
- PlayCue3D same but with position
- Volume/pitch randomization within specified ranges

### Test File Summary

**Sedulous.Audio.Tests/src/ (extend existing + new files):**
- AudioNodeTests.bf (base node wiring, mix-version caching)
- SourceNodeTests.bf (clip rendering, position, looping)
- CombineNodeTests.bf (summing, auto-collapse)
- VolumeNodeTests.bf (gain, interpolation)
- AudioGraphTests.bf (evaluation order, deferred mutations, complex graphs)
- AudioBusTests.bf (volume, mute, effects chain, parent routing)
- AudioBusSystemTests.bf (create, destroy, lookup, re-route)
- PanNodeTests.bf (stereo panning)
- SplitNodeTests.bf (send routing)
- SoundAttenuatorTests.bf (all curves, cone, doppler math)
- SoundCueTests.bf (selection modes, voice limiting, cooldown)

**Sedulous.Audio.Effects.Tests/src/ (NEW MODULE):**
- LowPassFilterTests.bf
- HighPassFilterTests.bf
- ReverbEffectTests.bf
- DelayEffectTests.bf
- CompressorEffectTests.bf
- ParametricEQTests.bf
- FadeEffectTests.bf
