using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// A mesh asset, centred, in a default PBR material.
class MeshThumbnailGenerator : ISceneThumbnailGenerator
{
	private ThumbnailStageEntities mEntities = new .() ~ delete _;
	private Proxy<StaticMesh> mProxy = default;
	private Material mMaterial = null ~ delete _;

	public void AssetTypeNames(List<StringView> outNames)
	{
		outNames.Add("StaticMeshAsset");
		outNames.Add("SkinnedMeshAsset");
	}

	public bool NeedsPrivateScene => false;

	public ThumbnailStageStep Stage(Guid id, Sedulous.Scene.Scene stage, ResourceManager resources,
		ref ThumbnailFraming outFraming)
	{
		let component = mEntities.Ensure(stage, "ThumbMesh");
		if (component == null)
			return .Failed;
		mProxy = resources.Bind<StaticMesh>(id);
		let mesh = mProxy.Get;
		if (mesh == null)
			return ThumbnailStaging.StepForPending(mProxy);
		component.Mesh.SetId(.());
		component.Mesh.SetDirect(mesh); // the cooked product, directly
		if (mMaterial == null)
			mMaterial = MaterialPresets.CreatePbr("ThumbMeshDefault");
		component.SetMaterial(mMaterial);

		var t = Transform();
		t.Position = Float3.Zero - mesh.Bounds.Center();
		stage.SetLocalTransform(mEntities.Display, t);
		outFraming.Radius = Max(Length(mesh.Bounds.Extents()), 0.05f);
		return .Ready;
	}

	public void Unstage(Sedulous.Scene.Scene stage)
	{
		ThumbnailStaging.ClearDisplayMesh(stage, mEntities.Display);
		mProxy = default;
		mEntities.Deactivate(stage);
	}
}
