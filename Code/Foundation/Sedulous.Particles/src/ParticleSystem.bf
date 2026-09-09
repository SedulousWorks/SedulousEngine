using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Particles;

/// One emitter's worth of particles: the timing, the modules, the streams and the per frame
/// loop.
///
/// The system owns its modules and its streams. Module order MATTERS in both lists, so an
/// editor reordering them changes the result.
class ParticleSystem
{
	/// The cap on events reported in one frame. A bound rather than a growing list, because
	/// the events feed sub emitters and an unbounded burst of them is an unbounded burst of
	/// spawns.
	public const int32 MaxEventsPerFrame = 64;

	private const uint64 cDefaultSeed = 0x9E3779B97F4A7C15UL;

	public String Name = new .() ~ delete _;
	public SimulationMode DesiredMode = .CPU;
	public ParticleSpace SimulationSpace = .World;
	public ParticleBlendMode BlendMode = .Alpha;
	public ParticleRenderMode RenderMode = .Billboard;

	/// The billboard sheet, as an OPAQUE cooked resource id. The runtime library does not
	/// resolve it: the resource factory binds it, and an empty id is untextured.
	public Guid TextureRef = .Empty;
	/// The per particle mesh for a mesh mode system, again an opaque cooked resource id.
	public Guid MeshRef = .Empty;
	public float MeshScale = 1.0f;
	/// Per submesh materials for a mesh mode system, indexed by the submesh's material index.
	/// Slot nought doubles as the whole mesh material, so a single material mesh needs one
	/// entry.
	public List<Guid> MaterialRefs = new .() ~ delete _;

	public bool SortParticles = false;
	/// Fades a billboard where it approaches the surface behind it, over SoftDistance world
	/// units. Read every frame, so it toggles live.
	public bool SoftParticles = true;
	public float SoftDistance = 0.6f;

	public TrailSettings Trail = .Default();
	public FlipbookSettings Flipbook = .();

	/// Simulated once on the first update, so the effect starts already running rather than
	/// visibly filling up.
	public float PrewarmTime = 0.0f;

	// Distance based rate falloff. Nought on both disables it.
	public float LodStartDistance = 0.0f;
	public float LodCullDistance = 0.0f;
	public float LodMinRate = 0.1f;

	// Where the emitter is, and where it was, which is what gives it a velocity.
	public Float3 Position = .(0, 0, 0);
	public Float3 PrevPosition = .(0, 0, 0);

	public ParticleEmitter Emitter = new .() ~ delete _;

	private int32 mMaxParticles;
	private ParticleStreamContainer mStreams ~ delete _;
	private List<ParticleInitializer> mInitializers = new .() ~ DeleteContainerAndItems!(_);
	private List<ParticleBehavior> mBehaviors = new .() ~ DeleteContainerAndItems!(_);
	private ParticleSimulator mSimulator = new CPUSimulator() ~ delete _;

	// Per particle trail state, parallel to the streams, and one flat ring buffer per
	// particle at [index * TrailMaxPoints + slot].
	private List<ParticleTrailState> mTrailStates = new .() ~ delete _;
	private List<TrailPoint> mTrailPoints = new .() ~ delete _;
	private int32 mTrailCapacityPoints = 0;

	private Sedulous.Core.Random mRandom;
	private uint64 mSeed = cDefaultSeed;
	private float mTotalTime = 0.0f;
	private float mLodRateMultiplier = 1.0f;
	private bool mPrewarmed = false;
	private SimulationMode mResolvedMode = .CPU;

	private ParticleEvent[MaxEventsPerFrame] mDeathEvents = .();
	private ParticleEvent[MaxEventsPerFrame] mBirthEvents = .();
	private int32 mDeathCount = 0;
	private int32 mBirthCount = 0;

	public this(int32 maxParticles, uint64 seed = cDefaultSeed)
	{
		mMaxParticles = maxParticles;
		mStreams = new .(maxParticles);
		mSeed = seed;
		mRandom = .(seed);
	}

	/// Reseeds for deterministic playback. Reset re-applies this seed, so the same seed and
	/// the same inputs give the same particles.
	public void SetSeed(uint64 seed)
	{
		mSeed = seed;
		mRandom = .(seed);
	}

	public uint64 Seed => mSeed;

