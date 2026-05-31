namespace Sedulous.Engine.Render;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Core.Mathematics;
using Sedulous.Profiler;

/// Manages reflection probe components: allocates stable cubemap-array slots,
/// extracts per-frame probe data for the renderer, releases slots on destroy.
///
/// Each probe gets a stable slot in [0, MaxIBLProbes). The slot determines
/// the probe's slice in the per-frame prefiltered cubemap array and its
/// SH9 coefficient offset. The renderer's capture scheduler (Sub-phase C)
/// looks up the slot to know where to render.
///
/// If the scene contains more probes than MaxIBLProbes, additional probes
/// get ArraySlot = -1 and are silently skipped by extraction. Bumping the
/// cap means resizing the IBL GPU resources in RenderContext.
class ReflectionProbeManager : ComponentManager<ReflectionProbeComponent>, IRenderDataProvider
{
	public override StringView SerializationTypeId => "Sedulous.ReflectionProbeComponent";

	/// Free list of probe slots. Initialized to [MaxIBLProbes-1, ..., 1, 0] so
	/// PopBack returns slot 0 first. New probes claim from the back; destroyed
	/// probes push their slot back.
	private List<int32> mFreeSlots = new .() ~ delete _;
	/// True once mFreeSlots has been initialized. Lazily filled on first use
	/// so the manager doesn't allocate state for scenes that never use probes.
	private bool mFreeSlotsInitialized = false;

	private void EnsureSlotsInitialized()
	{
		if (mFreeSlotsInitialized) return;
		mFreeSlotsInitialized = true;
		// Push in reverse so PopBack gives ascending slot indices first.
		for (int32 i = RenderContext.MaxIBLProbes - 1; i >= 0; i--)
			mFreeSlots.Add(i);
	}

	protected override void OnComponentCreated(ReflectionProbeComponent comp)
	{
		EnsureSlotsInitialized();
		if (mFreeSlots.Count > 0)
			comp.ArraySlot = mFreeSlots.PopBack();
		else
			comp.ArraySlot = -1;  // out of slots; probe is silently inactive
	}

	public override void OnEntityDestroyed(EntityHandle entity)
	{
		// Recover the slot before the base class destroys the component.
		if (let comp = GetForEntity(entity))
		{
			if (comp.ArraySlot >= 0)
			{
				mFreeSlots.Add(comp.ArraySlot);
				comp.ArraySlot = -1;
			}
		}
		base.OnEntityDestroyed(entity);
	}

	/// Extracts ReflectionProbeRenderData for all active probes with a valid slot.
	public void ExtractRenderData(in RenderExtractionContext context)
	{
		using (Profiler.Begin("ReflectionProbe.Extract"))
		{
			let scene = Scene;
			if (scene == null) return;

			let frameAlloc = context.RenderContext.FrameAllocator;

			for (let probe in ActiveComponents)
			{
				if (!probe.IsActive) continue;
				if (probe.ArraySlot < 0) continue;
				if (context.LayerMask != 0xFFFFFFFF && (probe.LayerMask & context.LayerMask) == 0)
					continue;

				let worldMatrix = scene.GetWorldMatrix(probe.Owner);
				let position = worldMatrix.Translation;

				// Influence bounds in world space. Used by the renderer to
				// frustum-cull and to compute the per-pixel weighted blend.
				let r = Vector3(probe.InfluenceRadius, probe.InfluenceRadius, probe.InfluenceRadius);

				let data = new:frameAlloc ReflectionProbeRenderData();
				data.Position = position;
				data.Bounds = .(position - r, position + r);
				data.Flags = .None;
				data.ProbePosition = position;
				data.InfluenceRadius = probe.InfluenceRadius;
				// Box bounds stay in the probe's LOCAL space - the forward shader
				// computes `localPos = worldPos - probe.Position` and compares
				// against these directly. Translating to world here would force
				// the shader's outside-check to compare apples to oranges
				// (localPos vs world-space bounds) and zero out the probe weight.
				data.LocalBoxMin = probe.LocalBoxMin;
				data.LocalBoxMax = probe.LocalBoxMax;
				data.BlendEdge = probe.BlendEdge;
				data.ArraySlot = probe.ArraySlot;

				context.RenderData.Add(RenderCategories.ReflectionProbe, data);
			}
		}
	}
}
