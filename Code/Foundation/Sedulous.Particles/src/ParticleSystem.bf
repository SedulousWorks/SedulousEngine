namespace Sedulous.Particles;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// A particle system - owns an emitter, behaviors, initializers, streams,
/// and a simulation backend. This is the per-system class from the proposal:
///
///   ParticleEffect
///     └── ParticleSystem
///           ├── Emitter        - spawn rules
///           ├── Behaviors[]    - per-frame update rules
///           ├── Initializers[] - per-spawn setup
///           ├── Streams        - SoA data channels
///           └── Simulator      - CPU or GPU backend
///
/// The ParticleSystem picks its simulator based on SimulationMode and
/// validates that all behaviors support the chosen backend.
public class ParticleSystem
{
	/// Maximum number of alive particles.
	public int32 MaxParticles { get; private set; }

	/// Desired simulation mode (CPU, GPU, or Auto).
	public SimulationMode DesiredMode = .CPU;

	/// Actual simulation mode resolved after checking behavior support.
	public SimulationMode ResolvedMode { get; private set; } = .CPU;

	/// Simulation space.
	public ParticleSpace SimulationSpace = .World;

	/// Blend mode for rendering.
	public ParticleBlendMode BlendMode = .Alpha;

	/// Render mode (billboard type, mesh, trail).
	public ParticleRenderMode RenderMode = .Billboard;

	/// Whether to sort particles back-to-front for alpha blending.
	public bool SortParticles = false;

	/// Trail configuration (only used when RenderMode == .Trail).
	public TrailSettings Trail = .Default();

	// --- Trail state ---

	/// Per-particle trail states (ring buffer metadata). Allocated when trails are active.
	public ParticleTrailState[] TrailStates ~ delete _;

	/// Flat array of trail points. Indexed as [particleIndex * Trail.MaxPoints + pointIndex].
	public TrailPoint[] TrailPoints ~ delete _;

	// --- LOD ---

	/// Distance from camera where LOD reduction begins. 0 = no LOD.
	public float LODStartDistance = 0;

	/// Distance from camera where particles are fully culled. 0 = no cull.
	public float LODCullDistance = 0;

	/// Minimum spawn rate multiplier at LODCullDistance (before full cull).
	public float LODMinRate = 0.1f;

	/// Emitter - spawning logic.
	public ParticleEmitter Emitter { get; private set; } ~ delete _;

	/// Stream container - SoA data channels.
	public ParticleStreamContainer Streams { get; private set; } ~ delete _;

	/// World-space position (set by owner before Update).
	public Vector3 Position;

	/// Previous frame position (for velocity inheritance).
	public Vector3 PrevPosition;

	/// Total elapsed simulation time.
	public float TotalTime { get; private set; }

	/// Number of alive particles.
	public int32 AliveCount => Streams.AliveCount;

	/// Current LOD rate multiplier (1.0 = full rate, 0.0 = culled).
	public float LODRateMultiplier { get; private set; } = 1.0f;

	/// Whether this system is fully LOD-culled (no alive particles and zero rate).
	public bool IsLODCulled => LODRateMultiplier <= 0 && AliveCount == 0;

	// --- Event buffers (for sub-emitter routing) ---

	private ParticleEvent[] mDeathEvents ~ delete _;
	private int32 mDeathCount = 0;
	private ParticleEvent[] mBirthEvents ~ delete _;
	private int32 mBirthCount = 0;
	private const int32 MaxEventsPerFrame = 64;

	/// Death events from this frame (valid until next Update).
	public Span<ParticleEvent> DeathEvents => .(mDeathEvents, 0, mDeathCount);

	/// Birth events from this frame (valid until next Update).
	public Span<ParticleEvent> BirthEvents => .(mBirthEvents, 0, mBirthCount);

	// --- Internal ---

	private List<ParticleInitializer> mInitializers = new .() ~ DeleteContainerAndItems!(_);
	private List<ParticleBehavior> mBehaviors = new .() ~ DeleteContainerAndItems!(_);
	private ParticleSimulator mSimulator ~ delete _;
	private Random mRandom = new .() ~ delete _;

	public this(int32 maxParticles)
	{
		MaxParticles = maxParticles;
		Emitter = new ParticleEmitter();
		Streams = new ParticleStreamContainer(maxParticles);
		mSimulator = new CPUSimulator();
		mDeathEvents = new ParticleEvent[MaxEventsPerFrame];
		mBirthEvents = new ParticleEvent[MaxEventsPerFrame];
	}

	// ==================== Configuration ====================

	/// Adds an initializer. The system takes ownership.
	public void AddInitializer(ParticleInitializer initializer)
	{
		initializer.DeclareStreams(Streams);
		mInitializers.Add(initializer);
	}

	/// Adds a behavior. The system takes ownership.
	/// Behaviors execute in the order they are added.
	public void AddBehavior(ParticleBehavior behavior)
	{
		behavior.DeclareStreams(Streams);
		mBehaviors.Add(behavior);
	}

	/// Gets the list of initializers.
	public Span<ParticleInitializer> Initializers => mInitializers;

