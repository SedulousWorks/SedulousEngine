using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Materials;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Shaders.Resource;
using Sedulous.Texture.Resource;

namespace Sedulous.Materials.Resource;

/// Builds an authored material source into a runtime material.
///
/// It BINDS the referenced shader and textures through the manager mid build, which records
/// the dependency edges: reloading a shader or a texture then reloads every material that
/// referenced it, without anything here having to know who did.
///
/// The product is the data only material. Its GPU bind group layout is still inferred later
/// by the material system, which is what keeps this layer device free.
class MaterialFactory : IResourceFactory
{
	/// BORROWED; null in a host without one.
	private ShaderSystem mSystem = null;

	public this() {}

	/// With the shader system (borrowed; may be null): the factory re-lays each material's effect
	/// groups on the effects' live tables, by what its shader's vertex stage declares (a material
	/// saved before an effect existed gains its group; one whose shader no longer declares the
	/// effect loses it). Without one, a material keeps the groups its source carries, which is
	/// all it needs to draw them.
	public this(ShaderSystem system)
	{
		mSystem = system;
	}

	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<Material>();
	public Type CookedType => typeof(MaterialSource);

	/// NOT async: the build binds other resources through the manager, and the manager is
	/// the main thread's.
	public bool SupportsAsync => false;

	public Object Create(ResourceManager manager, Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;
		defer delete stored;

		let source = stored as MaterialSource;
		if (source == null)
			return null;

		let missing = scope String();
		if (!ForwardMaterialContract.IsComplete(source, missing))
		{
			GlobalLog(.Error,
				"Materials: material '{}' is missing the forward shader property '{}'. The source is stale; re-create the material.",
				source.Name, missing);
			return null;
		}

		let depthName = scope String();
		let pickName = scope String();
		// Where the material's effects are declared: the shader's vertex variants, and the
		// shader system serving the effects' tables (a custom shader's own, else the host's).
		ShaderSystem effectSystem = null;
		ShaderFlags vertexVariants = .None;
		let shaderName = ResolveShaderName(manager, source, depthName, pickName, ref effectSystem, ref vertexVariants,
			.. scope .());
		if ((effectSystem == null) && (mSystem != null) && !shaderName.IsEmpty)
		{
			effectSystem = mSystem;
			vertexVariants = mSystem.DeclaredVariants(shaderName, .Vertex);
		}
		let material = source.ToMaterial(shaderName);
		material.DepthShaderName.Set(depthName);
		material.PickShaderName.Set(pickName);
		// An empty library says nothing (a shader system with no corpus): the stored groups stand.
		if ((effectSystem != null) && !effectSystem.Effects.IsEmpty)
			material.AdoptDeclaredEffects(effectSystem.Effects.All, vertexVariants);

		BindDefaultTextures(manager, source, material);
		return material;
	}

	/// The cooked shader's name, or the builtin named directly when there is no resource to
	/// point at; and the shader's own depth and pick programs, where the material needs them.
	private static void ResolveShaderName(ResourceManager manager, MaterialSource source,
		String outDepthName, String outPickName, ref ShaderSystem effectSystem, ref ShaderFlags vertexVariants,
		String outName)
	{
		if (source.ShaderId != Guid())
		{
			// The bind is what records the material to shader edge, so this is not merely
			// a lookup: it is how a shader reload reaches every material using it.
			let shader = manager.Bind<ShaderResource>(source.ShaderId);
			if (shader.Get != null)
			{
				outName.Set(shader.Get.Name);
				let masked = source.BlendMode == .Masked;
				outDepthName.Set(shader.Get.DepthProgram(masked));
				outPickName.Set(shader.Get.PickProgram(masked));
				effectSystem = shader.Get.System;
				vertexVariants = shader.Get.VertexVariants;
			}
		}

		if (outName.IsEmpty)
			outName.Set(source.ShaderName);
	}

	/// Resolves the stored texture slots and installs them as the material's defaults.
	///
	/// A slot that cannot be filled is left UNBOUND rather than failing the material: the
	/// system substitutes a neutral texture, so a material whose textures are not cooked yet
	/// still draws.
	private static void BindDefaultTextures(ResourceManager manager, MaterialSource source,
		Material material)
	{
		let count = Min(source.TextureSlots.Count, source.TextureIds.Count);
		for (int i = 0; i < count; i++)
		{
			let id = source.TextureIds[i];
			if (id == Guid())
				continue;

			let slot = source.TextureSlots[i];

			// Routed by the manager's own async flag, which whatever is driving the load
			// sets. A direct bind never consults it, and THIS loop is where a serial load
			// stalls: a scene's worth of textures decoded on the calling thread, inside
			// material builds.
			let texture = manager.AsyncBindsEnabled
				? manager.BindAsync<Texture>(id)
				: manager.Bind<Texture>(id);

			if (texture.Get == null)
			{
				// Still decoding on a worker: the slot stays unbound QUIETLY, because the
				// recorded edge brings this material back once the texture settles.
				if (texture.State == .Pending)
					continue;

				GlobalLog(.Warning,
					"Materials: material '{}' slot '{}' failed to bind. No product, or no texture factory registered.",
					source.Name, slot);
				continue;
			}

			if (texture.Get.View == null)
			{
				GlobalLog(.Warning, "Materials: material '{}' slot '{}' has no GPU view.",
					source.Name, slot);
				continue;
			}

			if (!material.FindProperty(slot, let ignored))
			{
				GlobalLog(.Warning,
					"Materials: material '{}' has no texture property named '{}' in its layout.",
					source.Name, slot);
				continue;
			}

			material.SetDefaultTexture(slot, texture.Get.View);
		}
	}
}
