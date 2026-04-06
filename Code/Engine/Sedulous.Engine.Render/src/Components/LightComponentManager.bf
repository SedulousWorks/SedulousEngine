namespace Sedulous.Engine.Render;

using System;
using Sedulous.Scenes;
using Sedulous.Renderer;
using Sedulous.Core.Mathematics;

/// Manages light components and extracts light data for the renderer.
/// Injected into scenes by RenderSubsystem via ISceneAware.
class LightComponentManager : ComponentManager<LightComponent>, IRenderDataProvider
{
	public override StringView SerializationTypeId => "Sedulous.LightComponent";

	/// Extracts LightRenderData for all active light components.
	public void ExtractRenderData(in RenderExtractionContext context)
	{
		let scene = Scene;
		if (scene == null)
			return;

		for (let light in ActiveComponents)
		{
			if (!light.IsActive)
				continue;

			if (context.LayerMask != 0xFFFFFFFF && (light.LayerMask & context.LayerMask) == 0)
				continue;

			let worldMatrix = scene.GetWorldMatrix(light.Owner);
			let position = worldMatrix.Translation;

			// Direction: forward vector is -Z in XNA convention.
			// M31/M32/M33 is the +Z axis (backward), negate for forward.
			let direction = -Vector3.Normalize(.(worldMatrix.M31, worldMatrix.M32, worldMatrix.M33));

			context.RenderData.AddLight(.()
			{
				Base = .()
				{
					Position = position,
					Bounds = .(.Zero, .Zero), // TODO: compute from range
					Flags = .None
				},
				Type = light.Type,
				Color = light.Color,
				Intensity = light.Intensity,
				Direction = direction,
				Range = light.Range,
				InnerConeAngle = Math.DegreesToRadians(light.InnerConeAngle),
				OuterConeAngle = Math.DegreesToRadians(light.OuterConeAngle),
				CastsShadows = light.CastsShadows,
				ShadowBias = light.ShadowBias,
				ShadowNormalBias = light.ShadowNormalBias
			});
		}
	}
}
