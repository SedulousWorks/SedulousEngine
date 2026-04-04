namespace Sedulous.Engine.Render;

using Sedulous.Scenes;
using Sedulous.Renderer;
using Sedulous.Core.Mathematics;
using System;

/// Manages mesh components and extracts render data for the renderer.
/// Injected into scenes by RenderSubsystem via ISceneAware.
class MeshComponentManager : ComponentManager<MeshComponent>, IRenderDataProvider
{
	public override StringView SerializationTypeId => "Sedulous.MeshComponent";

	/// Extracts MeshRenderData for all active, visible mesh components.
	public void ExtractRenderData(in RenderExtractionContext context)
	{
		let scene = Scene;
		if (scene == null)
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

			// Get world matrix from entity transform
			let worldMatrix = scene.GetWorldMatrix(mesh.Owner);

			// Transform local bounds to world space for sorting position
			let center = Vector3.Transform(mesh.LocalBounds.Center, worldMatrix);

			// Build render data flags
			var flags = RenderDataFlags.None;
			if (mesh.CastsShadows)
				flags |= .CastShadows;

			context.RenderData.AddMesh(RenderCategories.Opaque, .()
			{
				Base = .()
				{
					Position = center,
					Bounds = mesh.LocalBounds, // TODO: transform to world bounds
					MaterialSortKey = mesh.MaterialSortKey,
					SortOrder = 0,
					Flags = flags
				},
				WorldMatrix = worldMatrix,
				PrevWorldMatrix = worldMatrix, // TODO: track previous frame
				MeshHandle = mesh.MeshHandle,
				SubMeshIndex = mesh.SubMeshIndex,
				MaterialBindGroup = mesh.MaterialBindGroup,
				MaterialKey = mesh.MaterialSortKey
			});
		}
	}
}
