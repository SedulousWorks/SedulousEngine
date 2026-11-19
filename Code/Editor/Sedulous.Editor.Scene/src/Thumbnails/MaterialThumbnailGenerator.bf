using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Engine.Render;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// A material on a unit sphere.
class MaterialThumbnailGenerator : ISceneThumbnailGenerator
{
	private ThumbnailStageEntities mEntities = new .() ~ delete _;
	private Proxy<Material> mProxy = default;
	/// What the stage draws, held while it is staged: the stage reads the product directly, so
	/// no reference names it.
	private ResourceHold mHold = null ~ _?.Release();
	private StaticMesh mSphere = null ~ delete _;

	public void AssetTypeNames(List<StringView> outNames) => outNames.Add("MaterialAsset");

	public bool NeedsPrivateScene => false;

	public ThumbnailStageStep Stage(Guid id, Sedulous.Scene.Scene stage, ResourceManager resources,
		ref ThumbnailFraming outFraming)
	{
		let component = mEntities.Ensure(stage, "ThumbSphere");
		if (component == null)
			return .Failed;
		if (mSphere == null)
			mSphere = Primitives.Sphere(1.0f, 48, 24);
		mProxy = resources.Bind<Material>(id);
		let material = mProxy.Get;
		if (material == null)
			return ThumbnailStaging.StepForPending(mProxy);
		if ((mHold == null) || (mHold.Handle !== mProxy.Handle))
			ResourceHold.Replace(ref mHold, mProxy.Handle);
		component.Mesh.SetId(.());
		component.Mesh.SetDirect(mSphere);
		component.SetMaterial(material);
		stage.SetLocalTransform(mEntities.Display, .());
		outFraming.Radius = 1.0f;
		return .Ready;
	}

	public void Unstage(Sedulous.Scene.Scene stage)
	{
		if (let meshes = stage.GetSystem<MeshComponentManager>())
		{
			if (let component = meshes.Get(mEntities.Display))
			{
				component.Mesh.SetId(.());
				component.Mesh.SetDirect(null);
				component.Materials.Clear();
				component.MaterialCache.Clear();
			}
		}
		mProxy = default;
		ResourceHold.Drop(ref mHold);
		mEntities.Deactivate(stage);
	}
}
