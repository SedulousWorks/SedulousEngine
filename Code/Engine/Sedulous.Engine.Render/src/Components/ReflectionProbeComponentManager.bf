namespace Sedulous.Engine.Render;

using System;
using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Renderer.Probes;
using Sedulous.Core.Mathematics;
using Sedulous.Profiler;

/// Manages reflection probe components and extracts probe data for the renderer.
/// Injected into scenes by RenderSubsystem via ISceneAware.
class ReflectionProbeComponentManager : ComponentManager<ReflectionProbeComponent>, IRenderDataProvider
{
	public override StringView SerializationTypeId => "Sedulous.ReflectionProbeComponent";

	/// Extracts ReflectionProbeRenderData for all active probe components.
	public void ExtractRenderData(in RenderExtractionContext context)
	{
		let scene = Scene;
		if (scene == null)
			return;

		let frameAlloc = context.RenderContext.FrameAllocator;

		for (let probe in ActiveComponents)
		{
			if (!probe.IsActive)
				continue;

			let worldMatrix = scene.GetWorldMatrix(probe.Owner);

			let data = new:frameAlloc ReflectionProbeRenderData();
			data.ProbePosition = worldMatrix.Translation;
			data.Bounds = .(.Zero, .Zero); // Probes are not culled
			data.Flags = .None;
			data.UpdateMode = (uint8)probe.UpdateMode;
			data.CaptureResolution = probe.CaptureResolution;
			data.NearClip = probe.NearClip;
			data.FarClip = probe.FarClip;
			data.InfluenceRadius = probe.InfluenceRadius;
			data.Intensity = probe.Intensity;
			data.ProbeKey = (uint64)probe.Owner.GetHashCode();
			context.RenderData.Add(RenderCategories.ReflectionProbe, data);
		}
	}
}