	public int32 MaxParticles => mMaxParticles;
	public int32 AliveCount => mStreams.AliveCount;
	public float TotalTime => mTotalTime;
	public float LodRateMultiplier => mLodRateMultiplier;
	/// Culled AND drained: a system still holding particles has to keep simulating them out.
	public bool IsLodCulled => (mLodRateMultiplier <= 0.0f) && (mStreams.AliveCount == 0);
	public ParticleStreamContainer Streams => mStreams;
	public SimulationMode ResolvedMode => mResolvedMode;

	/// The ring length the trail points were allocated for. A point is at
	/// [particleIndex * TrailMaxPoints + slot].
	public int32 TrailMaxPoints => mTrailCapacityPoints;
	public Span<ParticleTrailState> TrailStates => .(mTrailStates.Ptr,
		Min(mStreams.AliveCount, mTrailStates.Count));
	public Span<TrailPoint> TrailPoints => mTrailPoints;

	public Span<ParticleEvent> DeathEvents => .(&mDeathEvents[0], mDeathCount);
	public Span<ParticleEvent> BirthEvents => .(&mBirthEvents[0], mBirthCount);

	// ---- Authoring -------------------------------------------------------------------------

	/// Creates a module, declares its streams and takes ownership. The caller gets a borrowed
	/// reference to configure.
	public T AddInitializer<T>() where T : ParticleInitializer where T : new, delete
	{
		let module = new T();
		module.DeclareStreams(mStreams);
		mInitializers.Add(module);
		return module;
	}

	public T AddBehavior<T>() where T : ParticleBehavior where T : new, delete
	{
		let module = new T();
		module.DeclareStreams(mStreams);
		mBehaviors.Add(module);
		return module;
	}

	/// Takes a module built elsewhere, which is what the cooked resource factory hands over.
	/// OWNERSHIP TRANSFERS.
	public void AddInitializer(ParticleInitializer module)
	{
		if (module == null)
			return;
		module.DeclareStreams(mStreams);
		mInitializers.Add(module);
	}

	public void AddBehavior(ParticleBehavior module)
	{
		if (module == null)
			return;
		module.DeclareStreams(mStreams);
		mBehaviors.Add(module);
	}

	/// Drops a module. The streams it declared STAY allocated, which is harmless: a module
	/// never removes a channel another one is reading.
	public void RemoveInitializer(int32 index)
	{
		if ((index >= 0) && (index < InitializerCount))
		{
			let module = mInitializers[index];
			mInitializers.RemoveAt(index);
			delete module;
		}
	}

	public void RemoveBehavior(int32 index)
	{
		if ((index >= 0) && (index < BehaviorCount))
		{
			let module = mBehaviors[index];
			mBehaviors.RemoveAt(index);
			delete module;
		}
	}

	/// Reorders a module. Order is the authored result: a colour initializer has to run
	/// before a colour over lifetime tint, and drag before a force is not drag after it.
	public void MoveInitializer(int32 from, int32 to) => MoveInList(mInitializers, from, to);
	public void MoveBehavior(int32 from, int32 to) => MoveInList(mBehaviors, from, to);

	/// Changes the particle budget, which RESTARTS the effect: the streams are rebuilt at the
	/// new capacity and every module re-declares into them. The trail buffers heal themselves
	/// on the next step.
	public void SetMaxParticles(int32 newMax)
	{
		let capped = Max(newMax, 1);
		if (capped == mMaxParticles)
			return;

		mMaxParticles = capped;
		delete mStreams;
		mStreams = new .(capped);
		for (let module in mInitializers)
			module.DeclareStreams(mStreams);
		for (let module in mBehaviors)
			module.DeclareStreams(mStreams);
		mStreams.AliveCount = 0;
		mTrailStates.Clear();
		mTrailPoints.Clear();
		mTrailCapacityPoints = 0;
	}

	public int32 InitializerCount => (int32)mInitializers.Count;
	public int32 BehaviorCount => (int32)mBehaviors.Count;

	public ParticleInitializer GetInitializer(int32 index) =>
		((index >= 0) && (index < InitializerCount)) ? mInitializers[index] : null;

	public ParticleBehavior GetBehavior(int32 index) =>
		((index >= 0) && (index < BehaviorCount)) ? mBehaviors[index] : null;

