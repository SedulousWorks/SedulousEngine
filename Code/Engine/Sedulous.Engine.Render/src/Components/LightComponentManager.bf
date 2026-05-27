namespace Sedulous.Engine.Render;

using System;
using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Core.Mathematics;
using Sedulous.Profiler;

/// Manages light components and extracts light data for the renderer.
/// Injected into scenes by RenderSubsystem via ISceneAware.
///
/// Debug visualization (direction arrows, range spheres, spot cones) is handled
/// by IGizmoRenderer in the editor layer, not here. This manager only handles
/// runtime extraction of light data for the renderer.
class LightComponentManager : ComponentManager<LightComponent>, IRenderDataProvider
{
	public override StringView SerializationTypeId => "Sedulous.LightComponent";

	/// Extracts LightRenderData for all active light components.
	public void ExtractRenderData(in RenderExtractionContext context)
	{
		using (Profiler.Begin("Light.Extract"))
		{
		let scene = Scene;
		if (scene == null)
			return;

		let frameAlloc = context.RenderContext.FrameAllocator;

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

			// Compute bounding box from light range for future frustum culling.
			// Directional lights are infinite - zero bounds (never culled).
			// Point and spot lights have a finite range as a bounding sphere,
			// approximated as an AABB for the broad-phase.
			BoundingBox lightBounds = .(.Zero, .Zero);
			if (light.Type != .Directional && light.Range > 0)
			{
				let r = Vector3(light.Range, light.Range, light.Range);
				lightBounds = .(position - r, position + r);
			}

			let data = new:frameAlloc LightRenderData();
			data.Position = position;
			data.Bounds = lightBounds;
			data.Flags = .None;
			data.Type = light.Type;
			data.Color = light.Color;
			data.Intensity = light.Intensity;
			data.Direction = direction;
			data.Range = light.Range;
			data.InnerConeAngle = Math.DegreesToRadians(light.InnerConeAngle);
			data.OuterConeAngle = Math.DegreesToRadians(light.OuterConeAngle);
			data.CastsShadows = light.CastsShadows;
			data.ShadowBias = light.ShadowBias;
			data.ShadowNormalBias = light.ShadowNormalBias;
			context.RenderData.Add(RenderCategories.Light, data);
		}
		}
	}
}
