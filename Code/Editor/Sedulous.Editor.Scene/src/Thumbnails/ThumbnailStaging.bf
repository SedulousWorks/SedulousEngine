using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Render;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// What the scene thumbnail generators share: reaching the project's source assets,
/// waiting on mesh references, and framing what was staged.
static class ThumbnailStaging
{
	/// Pending while a bind is still loading; failed once the handle says so, or when there
	/// is no handle at all.
	public static ThumbnailStageStep StepForPending<T>(Proxy<T> proxy) where T : class
	{
		let handle = proxy.Handle;
		if ((handle == null) || (handle.State == .Failed))
			return .Failed;
		return .Pending;
	}

	public static Instance SourceInstance(EditorContext context, Guid id)
	{
		if ((context == null) || (context.Project == null))
			return null;
		return context.Project.SourceDb.GetInstance(id);
	}

	/// A resolver over the project's source database. The caller owns it.
	public static ScenePrefabs.PayloadResolver PayloadResolver(EditorContext context)
	{
		return new [=context](prefabId) =>
		{
			let instance = SourceInstance(context, prefabId);
			return (instance != null) ? instance.ReadData("scene") : null;
		};
	}

	/// Whether every mesh reference has either resolved or failed, which is when the stage
	/// can be framed.
	public static bool MeshRefsSettled(Sedulous.Scene.Scene stage)
	{
		let meshes = stage.GetSystem<MeshComponentManager>();
		if (meshes == null)
			return true;
		var settled = true;
		meshes.ForEach(scope [&](c, owner) =>
		{
			if (c.Mesh.Id.IsNil || (c.Mesh.Get != null))
				return;
			if (c.Mesh.IsBound && (c.Mesh.State != .Failed))
				settled = false;
		});
		return settled;
	}

	/// The world bounds of every resolved mesh on the stage.
	public static AABB WorldMeshBounds(Sedulous.Scene.Scene stage)
	{
		var bounds = AABB.Empty();
		let meshes = stage.GetSystem<MeshComponentManager>();
		if (meshes == null)
			return bounds;
		meshes.ForEach(scope [&](c, entity) =>
		{
			let mesh = c.Mesh.Get;
			if ((mesh == null) || !mesh.Bounds.IsValid())
				return;
			let world = stage.GetWorldMatrix(entity);
			let mn = mesh.Bounds.Min;
			let mx = mesh.Bounds.Max;
			for (uint32 i < 8)
			{
				let corner = Float3(((i & 1) != 0) ? mx.X : mn.X, ((i & 2) != 0) ? mx.Y : mn.Y,
					((i & 4) != 0) ? mx.Z : mn.Z);
				bounds.Expand(TransformPoint(corner, world));
			}
		});
		return bounds;
	}

	public static void FrameFromBounds(AABB bounds, ref ThumbnailFraming outFraming)
	{
		if (bounds.IsValid())
		{
			outFraming.Center = bounds.Center();
			outFraming.Radius = Max(Length(bounds.Extents()), 0.05f);
		}
	}

	/// A key light for a stage that spawned its own content.
	public static void AddSun(Sedulous.Scene.Scene stage)
	{
		let lights = stage.GetSystem<LightComponentManager>();
		if (lights == null)
			return;
		let sun = stage.CreateEntity("ThumbSun");
		var t = Transform();
		t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.35f)
			* Quaternion.FromAxisAngle(.(1, 0, 0), -1.05f);
		stage.SetLocalTransform(sun, t);
		let light = lights.Add(sun);
		light.CastsShadows = false;
	}

	/// Drops the display entity's direct mesh so the shared stage holds nothing of the job.
	public static void ClearDisplayMesh(Sedulous.Scene.Scene stage, EntityHandle display)
	{
		if (let meshes = stage.GetSystem<MeshComponentManager>())
		{
			if (let component = meshes.Get(display))
			{
				component.Mesh.SetId(.());
				component.Mesh.SetDirect(null);
			}
		}
	}
}
