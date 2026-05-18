namespace Sedulous.Engine.Render;

using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Materials;
using Sedulous.Resources;
using Sedulous.Core.Mathematics;
using Sedulous.Particles;
using Sedulous.Inspection;

/// Component for a particle effect attached to an entity.
///
/// The app sets an effect ResourceRef (or a direct ParticleEffect pointer).
/// ParticleComponentManager resolves the effect resource, walks its systems
/// to resolve each system.TextureRef, creates per-system MaterialInstances,
/// simulates the effect, and extracts ParticleBatchRenderData each frame.
/// Texture is per-ParticleSystem on the asset - the component no longer
/// carries its own texture.
[Component]
class ParticleComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 2;

	public void Serialize(IComponentSerializer s)
	{
		s.ResourceRef("EffectRef", ref mEffectRef);
		s.Bool("IsVisible", ref IsVisible);
		s.Bool("AutoPlay", ref AutoPlay);
	}

	/// The particle effect definition (shared, not owned by component).
	/// Set directly for programmatic effects, or resolved from EffectRef by the manager.
	public ParticleEffect Effect;

	/// Runtime instance (created by manager when Effect is set/resolved).
	public ParticleEffectInstance Instance ~ delete _;

	/// Particle effect resource reference (serialized).
	[Property(.Default, "Effect Ref", "EffectRef")]
	[ResourceRefType(".particlefx")]
	private ResourceRef mEffectRef ~ _.Dispose();

	/// Layer mask for filtering during extraction.
	public uint32 LayerMask = 0xFFFFFFFF;

	/// Whether the particle effect is visible.
	public bool IsVisible = true;

	/// Whether to auto-play on creation.
	public bool AutoPlay = true;

	/// Gets the effect resource ref.
	public ResourceRef EffectRef => mEffectRef;

	/// Sets the effect resource ref (deep copy).
	public void SetEffectRef(ResourceRef @ref)
	{
		mEffectRef.Dispose();
		mEffectRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	/// Sets the effect and creates a runtime instance.
	public void SetEffect(ParticleEffect effect)
	{
		if (Effect == effect) return;
		Effect = effect;
		delete Instance;
		Instance = (effect != null) ? new ParticleEffectInstance(effect) : null;
	}
}
