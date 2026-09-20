using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Texture.Resource;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Engine.Render;

namespace Sedulous.Editor.Scene;

/// The preview half: the scene, the material rebuilt from the source, the shape or mesh
/// asset the material draws on, and the per material preview preference.
extension MaterialEditorPage
{
	private void BuildPreviewScene()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
		if (scene == null)
			return;

		mSphere = scene.CreateEntity("PreviewSphere");
		mPreviewMesh = Primitives.Sphere(1.0f, 48, 24);
		if (let meshes = scene.GetSystem<MeshComponentManager>())
		{
			let mc = meshes.Add(mSphere);
			mc.Mesh.SetDirect(mPreviewMesh); // runtime built, not an asset
		}

		let sun = scene.CreateEntity("Sun");
		var t = Transform();
		t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.35f) * Quaternion.FromAxisAngle(.(1, 0, 0), -1.05f);
		scene.SetLocalTransform(sun, t);
		if (let lights = scene.GetSystem<LightComponentManager>())
		{
			let light = lights.Add(sun);
			light.CastsShadows = false; // a lone shape has nothing to shadow
		}
	}

	/// Builds a runtime material from the source, as the resource factory would, and hands
	/// it to the preview entity. The previous one is deleted after the swap.
	private void RebuildPreviewMaterial()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
		if ((mAsset == null) || (scene == null) || !mSphere.IsAssigned)
			return;
		let src = mAsset.Source;

		let material = new Material();
		material.Name.Set(src.Name);
		material.ShaderName.Set(src.ShaderName);
		material.ShaderFlags = (ShaderFlags)src.ShaderFlags;
		for (int i < src.PropertyNames.Count)
		{
			var d = MaterialPropertyDef();
			d.Name = src.PropertyNames[i];
			d.Type = (i < src.PropertyTypes.Count) ? (MaterialPropertyType)src.PropertyTypes[i] : .Float;
			d.Binding = (i < src.PropertyBindings.Count) ? src.PropertyBindings[i] : 0;
			d.Offset = (i < src.PropertyOffsets.Count) ? src.PropertyOffsets[i] : 0;
			d.Size = (i < src.PropertySizes.Count) ? src.PropertySizes[i] : 0;
			material.AddProperty(d);
		}
		material.AllocateDefaultUniformData();
		material.SetRawDefaultUniformData(src.UniformDefaults);
		material.Pipeline = .();
		material.Pipeline.ShaderName = material.ShaderName;
		material.Pipeline.ShaderFlags = material.ShaderFlags;
		material.Pipeline.BlendMode = src.BlendMode;
		material.Pipeline.DepthMode = src.DepthMode;
		material.Pipeline.CullMode = src.CullMode;
		material.Pipeline.VertexLayout = src.VertexLayout;
		material.SamplerU = (AddressMode)src.SamplerU;
		material.SamplerV = (AddressMode)src.SamplerV;

		ForgetPreviewTextures();
		if (mContext.Resources != null)
		{
			for (int i = 0; (i < src.TextureSlots.Count) && (i < src.TextureIds.Count); i++)
			{
				if (src.TextureIds[i].IsNil)
					continue;
				var proxy = mContext.Resources.Bind<Texture>(src.TextureIds[i]);
				proxy.Retain();
				let texture = proxy.Get;
				let view = (texture != null) ? texture.View : null;
				mPreviewTextures.Add(proxy);
				mPreviewTextureViews.Add(view);
				if (view != null)
					material.SetDefaultTexture(src.TextureSlots[i], view);
			}
		}

		let previous = mPreviewMaterial;
		mPreviewMaterial = material;
		if (let meshes = scene.GetSystem<MeshComponentManager>())
		{
			if (let mc = meshes.Get(mSphere))
				mc.SetMaterial(mPreviewMaterial); // direct override
		}
		delete previous;
	}

	private void ForgetPreviewTextures()
	{
		for (var proxy in ref mPreviewTextures)
			proxy.Forget();
		mPreviewTextures.Clear();
		mPreviewTextureViews.Clear();
	}

	/// Detaches the page's mesh and material from the preview entity, ahead of deleting them.
	private void ClearPreviewOverrides()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
		if ((scene == null) || !mSphere.IsAssigned)
			return;
		if (let meshes = scene.GetSystem<MeshComponentManager>())
		{
			if (let mc = meshes.Get(mSphere))
			{
				mc.Mesh.SetId(.());
				mc.Mesh.SetDirect(null);
				mc.Materials.Clear();
				mc.MaterialCache.Clear();
			}
		}
	}

	private void LoadPreviewPref()
	{
		MaterialPreviewPrefs.Load(mContext.ProjectEditorSettings, InstanceId, ref mPreviewShape, ref mPreviewMeshGuid);
	}

	private void SavePreviewPref()
	{
		if (MaterialPreviewPrefs.Save(mContext.ProjectEditorSettings, InstanceId, mPreviewShape, mPreviewMeshGuid))
			mContext.RequestProjectEditorSettingsSave();
	}

	/// Puts the chosen mesh asset, or the chosen primitive, on the preview entity and frames
	/// the camera on it.
	private void ApplyPreviewMesh()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
		if ((scene == null) || !mSphere.IsAssigned)
			return;
		let meshes = scene.GetSystem<MeshComponentManager>();
		let mc = (meshes != null) ? meshes.Get(mSphere) : null;
		if (mc == null)
			return;

		if (!mPreviewMeshGuid.IsNil && (mContext.Resources != null))
		{
			mc.Mesh.SetDirect(null);
			delete mPreviewMesh;
			mPreviewMesh = null;
			mc.Mesh.SetId(mPreviewMeshGuid);
			mc.Mesh.Bind(mContext.Resources);
			FramePreview(mc.Mesh.Get);
			return;
		}

		let built = MaterialPreviewShapes.Build(mPreviewShape);
		mc.Mesh.SetId(.());
		mc.Mesh.SetDirect(built); // runtime built, not an asset
		delete mPreviewMesh;
		mPreviewMesh = built;
		FramePreview(mPreviewMesh);
	}

	private void FramePreview(StaticMesh mesh)
	{
		var radius = 1.0f;
		var center = Float3(0.0f, 0.0f, 0.0f);
		if ((mesh != null) && (mesh.VertexCount > 0))
		{
			center = mesh.Bounds.Center();
			radius = Math.Max(0.25f, Length(mesh.Bounds.Extents()));
		}
		if (mPreview != null)
			mPreview.Camera.FrameBounds(center, radius);
	}
}