	// ---- Simulation ------------------------------------------------------------------------

	/// Decides where this system runs. The decision is RECORDED even though everything
	/// simulates on the CPU today, so the GPU simulator has something to read when it lands.
	public void ResolveSimulationMode()
	{
		switch (DesiredMode)
		{
		case .CPU:
			mResolvedMode = .CPU;

		case .GPU:
			mResolvedMode = .GPU;
			// One CPU-only behaviour takes the whole system back to the CPU: the streams are
			// shared, so it cannot be split.
			for (let behavior in mBehaviors)
			{
				if (behavior.Support == .CPUOnly)
				{
					mResolvedMode = .CPU;
					break;
				}
			}

		case .Auto:
			var allSupportGpu = true;
			for (let behavior in mBehaviors)
			{
				if (behavior.Support == .CPUOnly)
				{
					allSupportGpu = false;
					break;
				}
			}
			// Small systems stay on the CPU whatever they support: the dispatch would cost
			// more than the work.
			mResolvedMode = (allSupportGpu && (mMaxParticles > 1024)) ? .GPU : .CPU;
		}
	}

	/// The per frame entry point. The first call runs the prewarm.
	public void Update(float deltaTime, Float3 cameraPosition = .(0, 0, 0))
	{
		if (!mPrewarmed)
		{
			mPrewarmed = true;
			if (PrewarmTime > 0.0f)
			{
				// A fixed thirtieth of a second, so a prewarm gives the same result whatever
				// the frame the effect happened to start on.
				let step = 1.0f / 30.0f;
				var remaining = PrewarmTime;
				while (remaining > 1.0e-4f)
				{
					let slice = Min(step, remaining);
					Step(slice, cameraPosition);
					remaining -= slice;
				}
			}
		}
		Step(deltaTime, cameraPosition);
	}

	/// One step, in ORDER: time, events cleared, level of detail, spawn, behaviours,
	/// integrate, record trails, collect deaths, compact.
	///
	/// Deaths are collected BEFORE compaction, because compaction is what removes the dead
	/// particles the events describe.
	public void Step(float deltaTime, Float3 cameraPosition = .(0, 0, 0))
	{
		mTotalTime += deltaTime;
		mDeathCount = 0;
		mBirthCount = 0;

		mLodRateMultiplier = CalculateLodMultiplier(cameraPosition);
		var spawnCount = Emitter.CalculateSpawnCount(deltaTime);
		spawnCount = (mLodRateMultiplier <= 0.0f)
			? 0
			: (int32)((float)spawnCount * mLodRateMultiplier);
		SpawnParticles(spawnCount);

		var context = ParticleUpdateContext();
		context.TotalTime = mTotalTime;
		context.DeltaTime = deltaTime;
		context.EmitterPosition = Position;
		context.EmitterVelocity = EmitterVelocity;
		context.Rng = &mRandom;
		mSimulator.Simulate(mStreams, mBehaviors, ref context);

		IntegrateVelocityAndAge(deltaTime);

		// After integration, so a point records where the particle actually ended up.
		if (Trail.IsActive)
			RecordTrailPoints();

		CollectDeathEvents();

		if (Trail.IsActive)
			CompactDeadWithTrails();
		else
			mStreams.CompactDead();

		PrevPosition = Position;
	}

	/// Spawns through the emitter's own timing.
	public void SpawnParticles(int32 count) => SpawnInternal(count, false, .Zero, false, .Zero,
		.(1, 1, 1, 1));

	/// Spawns now, bypassing the timing. A sub emitter birth that inherits nothing.
	public void SpawnImmediate(int32 count) => SpawnInternal(count, false, .Zero, false, .Zero,
		.(1, 1, 1, 1));

	/// Spawns at a point, for a sub emitter. The inherited velocity is ADDED to whatever the
	/// initializers produced and the inherited colour MODULATES it, so both are no-ops at
	/// their defaults and the caller passes an already factored parent value.
	public void SpawnAt(int32 count, Float3 spawnPosition, Float3 inheritedVelocity = .(0, 0, 0),
		Float4 inheritedColor = .(1, 1, 1, 1))
	{
		SpawnInternal(count, true, spawnPosition, true, inheritedVelocity, inheritedColor);
	}

