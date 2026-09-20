using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Physics.Resource;
using Sedulous.Engine.Render;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Physics;

/// A collision shape's thumbnail: its cooked outline as a lit mesh, centred and framed.
class CollisionThumbnailGenerator : ISceneThumbnailGenerator
{
	private EntityHandle mDisplay = .Invalid;
	private EntityHandle mSun = .Invalid;
	private Proxy<CollisionShape> mProxy = default;
	private StaticMesh mMesh = null ~ delete _;
	private Material mMaterial = null ~ delete _;

	public void AssetTypeNames(List<StringView> outNames) => outNames.Add("CollisionShapeAsset");

	public bool NeedsPrivateScene => false;

	public ThumbnailStageStep Stage(Guid id, Scene stage, ResourceManager resources, ref ThumbnailFraming outFraming)
	{
		let component = Ensure(stage);
		if (component == null)
			return .Failed;
		mProxy = resources.Bind<CollisionShape>(id);
		let shape = mProxy.Get;
		if (shape == null)
		{
			let handle = mProxy.Handle;
			if ((handle == null) || (handle.State == .Failed))
				return .Failed;
			return .Pending;
		}
		if (mMesh == null)
			mMesh = new StaticMesh();
		if (!CollisionOutlineMesh.Build(shape, mMesh))
			return .Failed; // cooked without display triangles
		component.Mesh.SetId(.());
		component.Mesh.SetDirect(mMesh);
		if (mMaterial == null)
			mMaterial = MaterialPresets.CreatePbr("ThumbCollisionDefault");
		component.SetMaterial(mMaterial);
		var t = Transform();
		t.Position = Float3.Zero - mMesh.Bounds.Center();
		stage.SetLocalTransform(mDisplay, t);
		outFraming.Radius = Math.Max(Length(mMesh.Bounds.Extents()), 0.05f);
		return .Ready;
	}

	public void Unstage(Scene stage)
	{
		if (let meshes = stage.GetSystem<MeshComponentManager>())
		{
			if (let component = meshes.Get(mDisplay))
			{
				component.Mesh.SetId(.());
				component.Mesh.SetDirect(null);
				component.Materials.Clear();
				component.MaterialCache.Clear();
			}
		}
		mProxy = default;
		if (mDisplay.IsAssigned && stage.IsValid(mDisplay))
			stage.SetActive(mDisplay, false);
		if (mSun.IsAssigned && stage.IsValid(mSun))
			stage.SetActive(mSun, false);
	}

	/// The display entity's mesh component, creating it and a key light on first use; null
	/// when the stage lacks the managers.
	private MeshComponent* Ensure(Scene stage)
	{
		let meshes = stage.GetSystem<MeshComponentManager>();
		let lights = stage.GetSystem<LightComponentManager>();
		if ((meshes == null) || (lights == null))
			return null;
		if (!mDisplay.IsAssigned || !stage.IsValid(mDisplay))
		{
			mDisplay = stage.CreateEntity("ThumbCollision");
			meshes.Add(mDisplay);
			mSun = stage.CreateEntity("ThumbCollisionSun");
			var t = Transform();
			t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.35f) * Quaternion.FromAxisAngle(.(1, 0, 0), -1.05f);
			stage.SetLocalTransform(mSun, t);
			let light = lights.Add(mSun);
			light.CastsShadows = false;
		}
		stage.SetActive(mDisplay, true);
		stage.SetActive(mSun, true);
		return meshes.Get(mDisplay);
	}
}
