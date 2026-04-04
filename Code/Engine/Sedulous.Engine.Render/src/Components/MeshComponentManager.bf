namespace Sedulous.Engine.Render;

using Sedulous.Scenes;
using Sedulous.Renderer;
using Sedulous.Materials;
using Sedulous.Core.Mathematics;
using System;

/// Manages mesh components and extracts render data for the renderer.
/// Injected into scenes by RenderSubsystem via ISceneAware.
///
/// Each MeshComponent can have multiple materials (one per submesh material slot).
/// Extraction emits one MeshRenderData per submesh.
class MeshComponentManager : ComponentManager<MeshComponent>, IRenderDataProvider
{
	/// Reference to the pipeline's GPU resource manager (set by RenderSubsystem).
	public GPUResourceManager GPUResources { get; set; }

	public override StringView SerializationTypeId => "Sedulous.MeshComponent";

	/// Extracts MeshRenderData for all active, visible mesh components.
	/// Emits one entry per submesh, each with its own material.
	public void ExtractRenderData(in RenderExtractionContext context)
	{
		let scene = Scene;
		if (scene == null || GPUResources == null)
			return;

		for (let mesh in ActiveComponents)
		{
			if (!mesh.IsActive || !mesh.IsVisible)
				continue;

			if (!mesh.MeshHandle.IsValid)
				continue;

			// Layer mask filtering
			if (context.LayerMask != 0xFFFFFFFF && (mesh.LayerMask & context.LayerMask) == 0)
				continue;

			let gpuMesh = GPUResources.GetMesh(mesh.MeshHandle);
			if (gpuMesh == null)
				continue;

			// Get world matrix from entity transform
			let worldMatrix = scene.GetWorldMatrix(mesh.Owner);
			let center = Vector3.Transform(mesh.LocalBounds.Center, worldMatrix);

			// Build render data flags
			var flags = RenderDataFlags.None;
			if (mesh.CastsShadows)
				flags |= .CastShadows;

			// Emit one MeshRenderData per submesh
			for (int32 subIdx = 0; subIdx < gpuMesh.SubMeshes.Count; subIdx++)
			{
				let subMesh = gpuMesh.SubMeshes[subIdx];
				let materialSlot = (int32)subMesh.MaterialSlot;

				// Resolve material for this submesh's slot
				let material = mesh.GetMaterial(materialSlot);

				// Determine category from material blend mode
				var category = RenderCategories.Opaque;
				if (material != null && material.BlendMode != .Opaque)
					category = RenderCategories.Transparent;

				// Material sort key for batching
				let materialKey = (material != null) ? (uint32)(int)Internal.UnsafeCastToPtr(material) : 0;

				context.RenderData.AddMesh(category, .()
				{
					Base = .()
					{
						Position = center,
						Bounds = mesh.LocalBounds,
						MaterialSortKey = materialKey,
						SortOrder = 0,
						Flags = flags
					},
					WorldMatrix = worldMatrix,
					PrevWorldMatrix = worldMatrix, // TODO: track previous frame
					MeshHandle = mesh.MeshHandle,
					SubMeshIndex = (uint32)subIdx,
					MaterialBindGroup = material?.BindGroup,
					MaterialKey = materialKey
				});
			}
		}
	}
}
