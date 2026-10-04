using System;
using Sedulous.Content;
using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Engine.Render;

/// The cooked Environment Profile: the environment's value fields, written by the same
/// serializer as the scene's block. No source: a profile IS the source.
///
/// Describes itself rather than carrying [Serializable], because its fields are a settings
/// block's values and the block's own serializer is what writes them.
class EnvironmentProfileSource : ISerializable
{
	public EnvironmentSettings Values = .();

	public void Serialize(ISerializer ar)
	{
		RenderSettingsValues.SerializeEnvironment(ar, ref Values, true);
	}
}

/// The cooked Post Process Profile.
class PostProcessProfileSource : ISerializable
{
	public PostProcessSettings Values = .();

	public void Serialize(ISerializer ar)
	{
		RenderSettingsValues.SerializePost(ar, ref Values);
	}
}

/// Loads an Environment Profile, binding its sky texture through the manager. The bind
/// records the dependency, so a texture's reload reaches the profile; it is the manager's to
/// write on the thread that owns it, hence synchronous.
class EnvironmentProfileFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<EnvironmentProfile>();
	public Type CookedType => typeof(EnvironmentProfileSource);

	public Object Create(ResourceManager manager, Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;
		defer delete stored;
		let source = stored as EnvironmentProfileSource;
		if (source == null)
			return null;

		let profile = new EnvironmentProfile();
		profile.Values = source.Values;
		profile.Values.SkyTexture.Bind(manager);
		return profile;
	}
}

/// Loads a Post Process Profile, binding its grading lookup texture.
class PostProcessProfileFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<PostProcessProfile>();
	public Type CookedType => typeof(PostProcessProfileSource);

	public Object Create(ResourceManager manager, Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;
		defer delete stored;
		let source = stored as PostProcessProfileSource;
		if (source == null)
			return null;

		let profile = new PostProcessProfile();
		profile.Values = source.Values;
		profile.Values.GradingLut.Bind(manager);
		return profile;
	}
}

/// Registration for the render profiles: their cooked records and the factories that load
/// them, a resource module of the render domain.
static class RenderProfileResources
{
	public static ResourceModule Module => sModule ?? (sModule = new .("render.profiles", () => RegisterAll(), new .(
		.ByDefault<EnvironmentProfile, EnvironmentProfileSource, EnvironmentProfileFactory>(),
		.ByDefault<PostProcessProfile, PostProcessProfileSource, PostProcessProfileFactory>())));
	private static ResourceModule sModule ~ delete _;

	/// Into the global registry unless another is given. The records describe themselves
	/// rather than carrying [Serializable], so they are named here.
	public static void RegisterAll(SerializableRegistry registry = null)
	{
		let target = (registry != null) ? registry : GlobalSerializableRegistry;
		target.Register(TypeIdOf("Sedulous.Engine.Render.EnvironmentProfileSource"),
			() => new EnvironmentProfileSource());
		target.Register(TypeIdOf("Sedulous.Engine.Render.PostProcessProfileSource"),
			() => new PostProcessProfileSource());
	}
}