	/// Empties the system and rewinds it to its seed.
	public void Reset()
	{
		mStreams.AliveCount = 0;
		Emitter.Reset();
		mTotalTime = 0.0f;
		mPrewarmed = false;
		mRandom = .(mSeed);
	}

	// ---- Internals -------------------------------------------------------------------------

	/// The emitter's own velocity, which a velocity initializer can inherit.
	///
	/// Divided by the TOTAL time rather than the step, which is what Sedulous shipped and
	/// what Raptor kept: the inherited velocity therefore fades as the effect runs. Kept as
	/// it is because content is authored against it.
	private Float3 EmitterVelocity
	{
		get
		{
			// Local space stores particles relative to the emitter and re-bases them at
			// extract, so the emitter contributes nothing at spawn.
			if (SimulationSpace == .Local)
				return .Zero;
			return (Position - PrevPosition) / Max(mTotalTime, 0.001f);
		}
	}

	private static void MoveInList<T>(List<T> list, int32 from, int32 to)
	{
		let count = (int32)list.Count;
		if ((from < 0) || (from >= count) || (to < 0) || (to >= count) || (from == to))
			return;

		// `to` is the FINAL index. After the removal the list is one shorter, and inserting
		// at `to` lands the item exactly there, which is valid because to <= count - 1.
		let item = list[from];
		list.RemoveAt(from);
		list.Insert(to, item);
	}

	private void SpawnInternal(int32 count, bool overridePosition, Float3 spawnPosition,
		bool inherit, Float3 inheritedVelocity, Float4 inheritedColor)
	{
		if (count <= 0)
			return;

		let local = (SimulationSpace == .Local);

		var context = ParticleUpdateContext();
		context.TotalTime = mTotalTime;
		context.EmitterPosition = local ? Float3.Zero : Position;
		context.EmitterVelocity = EmitterVelocity;
		context.Rng = &mRandom;

		for (int32 n = 0; n < count; n++)
		{
			// The budget is a hard cap: the rest of the burst is DROPPED rather than
			// overwriting live particles.
			if (mStreams.AliveCount >= mMaxParticles)
				break;

			let index = mStreams.AliveCount;
			mStreams.AliveCount++;

			for (let module in mInitializers)
				module.Initialize(mStreams, index, ref context);

			if (overridePosition)
				mStreams.Positions[index] = spawnPosition;

			if (inherit)
			{
				if (mStreams.Velocities != null)
					mStreams.Velocities[index] += inheritedVelocity;
				if (mStreams.Colors != null)
				{
					let own = mStreams.Colors[index];
					mStreams.Colors[index] = .(own.X * inheritedColor.X, own.Y * inheritedColor.Y,
						own.Z * inheritedColor.Z, own.W * inheritedColor.W);
				}
			}

			RecordBirthEvent(index);
		}
	}

	/// The hardcoded finalize: position follows velocity, and everything ages. Not a
	/// behaviour, so a behaviour's write to velocity always lands before the move it causes.
	private void IntegrateVelocityAndAge(float deltaTime)
	{
		let positions = mStreams.Positions;
		let velocities = mStreams.Velocities;
		let ages = mStreams.Ages;
		let applyVelocity = (positions != null) && (velocities != null);

		for (int32 i = 0; i < mStreams.AliveCount; i++)
		{
			if (applyVelocity)
				positions[i] += velocities[i] * deltaTime;
			if (ages != null)
				ages[i] += deltaTime;
		}
	}

	/// Sizes the trail buffers to the current budget and ring length. A resize CLEARS the
	/// trails, because the ring stride changes and the old points no longer mean anything.
	private void EnsureTrailStorage()
	{
		if ((mTrailCapacityPoints == Trail.MaxPoints) && (mTrailStates.Count == mMaxParticles))
			return;

		mTrailStates.Resize(mMaxParticles);
		mTrailPoints.Resize(mMaxParticles * Trail.MaxPoints);
		mTrailCapacityPoints = Trail.MaxPoints;
		for (int i = 0; i < mTrailStates.Count; i++)
			mTrailStates[i].Clear();
	}