	/// Gets the list of behaviors.
	public Span<ParticleBehavior> Behaviors => mBehaviors;

	/// Resolves the simulation mode and creates the appropriate simulator.
	/// Call after all behaviors are added.
	public void ResolveSimulationMode()
	{
		switch (DesiredMode)
		{
		case .CPU:
			ResolvedMode = .CPU;
		case .GPU:
			// Check if all behaviors support GPU
			for (let b in mBehaviors)
			{
				if (b.Support == .CPUOnly)
				{
					ResolvedMode = .CPU; // Fall back
					break;
				}
			}
			ResolvedMode = .GPU;
		case .Auto:
			// GPU if all behaviors support it and particle count is high enough
			bool allSupportGPU = true;
			for (let b in mBehaviors)
			{
				if (b.Support == .CPUOnly)
				{
					allSupportGPU = false;
					break;
				}
			}
			ResolvedMode = (allSupportGPU && MaxParticles > 1024) ? .GPU : .CPU;
		}

		// Create appropriate simulator
		delete mSimulator;
		switch (ResolvedMode)
		{
		case .CPU, .Auto:
			mSimulator = new CPUSimulator();
		case .GPU:
			mSimulator = new GPUSimulator();
		}
	}

	// ==================== Simulation ====================

	/// Advances the system by deltaTime seconds.
	/// cameraPos is used for LOD distance culling (pass .Zero to disable).
	public void Update(float deltaTime, Vector3 cameraPos = .Zero)
	{
		TotalTime += deltaTime;

		// Reset event buffers
		mDeathCount = 0;
		mBirthCount = 0;

		// Compute LOD rate multiplier
		LODRateMultiplier = CalculateLODMultiplier(cameraPos);

		// Spawn new particles (scaled by LOD)
		var spawnCount = Emitter.CalculateSpawnCount(deltaTime);
		if (LODRateMultiplier < 1.0f && LODRateMultiplier > 0)
			spawnCount = (int32)(spawnCount * LODRateMultiplier);
		else if (LODRateMultiplier <= 0)
			spawnCount = 0;
		SpawnParticles(spawnCount);

		// Build update context
		var ctx = ParticleUpdateContext()
		{
			TotalTime = TotalTime,
			DeltaTime = deltaTime,
			EmitterPosition = Position,
			Rng = mRandom
		};

		// Run simulation
		mSimulator.Simulate(Streams, mBehaviors, ref ctx);

		// Record trail points after simulation (positions have been updated)
		if (Trail.IsActive)
			RecordTrailPoints();

		// Collect death events before compaction
		CollectDeathEvents();

		// Remove dead particles (with trail state compaction)
		CompactDeadWithTrails();

		// Save position for next frame
		PrevPosition = Position;
	}

	/// Spawns particles immediately, bypassing emission timing.
	public void SpawnImmediate(int32 count)
	{
		SpawnParticles(count);
	}

	/// Spawns particles at a specific world position, overriding the PositionInitializer.
	/// Used by sub-emitter routing to spawn child particles at the parent event location.
	public void SpawnAt(int32 count, Vector3 position, Vector3 inheritedVelocity = .Zero, Vector4 inheritedColor = .(1,1,1,1))
	{
		for (int32 i = 0; i < count; i++)
		{
			if (Streams.AliveCount >= MaxParticles)
				break;

			let index = Streams.AliveCount;
			Streams.AliveCount++;

			// Run all initializers first
			for (let initializer in mInitializers)
				initializer.Initialize(Streams, index, mRandom);

			// Override position to the event location
			Streams.Positions[index] = position;
		}
	}

	/// Resets - kills all particles and restarts emission.
	public void Reset()
	{
		Streams.AliveCount = 0;
		Emitter.Reset();
		TotalTime = 0;
	}

	/// Whether this system is GPU-simulated.
	public bool IsGPU => ResolvedMode == .GPU;

	// ==================== Internal ====================

	private void SpawnParticles(int32 count)
	{
		if (count <= 0) return;

		// Push system state to initializers before spawning
		let emitterVelocity = (TotalTime > 0) ? (Position - PrevPosition) / Math.Max(TotalTime, 0.001f) : Vector3.Zero;
		for (let init in mInitializers)
		{
			if (let posInit = init as PositionInitializer)
				posInit.EmitterPosition = Position;
			else if (let velInit = init as VelocityInitializer)
				velInit.EmitterVelocity = emitterVelocity;
		}

		for (int32 i = 0; i < count; i++)
		{
			if (Streams.AliveCount >= MaxParticles)
				break;

			let index = Streams.AliveCount;
			Streams.AliveCount++;

			for (let initializer in mInitializers)
				initializer.Initialize(Streams, index, mRandom);

			// Record birth event
			if (mBirthCount < MaxEventsPerFrame)
			{
				mBirthEvents[mBirthCount] = .()
				{
					Position = Streams.Positions[index],
					Velocity = (Streams.Velocities != null) ? Streams.Velocities[index] : .Zero,
					Color = (Streams.Colors != null) ? Streams.Colors[index] : .(1, 1, 1, 1)
				};
				mBirthCount++;
			}
		}
	}

