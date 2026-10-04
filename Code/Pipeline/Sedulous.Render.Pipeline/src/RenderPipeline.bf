using Sedulous.Core.Serialization;

namespace Sedulous.Render.Pipeline;

/// Registration for the render authoring types.
static class RenderPipeline
{
	/// Hand written rather than generated: the assets describe THEMSELVES, so a field walk
	/// would never see them.
	public static void RegisterAll(SerializableRegistry registry = null)
	{
		let target = (registry != null) ? registry : GlobalSerializableRegistry;
		target.Register(TypeIdOf("Sedulous.Render.Pipeline.EnvironmentProfileAsset"),
			() => new EnvironmentProfileAsset());
		target.Register(TypeIdOf("Sedulous.Render.Pipeline.PostProcessProfileAsset"),
			() => new PostProcessProfileAsset());
	}
}
