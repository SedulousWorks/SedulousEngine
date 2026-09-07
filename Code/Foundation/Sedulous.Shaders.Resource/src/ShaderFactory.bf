using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Shaders;

namespace Sedulous.Shaders.Resource;

/// Builds a ShaderResource from an authored ShaderSource.
///
/// The build REGISTERS the sources with the shader system and invalidates the shader, so a
/// reload propagates on its own: stale variants are destroyed, the version moves, and any
/// pipeline cache watching that version rebuilds. A material depending on the shader is then
/// just an ordinary resource to resource edge.
class ShaderFactory : IResourceFactory
{
	private ShaderSystem mSystem;

	/// The system is BORROWED and must outlive this.
	public this(ShaderSystem system)
	{
		mSystem = system;
	}

	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<ShaderResource>();

	/// NOT async: registering sources and invalidating mutate the shared shader system, and
	/// the variants themselves compile lazily on the thread that asks for them anyway, so
	/// there is nothing here worth moving to a worker.
	public bool SupportsAsync => false;

	public Object Create(ResourceManager manager, Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;
		defer delete stored;

		let source = stored as ShaderSource;
		if (source == null)
			return null;
		if (source.Name.IsEmpty)
			return null;

		mSystem.RegisterSource(source.Name, .Vertex, source.VertexSource);
		mSystem.RegisterSource(source.Name, .Fragment, source.FragmentSource);
		// Drops variants compiled from the PREVIOUS source and bumps the version, which is
		// what makes a reload observable rather than silently serving stale modules.
		mSystem.InvalidateShader(source.Name);

		let product = new ShaderResource();
		product.Initialize(mSystem, source.Name);
		return product;
	}
}