	/// Scans for particles that will die this frame and records death events.
	private void CollectDeathEvents()
	{
		let ages = Streams.Ages;
		let lifetimes = Streams.Lifetimes;
		if (ages == null || lifetimes == null) return;

		for (int32 i = 0; i < Streams.AliveCount; i++)
		{
			if (ages[i] >= lifetimes[i])
			{
				if (mDeathCount < MaxEventsPerFrame)
				{
					mDeathEvents[mDeathCount] = .()
					{
						Position = Streams.Positions[i],
						Velocity = (Streams.Velocities != null) ? Streams.Velocities[i] : .Zero,
						Color = (Streams.Colors != null) ? Streams.Colors[i] : .(1, 1, 1, 1)
					};
					mDeathCount++;
				}
			}
		}
	}

	private float CalculateLODMultiplier(Vector3 cameraPos)
	{
		// No LOD configured
		if (LODStartDistance <= 0 && LODCullDistance <= 0)
			return 1.0f;

		let diff = Position - cameraPos;
		let dist = diff.Length();

		// Before start distance: full rate
		if (LODStartDistance > 0 && dist <= LODStartDistance)
			return 1.0f;

		// Beyond cull distance: fully culled
		if (LODCullDistance > 0 && dist >= LODCullDistance)
			return 0.0f;

		// Between start and cull: linear interpolation
		if (LODStartDistance > 0 && LODCullDistance > LODStartDistance)
		{
			let range = LODCullDistance - LODStartDistance;
			let t = (dist - LODStartDistance) / range;
			return Math.Max(1.0f - t * (1.0f - LODMinRate), LODMinRate);
		}

		return 1.0f;
	}

	// ==================== Trail Management ====================

	/// Initializes trail storage. Called lazily on first use.
	private void EnsureTrailStorage()
	{
		if (TrailStates != null) return;

		let maxPoints = Math.Max(Trail.MaxPoints, 2);
		TrailStates = new ParticleTrailState[MaxParticles];
		TrailPoints = new TrailPoint[MaxParticles * maxPoints];
	}

	/// Records trail points for all alive particles.
	private void RecordTrailPoints()
	{
		EnsureTrailStorage();

		let maxPoints = Math.Max(Trail.MaxPoints, 2);
		let positions = Streams.Positions;
		let colors = Streams.Colors;
		if (positions == null) return;

		for (int32 i = 0; i < Streams.AliveCount; i++)
		{
			var state = ref TrailStates[i];

			// Check time since last record
			let timeSince = TotalTime - state.LastRecordTime;
			if (timeSince < Trail.RecordInterval && state.Count > 0)
				continue;

			// Check minimum distance
			if (state.Count > 0)
			{
				let diff = positions[i] - state.LastPosition;
				if (Vector3.Dot(diff, diff) < Trail.MinVertexDistance * Trail.MinVertexDistance)
					continue;
			}

			// Compute width from particle life ratio
			let lifeRatio = Streams.GetLifeRatio(i);
			let width = Trail.WidthStart * (1.0f - lifeRatio) + Trail.WidthEnd * lifeRatio;

			// Get particle color
			Color pointColor;
			if (Trail.UseParticleColor && colors != null)
			{
				let c = colors[i];
				pointColor = Color(c.X, c.Y, c.Z, c.W);
			}
			else
			{
				let c = Trail.TrailColor;
				pointColor = Color(c.X, c.Y, c.Z, c.W);
			}

			// Record point in ring buffer
			let pointOffset = i * maxPoints + state.Head;
			TrailPoints[pointOffset] = .()
			{
				Position = positions[i],
				Width = width,
				Color = pointColor,
				RecordTime = TotalTime
			};

			state.Head = (state.Head + 1) % maxPoints;
			if (state.Count < maxPoints)
				state.Count++;

			state.LastRecordTime = TotalTime;
			state.LastPosition = positions[i];
		}
	}

	/// Removes dead particles and compacts trail state alongside stream data.
	private void CompactDeadWithTrails()
	{
		let ages = Streams.Ages;
		let lifetimes = Streams.Lifetimes;
		if (ages == null || lifetimes == null) return;

		let hasTrails = Trail.IsActive && TrailStates != null;
		let maxPoints = hasTrails ? Math.Max(Trail.MaxPoints, 2) : 0;

		for (int32 i = Streams.AliveCount - 1; i >= 0; i--)
		{
			if (ages[i] >= lifetimes[i])
			{
				let last = Streams.AliveCount - 1;

				// Compact trail state before stream swap-remove
				if (hasTrails && i < last)
				{
					TrailStates[i] = TrailStates[last];
					let srcOffset = last * maxPoints;
					let dstOffset = i * maxPoints;
					for (int32 t = 0; t < maxPoints; t++)
						TrailPoints[dstOffset + t] = TrailPoints[srcOffset + t];
				}
				if (hasTrails)
					TrailStates[last].Clear();

				Streams.SwapRemove(i);
			}
		}
	}
}
