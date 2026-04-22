namespace Sedulous.Engine.Render;

using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Materials;
using Sedulous.Resources;
using Sedulous.Core.Mathematics;
using Sedulous.Particles;

/// Component for a particle effect attached to an entity.
///
/// The app sets an effect ResourceRef (or a direct ParticleEffect pointer).
/// ParticleComponentManager resolves the effect resource, creates a runtime
/// instance, resolves the texture, creates a MaterialInstance, simulates the
/// effect, and extracts ParticleBatchRenderData each frame.
class ParticleComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.ResourceRef("EffectRef", ref mEffectRef);
		s.ResourceRef("TextureRef", ref mTextureRef);
		s.Bool("IsVisible", ref IsVisible);
		s.Bool("AutoPlay", ref AutoPlay);
	}

	/// The particle effect definition (shared, not owned by component).
	/// Set directly for programmatic effects, or resolved from EffectRef by the manager.
	public ParticleEffect Effect;

	/// Runtime instance (created by manager when Effect is set/resolved).
	public ParticleEffectInstance Instance ~ delete _;

	/// Particle effect resource reference (serialized).
	private ResourceRef mEffectRef ~ _.Dispose();

	/// Texture resource reference (serialized). Overrides the effect's default texture.
	private ResourceRef mTextureRef ~ _.Dispose();

	/// Resolved MaterialInstance - created by the manager, released on destroy.
	public MaterialInstance Material ~ _?.ReleaseRef();

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

	/// Gets the texture resource ref.
	public ResourceRef TextureRef => mTextureRef;

	/// Sets the texture resource ref (deep copy).
	public void SetTextureRef(ResourceRef @ref)
	{
		mTextureRef.Dispose();
		mTextureRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	/// Assigns a MaterialInstance directly (takes ownership - AddRef/ReleaseRef pattern).
	public void SetMaterial(MaterialInstance material)
	{
		if (Material == material) return;
		material?.AddRef();
		Material?.ReleaseRef();
		Material = material;
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