	/// Records each live particle's position into its ring, when enough time has passed OR it
	/// has moved far enough. The distance test is what keeps a fast particle's ribbon smooth
	/// between the timed samples.
	private void RecordTrailPoints()
	{
		EnsureTrailStorage();

		let positions = mStreams.Positions;
		if (positions == null)
			return;
		let colors = mStreams.Colors;
		let ringLength = Trail.MaxPoints;

		for (int32 i = 0; i < mStreams.AliveCount; i++)
		{
			var state = ref mTrailStates[i];
			let position = positions[i];

			let first = (state.Count == 0);
			if (!first)
			{
				let byTime = (mTotalTime - state.LastRecordTime) >= Trail.RecordInterval;
				let byDistance = Length(position - state.LastPosition) >= Trail.MinVertexDistance;
				if (!byTime && !byDistance)
					continue;
				state.Head = (state.Head + 1) % ringLength;
			}

			var point = ref mTrailPoints[i * ringLength + state.Head];
			point.Position = position;
			point.Width = Trail.WidthStart;
			point.Color = (Trail.UseParticleColor && (colors != null)) ? colors[i]
				: Trail.TrailColor;
			point.RecordTime = mTotalTime;

			// Saturates at the ring length: past that the buffer is full and the head is
			// overwriting the oldest point.
			if (state.Count < ringLength)
				state.Count++;
			state.LastRecordTime = mTotalTime;
			state.LastPosition = position;
		}
	}

	/// Compaction that carries the trail with the particle. The streams' own swap remove
	/// moves a particle into a dead slot, so its ring has to move with it or the ribbon would
	/// jump to whoever used to be there.
	private void CompactDeadWithTrails()
	{
		let ages = mStreams.Ages;
		let lifetimes = mStreams.Lifetimes;
		if ((ages == null) || (lifetimes == null))
			return;

		EnsureTrailStorage();
		let ringLength = Trail.MaxPoints;

		for (int32 i = mStreams.AliveCount - 1; i >= 0; i--)
		{
			if (ages[i] < lifetimes[i])
				continue;

			let last = mStreams.AliveCount - 1;
			if (i < last)
			{
				mTrailStates[i] = mTrailStates[last];
				for (int32 p = 0; p < ringLength; p++)
					mTrailPoints[i * ringLength + p] = mTrailPoints[last * ringLength + p];
			}
			mTrailStates[last].Clear();
			mStreams.SwapRemove(i);
		}
	}

	private void RecordBirthEvent(int32 index)
	{
		if (mBirthCount >= MaxEventsPerFrame)
			return;

		var event = ParticleEvent();
		event.Position = mStreams.Positions[index];
		if (mStreams.Velocities != null)
			event.Velocity = mStreams.Velocities[index];
		if (mStreams.Colors != null)
			event.Color = mStreams.Colors[index];

		mBirthEvents[mBirthCount] = event;
		mBirthCount++;
	}

	private void CollectDeathEvents()
	{
		let ages = mStreams.Ages;
		let lifetimes = mStreams.Lifetimes;
		if ((ages == null) || (lifetimes == null))
			return;

		let positions = mStreams.Positions;
		let velocities = mStreams.Velocities;
		let colors = mStreams.Colors;

		for (int32 i = 0; i < mStreams.AliveCount; i++)
		{
			if (ages[i] < lifetimes[i])
				continue;
			if (mDeathCount >= MaxEventsPerFrame)
				break;

			var event = ParticleEvent();
			if (positions != null)
				event.Position = positions[i];
			if (velocities != null)
				event.Velocity = velocities[i];
			if (colors != null)
				event.Color = colors[i];

			mDeathEvents[mDeathCount] = event;
			mDeathCount++;
		}
	}

	/// One at full rate, nought culled, and a linear falloff to LodMinRate between the two
	/// distances.
	private float CalculateLodMultiplier(Float3 cameraPosition)
	{
		if ((LodStartDistance <= 0.0f) && (LodCullDistance <= 0.0f))
			return 1.0f;

		let distance = Length(Position - cameraPosition);
		if (distance <= LodStartDistance)
			return 1.0f;
		if ((LodCullDistance > 0.0f) && (distance >= LodCullDistance))
			return 0.0f;
		// An inverted or degenerate band has no falloff to interpolate across.
		if (LodCullDistance <= LodStartDistance)
			return 1.0f;

		let t = (distance - LodStartDistance) / (LodCullDistance - LodStartDistance);
		return Max(1.0f - t * (1.0f - LodMinRate), LodMinRate);
	}
}
