using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Particles;
using Sedulous.Particles.Resource;
using Sedulous.Profiler;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Scene;

namespace Sedulous.Engine.Particles;

/// The pool of particle effects, which is both a scene system and a render data provider.
///
/// It advances every instance in the animation phase, before extraction, and then packs what
/// is alive into render data when its scene's turn to extract comes.
class ParticleEffectComponentManager : ResourceBindingComponentManager<ParticleEffectComponent>,
	IRenderDataProvider
{
	/// The most point lights ONE light mode system contributes in a frame.
	///
	/// Kept well above a light system's usual alive count so the stride stays one and every
	/// particle gets a light. A smaller cap strides across the set, and because the pool swaps
	/// its last particle into a hole each frame, the chosen ones would shuffle and the lights
	/// would pop in and out. Still far under what the clustered forward pass budgets.
	private const int32 cLightParticleCap = 200;

	/// BORROWED: the scene outlives its systems.
	private Scene mScene = null;
	/// The particle renderer's dispatch id, set by the subsystem once it has registered it.
	private uint16 mBillboardRendererId = 0;

	/// Cloning an effect is a serialization round trip, so the manager carries the factory.
	private SerializerFactory mSerializers
		= (new (stream, mode) => new BinarySerializerContext(stream, mode)) ~ delete _;

	/// The current component's emitter frame, which is what re bases a locally simulated
	/// system at extract.
	private Float4x4 mEmitterWorld = Float4x4.Identity();
	/// Nothing sets this yet, so the sorting and the ribbon orientation both work from the
	/// origin. Raptor has the same gap: the field is read in three places and written in none.
	private Float3 mCameraPos = .(0, 0, 0);

	private List<int32> mSortOrder = new .() ~ delete _;
	private List<float> mSortDistance = new .() ~ delete _;

	// The per batch scratch pools. A render data points INTO one of these and is valid for the
	// frame, so growing the POOL must never move a live buffer: the inner lists are reference
	// types, so appending to the outer one leaves every existing buffer exactly where it was.
	private List<List<ParticleBillboardInstance>> mScratch
		= new .() ~ DeleteContainerAndItems!(_);
	private int mScratchUsed = 0;
	private List<List<Float4x4>> mXformScratch = new .() ~ DeleteContainerAndItems!(_);
	private int mXformUsed = 0;
	private List<List<Color>> mTintScratch = new .() ~ DeleteContainerAndItems!(_);
	private int mTintUsed = 0;
	private List<List<TrailVertex>> mTrailScratch = new .() ~ DeleteContainerAndItems!(_);
	private int mTrailUsed = 0;

	/// Bumped per mesh batch, so the instanced mesh path re uploads what changed this frame.
	private uint32 mMeshVersion = 0;

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
	}

	/// Particles run in an editor as well as in a player, so this is NOT simulation gated.
	public override bool IsSimulationOnly => false;

	public void SetBillboardRendererId(uint16 id)
	{
		mBillboardRendererId = id;
	}

	protected override void OnComponentCreated(ParticleEffectComponent* component,
		EntityHandle entity)
	{
		component.EffectMaterialCache = new List<List<Material>>();
	}

	protected override void OnComponentDestroyed(ParticleEffectComponent* component,
		EntityHandle entity)
	{
		DeleteAndNullify!(component.Instance);
		DeleteAndNullify!(component.OwnedEffect);

		if (component.EffectMaterialCache != null)
		{
			ClearAndDeleteItems!(component.EffectMaterialCache);
			DeleteAndNullify!(component.EffectMaterialCache);
		}

		component.Effect = null;
		component.AttachedResource = null;
	}

	/// Attaches a BORROWED effect the caller owns, which is the code path a sample or a test
	/// takes.
	public void SetEffect(EntityHandle entity, ParticleEffect effect)
	{
		let component = Get(entity);
		if (component == null)
			return;

		component.Effect = effect;
		delete component.Instance;
		component.Instance = new ParticleEffectInstance(effect);
	}

	/// (Re)clones a cooked effect as this component's live one.
	///
	/// A CLONE rather than the template itself, because two entities running one effect must
	/// not share live particle state.
	public void AttachResource(ParticleEffectComponent* component, ParticleEffectResource resource)
	{
		component.AttachedResource = resource;

		delete component.OwnedEffect;
		component.OwnedEffect = new ParticleEffect();

		if (resource != null)
			ParticleEffectSerialization.CloneEffect(resource.Effect, component.OwnedEffect,
				mSerializers).IgnoreError();

		component.Effect = component.OwnedEffect;

		delete component.Instance;
		component.Instance = new ParticleEffectInstance(component.OwnedEffect);
	}

	/// Attaches a resource for its RENDER RESOURCES only, without re cloning the effect.
	///
	/// An editor's preview keeps its live borrowed effect for the simulation, so a scalar edit
	/// stays live, while the resolved meshes, textures and materials still drive what draws.
	/// The caller owns the resource and rebuilds it when the effect's references change.
	public void SetRenderResources(EntityHandle entity, ParticleEffectResource resource)
	{
		let component = Get(entity);
		if (component != null)
			component.AttachedResource = resource;
	}

	/// The scene drives the simulation: advance every instance before extraction runs.
	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if ((phase != .PostUpdate) || (mScene == null))
			return;

		using (ProfileScope("Particles.Simulate"))
		{
			ForEach(scope (component, owner) =>
				{
					Simulate(component, owner, deltaTime);
				});
		}
	}

	private void Simulate(ParticleEffectComponent* component, EntityHandle owner, float deltaTime)
	{
		// Frozen: no simulation and no emission, and the live particles hold where they are.
		if (!mScene.IsEffectivelyActive(owner))
			return;

		// Attach or re attach when the reference's resolved product CHANGED: a pick, a scene
		// load's resolve, or a hot reload swapping what sits behind the proxy.
		let resource = component.EffectAsset.Get;
		if ((resource !== component.AttachedResource) && (resource != null))
			AttachResource(component, resource);

		if (component.Instance == null)
			return;

		component.Instance.Position = mScene.GetWorldPosition(owner);
		component.Instance.Update(deltaTime, mCameraPos);
	}

	/// Packs each visible system's live particles into the snapshot. Called during this
	/// scene's extraction.
	public void ExtractRenderData(ExtractedScene snapshot)
	{
		using (ProfileScope("Particles.Extract"))
		{
			mScratchUsed = 0;
			mXformUsed = 0;
			mTintUsed = 0;
			mTrailUsed = 0;

			ForEach(scope (component, owner) =>
				{
					ExtractComponent(component, owner, snapshot);
				});
		}
	}

	private void ExtractComponent(ParticleEffectComponent* component, EntityHandle owner,
		ExtractedScene snapshot)
	{
		// A frozen effect does not RENDER either, which is what makes deactivation read as
		// gone rather than as paused mid frame.
		if (!component.Visible || (component.Instance == null)
			|| ((mScene != null) && !mScene.IsEffectivelyActive(owner)))
			return;

		mEmitterWorld = (mScene != null) ? mScene.GetWorldMatrix(owner) : Float4x4.Identity();

		let effect = component.Instance.Effect;
		for (int32 s = 0; s < effect.SystemCount; s++)
		{
			let system = effect.GetSystem(s);
			if (system == null)
				continue;

			if (system.RenderMode == .Mesh)
			{
				ExtractMeshSystem(system, component, owner, s, snapshot);
				continue;
			}

			if (system.RenderMode == .Trail)
			{
				ExtractTrailSystem(system, component, s, snapshot);
				continue;
			}

			let alive = system.AliveCount;
			if (alive <= 0)
				continue;

			// A light mode system illuminates the scene as well as drawing its billboards.
			if (system.RenderMode == .Light)
				ExtractLights(system, component, snapshot);

			let scratch = AcquireScratch();
			scratch.Resize(alive);

			var boundsMin = Float3(1e30f, 1e30f, 1e30f);
			var boundsMax = Float3(-1e30f, -1e30f, -1e30f);

			// Only an ALPHA blended system needs ordering: additive and multiplicative
			// compositing are order independent, so sorting them would cost for nothing.
			let order = (system.SortParticles && (system.BlendMode == .Alpha))
				? BuildBackToFrontOrder(system) : null;

			PackBillboards(system, scratch.Ptr, ref boundsMin, ref boundsMax, order);

			let data = snapshot.Add<ParticleBillboardRenderData>();
			if (data == null)
				continue;

			data.Category = RenderCategories.Transparent;
			data.RendererId = mBillboardRendererId;
			data.Instances = scratch.Ptr;
			data.Count = (uint32)alive;
			data.Texture = SystemTextureView(component, s);
			data.Blend = system.BlendMode;

			let center = (boundsMin + boundsMax) * 0.5f;
			data.WorldCenter = center;
			data.WorldRadius = Length(boundsMax - center) + LargestSize(system);
		}
	}

	/// The shader's orientation mode: camera facing, camera facing about the vertical, or flat
	/// in the world plane.
	private static float OrientationMode(ParticleRenderMode mode)
	{
		switch (mode)
		{
		case .VerticalBillboard: return 1.0f;
		case .HorizontalBillboard: return 2.0f;
		default: return 0.0f;
		}
	}

	/// `order` remaps an output slot onto a source particle, or is null for the identity.
	private void PackBillboards(ParticleSystem system, ParticleBillboardInstance* output,
		ref Float3 boundsMin, ref Float3 boundsMax, int32* order)
	{
		let streams = system.Streams;
		let positions = streams.Positions;
		let sizes = streams.Sizes;
		let colors = streams.Colors;
		let rotations = streams.Rotations;
		let velocities = streams.Velocities;
		let ages = streams.Ages;
		let lifetimes = streams.Lifetimes;

		let stretch = (system.RenderMode == .StretchedBillboard);
		let mode = OrientationMode(system.RenderMode);
		// Nought means no soft fade at all.
		let softDistance = system.SoftParticles ? system.SoftDistance : 0.0f;
		let flipbook = system.Flipbook.IsActive;
		let alive = system.AliveCount;

		// A LOCALLY simulated system's particles are in the emitter's frame, so they re base
		// through it here rather than the simulation paying for it every step.
		let localSpace = (system.SimulationSpace == .Local);
		let transform = localSpace ? mEmitterWorld : Float4x4.Identity();

		for (int32 k = 0; k < alive; k++)
		{
			let i = (order != null) ? order[k] : k;

			var position = (positions != null) ? positions[i] : Float3.Zero;
			if (localSpace)
				position = TransformPoint(position, transform);

			let size = (sizes != null) ? sizes[i] : Float2(0.1f, 0.1f);

			var instance = ref output[k];
			instance.PositionSize = .(position.X, position.Y, position.Z, size.X);
			instance.SizeRotMode = .(size.Y, (rotations != null) ? rotations[i] : 0.0f, mode,
				softDistance);
			instance.Color = (colors != null) ? colors[i] : Float4(1.0f, 1.0f, 1.0f, 1.0f);

			let lifeRatio = ((ages != null) && (lifetimes != null) && (lifetimes[i] > 0.0f))
				? (ages[i] / lifetimes[i]) : 0.0f;
			instance.UvRect = flipbook
				? system.Flipbook.FrameUV(lifeRatio, (ages != null) ? ages[i] : 0.0f)
				: Float4(0.0f, 0.0f, 1.0f, 1.0f);

			var velocity = (stretch && (velocities != null)) ? velocities[i] : Float3.Zero;
			if (localSpace && stretch)
				velocity = TransformDirection(velocity, transform);
			instance.Velocity = .(velocity.X, velocity.Y, velocity.Z, stretch ? 0.1f : 0.0f);

			boundsMin = .(Math.Min(boundsMin.X, position.X), Math.Min(boundsMin.Y, position.Y),
				Math.Min(boundsMin.Z, position.Z));
			boundsMax = .(Math.Max(boundsMax.X, position.X), Math.Max(boundsMax.Y, position.Y),
				Math.Max(boundsMax.Z, position.Z));
		}
	}

	/// The alive particles ordered FARTHEST first, so an alpha blended system composites
	/// correctly where its particles overlap.
	private int32* BuildBackToFrontOrder(ParticleSystem system)
	{
		using (ProfileScope("Particles.Sort"))
		{
			let alive = system.AliveCount;
			let positions = system.Streams.Positions;
			if (positions == null)
				return null;

			let localSpace = (system.SimulationSpace == .Local);
			mSortOrder.Resize(alive);
			mSortDistance.Resize(alive);

			for (int32 i = 0; i < alive; i++)
			{
				var position = positions[i];
				if (localSpace)
					position = TransformPoint(position, mEmitterWorld);

				mSortOrder[i] = i;
				mSortDistance[i] = LengthSquared(position - mCameraPos);
			}

			let distances = mSortDistance;
			mSortOrder.Sort(scope (a, b) =>
				{
					let da = distances[a];
					let db = distances[b];
					return (da > db) ? -1 : ((da < db) ? 1 : 0);
				});

			return mSortOrder.Ptr;
		}
	}

	/// The largest particle in the system, which pads the bounds so a big one near the edge is
	/// not culled by a radius measured to its centre.
	private static float LargestSize(ParticleSystem system)
	{
		let sizes = system.Streams.Sizes;
		if (sizes == null)
			return 0.5f;

		var largest = 0.0f;
		for (int32 i = 0; i < system.AliveCount; i++)
			largest = Math.Max(largest, Math.Max(sizes[i].X, sizes[i].Y));
		return largest;
	}

	/// A mesh particle's material blend maps onto a category the same way a regular mesh's
	/// does: opaque and masked keep their pass, and everything else is transparent.
	private static uint16 MeshCategoryFor(Material material)
	{
		if (material == null)
			return RenderCategories.Opaque;

		switch (material.Pipeline.BlendMode)
		{
		case .Opaque: return RenderCategories.Opaque;
		case .Masked: return RenderCategories.Masked;
		default: return RenderCategories.Transparent;
		}
	}

	/// A mesh mode system rides the INSTANCED MESH path: no new renderer, the same persistent
	/// buffer machinery a scattered set uses, with a bumped version each frame because the
	/// transforms are new every frame.
	private void ExtractMeshSystem(ParticleSystem system, ParticleEffectComponent* component,
		EntityHandle owner, int32 systemIndex, ExtractedScene snapshot)
	{
		// The resources come RESOLVED from the attached resource, which is the live product on
		// the cooked path and the preview's own on the editor path. It is null on the bare
		// code path, where an application built the effect and there are no resources at all.
		let resource = component.AttachedResource;

		// The COMPONENT's mesh WINS, being the per placement override, and the system's
		// resolved one is the fallback. The scale follows whichever mesh is drawn.
		let componentMesh = component.Mesh.Get;
		let effectMesh = (resource != null) ? resource.SystemMesh(systemIndex).Get : null;
		let mesh = (componentMesh != null) ? componentMesh : effectMesh;
		let meshScale = (componentMesh != null) ? component.MeshScale : system.MeshScale;

		// The material follows the same rule. When the fallback is used, this refreshes the
		// component's cache for the system so the snapshot can borrow a stable per submesh
		// array for the frame, which mirrors what the mesh component does and for the same
		// reason: a late cook heals rather than staying null until the scene is reopened.
		List<Material> materialCache = null;
		if ((component.Material.Get == null) && (resource != null) && (systemIndex >= 0))
		{
			while (component.EffectMaterialCache.Count <= systemIndex)
				component.EffectMaterialCache.Add(new List<Material>());

			let proxies = resource.SystemMaterials(systemIndex);
			let cache = component.EffectMaterialCache[systemIndex];
			cache.Clear();
			for (var proxy in proxies)
				cache.Add(proxy.Get);

			if (!cache.IsEmpty)
				materialCache = cache;
		}

		Material material = component.Material.Get;
		if ((material == null) && (materialCache != null))
			material = materialCache[0];

		let alive = system.AliveCount;
		if ((alive <= 0) || (mesh == null))
			return;

		let transforms = AcquireXformScratch();
		let tints = AcquireTintScratch();
		transforms.Resize(alive);
		tints.Resize(alive);

		var boundsMin = Float3(1e30f, 1e30f, 1e30f);
		var boundsMax = Float3(-1e30f, -1e30f, -1e30f);
		PackMeshTransforms(system, meshScale, transforms.Ptr, tints.Ptr, ref boundsMin,
			ref boundsMax);

		let data = snapshot.Add<MultiMeshRenderData>();
		if (data == null)
			return;

		data.MultiMesh = true;
		data.Key = ((uint64)owner.Index << 16) | ((uint64)(uint32)systemIndex & 0xFFFF);
		data.Transforms = transforms.Ptr;
		data.Tints = tints.Ptr;
		data.InstanceCount = (uint32)alive;
		// Dynamic: the transforms change every frame, so the upload cannot be skipped.
		data.Version = ++mMeshVersion;
		data.Mesh = mesh;
		data.Material = material;

		// More than one slot means the renderer routes each submesh by its own index, falling
		// back to the whole mesh material for a null or out of range one. A single slot leaves
		// this empty and the whole mesh material covers everything.
		let perSubmesh = (materialCache != null) && (materialCache.Count > 1);
		data.SubmeshMaterials = perSubmesh ? materialCache.Ptr : null;
		data.SubmeshMaterialCount = perSubmesh ? (uint32)materialCache.Count : 0;
		// The mesh renderer, which is the first registered.
		data.RendererId = 0;
		data.Category = MeshCategoryFor(material);

		let center = (boundsMin + boundsMax) * 0.5f;
		data.WorldCenter = center;
		data.WorldRadius = Length(boundsMax - center) + LargestSize(system) * meshScale;
	}

	private void PackMeshTransforms(ParticleSystem system, float meshScale, Float4x4* transforms,
		Color* tints, ref Float3 boundsMin, ref Float3 boundsMax)
	{
		let streams = system.Streams;
		let positions = streams.Positions;
		let sizes = streams.Sizes;
		let colors = streams.Colors;
		let axes = streams.Axes;
		let rotations = streams.Rotations;

		let localSpace = (system.SimulationSpace == .Local);
		let alive = system.AliveCount;

		for (int32 i = 0; i < alive; i++)
		{
			let position = (positions != null) ? positions[i] : Float3.Zero;
			let size = ((sizes != null) ? sizes[i].X : 0.1f) * meshScale;

			var transform = Transform();
			transform.Position = position;
			transform.Scale = .(size, size, size);
			if (rotations != null)
			{
				let axis = (axes != null) ? axes[i] : Float3.UnitY;
				transform.Rotation = Quaternion.FromAxisAngle(
					(LengthSquared(axis) > 1e-6f) ? Normalized(axis) : Float3.UnitY, rotations[i]);
			}

			// A local particle reaches the world through its emitter.
			transforms[i] = localSpace ? (transform.ToMatrix() * mEmitterWorld)
				: transform.ToMatrix();

			let worldPosition = localSpace ? TransformPoint(position, mEmitterWorld) : position;
			let color = (colors != null) ? colors[i] : Float4(1.0f, 1.0f, 1.0f, 1.0f);
			tints[i] = .(color.X, color.Y, color.Z, color.W);

			boundsMin = .(Math.Min(boundsMin.X, worldPosition.X),
				Math.Min(boundsMin.Y, worldPosition.Y), Math.Min(boundsMin.Z, worldPosition.Z));
			boundsMax = .(Math.Max(boundsMax.X, worldPosition.X),
				Math.Max(boundsMax.Y, worldPosition.Y), Math.Max(boundsMax.Z, worldPosition.Z));
		}
	}

	/// A point light per particle, capped and evenly strided so the set stays under the
	/// forward pass's budget, coloured by the particle and faded by its alpha.
	private void ExtractLights(ParticleSystem system, ParticleEffectComponent* component,
		ExtractedScene snapshot)
	{
		let positions = system.Streams.Positions;
		if (positions == null)
			return;

		let colors = system.Streams.Colors;
		let alive = system.AliveCount;
		let cap = Math.Min(alive, cLightParticleCap);
		let step = Math.Max(1, alive / Math.Max(cap, 1));

		var added = 0;
		var i = 0;
		while ((added < cap) && (i < alive))
		{
			var light = GpuLight();
			light.PositionWS = (system.SimulationSpace == .Local)
				? TransformPoint(positions[(int32)i], mEmitterWorld) : positions[(int32)i];
			light.Range = component.LightRange;

			let color = (colors != null) ? colors[(int32)i] : Float4(1.0f, 1.0f, 1.0f, 1.0f);
			light.Color = .(color.X, color.Y, color.Z);
			// Faded by the particle's own alpha, so a light dies with the particle.
			light.Intensity = component.LightIntensity * color.W;
			light.DirectionWS = .(0.0f, -1.0f, 0.0f);
			// A point light.
			light.Type = 1.0f;
			// Particles cast no shadows.
			light.ShadowIndex = -1.0f;

			snapshot.AddLight(light);

			i += step;
			added++;
		}
	}

	/// A ribbon from each live particle's recorded points: every consecutive pair becomes a
	/// quad whose side is perpendicular to BOTH the segment and the view, so the ribbon always
	/// faces the camera. The width tapers along the trail and the alpha fades with each
	/// point's age.
	private void ExtractTrailSystem(ParticleSystem system, ParticleEffectComponent* component,
		int32 systemIndex, ExtractedScene snapshot)
	{
		let maxPoints = system.TrailMaxPoints;
		let alive = system.AliveCount;
		if ((maxPoints < 2) || (alive <= 0))
			return;

		let settings = system.Trail;
		let states = system.TrailStates;
		let points = system.TrailPoints;
		let now = system.TotalTime;
		let inverseLife = 1.0f / Math.Max(settings.Lifetime, 1e-3f);
		let localSpace = (system.SimulationSpace == .Local);

		let vertices = AcquireTrailScratch();
		vertices.Clear();

		var boundsMin = Float3(1e30f, 1e30f, 1e30f);
		var boundsMax = Float3(-1e30f, -1e30f, -1e30f);

		for (int32 p = 0; p < alive; p++)
		{
			let state = states[p];
			let count = Math.Min(state.Count, maxPoints);
			if (count < 2)
				continue;

			let baseIndex = p * maxPoints;
			for (int32 k = 0; (k + 1) < count; k++)
			{
				// The ring runs newest to oldest, so this walks BACKWARDS from the head.
				let i0 = baseIndex + (((state.Head - k) % maxPoints + maxPoints) % maxPoints);
				let i1 = baseIndex + (((state.Head - (k + 1)) % maxPoints + maxPoints) % maxPoints);
				let p0 = points[i0];
				let p1 = points[i1];

				let pos0 = localSpace ? TransformPoint(p0.Position, mEmitterWorld) : p0.Position;
				let pos1 = localSpace ? TransformPoint(p1.Position, mEmitterWorld) : p1.Position;

				let segment = pos0 - pos1;
				if (LengthSquared(segment) < 1e-8f)
					continue;

				let mid = (pos0 + pos1) * 0.5f;
				let view = Normalized(mid - mCameraPos);
				var side = Cross(Normalized(segment), view);
				if (LengthSquared(side) < 1e-8f)
					continue;
				side = Normalized(side);

				// Nought at the newest end through one at the oldest.
				let f0 = (float)k / (float)(count - 1);
				let f1 = (float)(k + 1) / (float)(count - 1);
				let w0 = Lerp(settings.WidthStart, settings.WidthEnd, f0) * 0.5f;
				let w1 = Lerp(settings.WidthStart, settings.WidthEnd, f1) * 0.5f;

				let a0 = Math.Clamp(1.0f - (now - p0.RecordTime) * inverseLife, 0.0f, 1.0f);
				let a1 = Math.Clamp(1.0f - (now - p1.RecordTime) * inverseLife, 0.0f, 1.0f);
				let c0 = Float4(p0.Color.X, p0.Color.Y, p0.Color.Z, p0.Color.W * a0);
				let c1 = Float4(p1.Color.X, p1.Color.Y, p1.Color.Z, p1.Color.W * a1);

				let l0 = pos0 + side * w0;
				let r0 = pos0 - side * w0;
				let l1 = pos1 + side * w1;
				let r1 = pos1 - side * w1;

				PushTrailVertex(vertices, l0, 0.0f, c0, ref boundsMin, ref boundsMax);
				PushTrailVertex(vertices, r0, 1.0f, c0, ref boundsMin, ref boundsMax);
				PushTrailVertex(vertices, l1, 0.0f, c1, ref boundsMin, ref boundsMax);
				PushTrailVertex(vertices, r0, 1.0f, c0, ref boundsMin, ref boundsMax);
				PushTrailVertex(vertices, r1, 1.0f, c1, ref boundsMin, ref boundsMax);
				PushTrailVertex(vertices, l1, 0.0f, c1, ref boundsMin, ref boundsMax);
			}
		}

		if (vertices.IsEmpty)
			return;

		let data = snapshot.Add<ParticleTrailRenderData>();
		if (data == null)
			return;

		data.Category = RenderCategories.Transparent;
		// The ribbons ride the same renderer id as the billboards; the kind tells them apart.
		data.RendererId = mBillboardRendererId;
		data.Vertices = vertices.Ptr;
		data.VertexCount = (uint32)vertices.Count;
		data.Texture = SystemTextureView(component, systemIndex);
		data.Blend = system.BlendMode;

		let center = (boundsMin + boundsMax) * 0.5f;
		data.WorldCenter = center;
		data.WorldRadius = Length(boundsMax - center) + settings.WidthStart;
	}

	/// The horizontal coordinate sits at the dot's opaque centre column, and the vertical runs
	/// across the ribbon so its edges stay soft.
	private static void PushTrailVertex(List<TrailVertex> vertices, Float3 position, float v,
		Float4 color, ref Float3 boundsMin, ref Float3 boundsMax)
	{
		var vertex = TrailVertex();
		vertex.Position = position;
		vertex.TexCoord = .(0.5f, v);
		vertex.Color = color;
		vertices.Add(vertex);

		boundsMin = .(Math.Min(boundsMin.X, position.X), Math.Min(boundsMin.Y, position.Y),
			Math.Min(boundsMin.Z, position.Z));
		boundsMax = .(Math.Max(boundsMax.X, position.X), Math.Max(boundsMax.Y, position.Y),
			Math.Max(boundsMax.Z, position.Z));
	}

	/// A system's texture: the cooked resource's own per system one, which follows a hot
	/// reload, or the raw view code set on the component.
	private static ITextureView SystemTextureView(ParticleEffectComponent* component,
		int32 systemIndex)
	{
		if (let resource = component.EffectAsset.Get)
		{
			if (let texture = resource.SystemTexture(systemIndex).Get)
				return texture.View;
		}
		return component.Texture;
	}

	private List<ParticleBillboardInstance> AcquireScratch()
	{
		if (mScratchUsed >= mScratch.Count)
			mScratch.Add(new List<ParticleBillboardInstance>());
		return mScratch[mScratchUsed++];
	}

	private List<Float4x4> AcquireXformScratch()
	{
		if (mXformUsed >= mXformScratch.Count)
			mXformScratch.Add(new List<Float4x4>());
		return mXformScratch[mXformUsed++];
	}

	private List<Color> AcquireTintScratch()
	{
		if (mTintUsed >= mTintScratch.Count)
			mTintScratch.Add(new List<Color>());
		return mTintScratch[mTintUsed++];
	}

	private List<TrailVertex> AcquireTrailScratch()
	{
		if (mTrailUsed >= mTrailScratch.Count)
			mTrailScratch.Add(new List<TrailVertex>());
		return mTrailScratch[mTrailUsed++];
	}
}
