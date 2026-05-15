namespace Sedulous.Particles;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Inspection;
using Sedulous.Resources;
using Sedulous.Serialization;
using static Sedulous.Resources.ResourceSerializerExtensions;

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
	[Property]
	public SimulationMode DesiredMode = .CPU;

	/// Actual simulation mode resolved after checking behavior support.
	public SimulationMode ResolvedMode { get; private set; } = .CPU;

	/// Simulation space.
	[Property]
	public ParticleSpace SimulationSpace = .World;

	/// Blend mode for rendering.
	[Property]
	public ParticleBlendMode BlendMode = .Alpha;

	/// Render mode (billboard type, mesh, trail).
	[Property]
	public ParticleRenderMode RenderMode = .Billboard;

	/// Whether to sort particles back-to-front for alpha blending.
	[Property]
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
	[Property, Range(0, 10000)]
	public float LODStartDistance = 0;

	/// Distance from camera where particles are fully culled. 0 = no cull.
	[Property, Range(0, 10000)]
	public float LODCullDistance = 0;

	/// Minimum spawn rate multiplier at LODCullDistance (before full cull).
	[Property, Range(0, 1)]
	public float LODMinRate = 0.1f;

	/// Sprite texture for this system, resolved by the engine layer into a
	/// MaterialInstance and bound per draw. The asset is the source of truth
	/// for visuals - the runtime no longer carries a separate per-component
	/// texture; rendering pulls from each system here.
	[Property]
	[ResourceRefType(".texture")]
	private ResourceRef mTextureRef ~ _.Dispose();

	public ResourceRef TextureRef => mTextureRef;

	public void SetTextureRef(ResourceRef @ref)
	{
		mTextureRef.Dispose();
		mTextureRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	/// Static mesh used when `RenderMode == .Mesh`. Resolved by the engine
	/// layer into a GPUMeshHandle; particles render as instances of this
	/// mesh transformed per-particle (position from streams, axis-angle
	/// rotation from Axis + Rotation streams, uniform scale from Size *
	/// MeshScale).
	[Property]
	[ResourceRefType(".mesh")]
	private ResourceRef mMeshRef ~ _.Dispose();

	public ResourceRef MeshRef => mMeshRef;

	public void SetMeshRef(ResourceRef @ref)
	{
		mMeshRef.Dispose();
		mMeshRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	/// Material applied to mesh particles. Required when `RenderMode ==
	/// .Mesh` - StaticMeshResource only carries geometry, not materials,
	/// so the system must specify one.
	[Property]
	[ResourceRefType(".material")]
	private ResourceRef mMaterialRef ~ _.Dispose();

	public ResourceRef MaterialRef => mMaterialRef;

	public void SetMaterialRef(ResourceRef @ref)
	{
		mMaterialRef.Dispose();
		mMaterialRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	/// Uniform scale multiplier applied on top of the per-particle Size
	/// when rendering as a mesh. The Size stream provides the per-particle
	/// magnitude; MeshScale lets the author tune the asset to its mesh
	/// (e.g. a 1-unit cube mesh with Size = 0.1 -> 0.1 final scale).
	[Property, Range(0, 100)]
	public float MeshScale = 1.0f;

	/// Round-trip the texture ref through `s`. Called from
	/// ParticleEffectSerializer so the field's owning class manages access.
	public void SerializeTexture(Serializer s)
	{
		s.ResourceRef("texture", ref mTextureRef);
	}

	/// Round-trip the mesh-particle refs (mesh, material, scale).
	public void SerializeMeshRefs(Serializer s)
	{
		s.ResourceRef("mesh", ref mMeshRef);
		s.ResourceRef("material", ref mMaterialRef);
		s.Float("meshScale", ref MeshScale);
	}

	/// Emitter - spawning logic.
	public ParticleEmitter Emitter { get; private set; } ~ delete _;

	/// Stream container - SoA data channels.
	public ParticleStreamContainer Streams { get; private set; } ~ delete _;

	/// World-space position (set by owner before Update).
	[HideInInspector]
	public Vector3 Position;

	/// Previous frame position (for velocity inheritance).
	[HideInInspector]
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

	/// Removes the initializer at the given index, deleting it. The system
	/// owns all initializers and must free the removed entry. Note that
	/// streams previously declared by the removed initializer are NOT
	/// removed - leaving them allocated is harmless (unused).
	public bool RemoveInitializer(int32 index)
	{
		if (index < 0 || index >= mInitializers.Count) return false;
		delete mInitializers[index];
		mInitializers.RemoveAt(index);
		return true;
	}

	/// Inserts an initializer at the given index. The system takes ownership.
	public bool InsertInitializer(int32 index, ParticleInitializer initializer)
	{
		if (initializer == null) return false;
		if (index < 0 || index > mInitializers.Count) return false;
		initializer.DeclareStreams(Streams);
		mInitializers.Insert(index, initializer);
		return true;
	}

	/// Moves an initializer from one index to another. Used for reordering.
	public bool MoveInitializer(int32 fromIndex, int32 toIndex)
	{
		if (fromIndex < 0 || fromIndex >= mInitializers.Count) return false;
		if (toIndex < 0 || toIndex >= mInitializers.Count) return false;
		if (fromIndex == toIndex) return true;
		let init = mInitializers[fromIndex];
		mInitializers.RemoveAt(fromIndex);
		mInitializers.Insert(toIndex, init);
		return true;
	}

	/// Removes the behavior at the given index, deleting it.
	public bool RemoveBehavior(int32 index)
	{
		if (index < 0 || index >= mBehaviors.Count) return false;
		delete mBehaviors[index];
		mBehaviors.RemoveAt(index);
		return true;
	}

	/// Inserts a behavior at the given index. The system takes ownership.
	/// Behaviors execute in list order - position matters for behaviors like
	/// VelocityIntegration which must run after force-applying behaviors.
	public bool InsertBehavior(int32 index, ParticleBehavior behavior)
	{
		if (behavior == null) return false;
		if (index < 0 || index > mBehaviors.Count) return false;
		behavior.DeclareStreams(Streams);
		mBehaviors.Insert(index, behavior);
		return true;
	}

	/// Moves a behavior from one index to another. Critical for reordering
	/// effects that depend on behavior execution order.
	public bool MoveBehavior(int32 fromIndex, int32 toIndex)
	{
		if (fromIndex < 0 || fromIndex >= mBehaviors.Count) return false;
		if (toIndex < 0 || toIndex >= mBehaviors.Count) return false;
		if (fromIndex == toIndex) return true;
		let beh = mBehaviors[fromIndex];
		mBehaviors.RemoveAt(fromIndex);
		mBehaviors.Insert(toIndex, beh);
		return true;
	}

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
