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
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Materials;

/// The preview half: the scene, the material rebuilt from the source, the shape or mesh the
/// material draws on (chosen on the preview's bar), and the per material preview preference.
extension MaterialEditorPage
{
	private Sedulous.Scene.Scene PreviewScene => ((mPane != null) && (mPane.Viewport != null)) ? mPane.Viewport.Scene : null;

	/// The preview's bar: the shape the material is shown on, or a mesh of the project.
	private void AddPreviewControls()
	{
		mShapeChoice = new ComboBox();
		mShapeChoice.AddClass("preview-shape");
		mShapeChoice.Tooltip = "The shape the preview shows the material on";
		let items = scope String();
		for (let shape in MaterialPreviewShapes.Names)
		{
			if (!items.IsEmpty)
				items.Append('|');
			items.Append(shape);
		}
		mShapeChoice.ItemsText = items;
		// The user's pick only (its change event): a selection set from code (the page showing the
		// kept shape) must not count as a shape picked, which would put the kept mesh away.
		mShapeChoice.AddEventListener(.Changed, new [=this] (e) => { SetPreviewShape((uint32)Math.Max(0, mShapeChoice.SelectedIndex)); });
		mPane.AddControl(mShapeChoice);

		// Or a mesh from the project, its real UVs (an imported model), in place of the shape.
		mMeshSlot = new AssetPickerSlot();
		mMeshSlot.AddClass("preview-slot");
		mMeshSlot.Tooltip = "A mesh from the project to show the material on, in place of the shape";
		let refs = Services.Refs;
		mMeshSlot.AcceptTypesOf(refs, typeof(StaticMesh)); // what makes a StaticMesh, asked of the builders
		if ((refs != null) && (refs.Pick != null))
			mMeshSlot.SetOnPick(new [=this, =refs] () =>
				{
					refs.Pick(mMeshSlot.AcceptedTypes, mPreviewMeshGuid, new [=this] (picked) => { SetPreviewMesh(picked); });
				});
		mMeshSlot.SetOnClear(new [=this] () => { SetPreviewMesh(.()); });
		mMeshSlot.SetOnDropped(new [=this] (dropped) => { SetPreviewMesh(dropped); });
		mPane.AddControl(mMeshSlot);
	}

	/// The preview bar's choices as they are now.
	private void ShowPreviewChoices()
	{
		if ((mShapeChoice != null) && (mShapeChoice.SelectedIndex != (int32)mPreviewShape))
			mShapeChoice.SelectedIndex = (int32)mPreviewShape;
		if (mMeshSlot == null)
			return;
		let refs = Services.Refs;
		if (!mPreviewMeshGuid.IsNil && (refs != null) && (refs.Describe != null))
		{
			let shown = scope ResourceRefShown();
			if (refs.Describe(mPreviewMeshGuid, shown))
			{
				mMeshSlot.SetValue(shown.Name);
				mMeshSlot.SetGlyph(shown.Glyph, shown.GlyphClass);
				return;
			}
		}
		mMeshSlot.SetValue(""); // the shape
	}

	/// The preview world: the material's shape and a sun (the render subsystem gives the scene its
	/// default environment).
	private void BuildPreviewScene()
	{
		let scene = PreviewScene;
		if (scene == null)
			return;

		mShape = scene.CreateEntity("PreviewShape");
		mPreviewMesh = MaterialPreviewShapes.Build(0);
		if (let meshes = scene.GetSystem<MeshComponentManager>())
		{
			let mc = meshes.Add(mShape);
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

	/// Builds a runtime material from the source, as the resource factory would, and hands it to
	/// the preview entity. The previous one is deleted after the swap.
	private void RebuildPreviewMaterial()
	{
		let scene = PreviewScene;
		let asset = Edited;
		if ((asset == null) || (scene == null) || !mShape.IsAssigned)
			return;
		let src = asset.Source;

		// A shader asset draws under its resource's name (binding it registered the source).
		let shader = mShader.Get;
		let material = src.ToMaterial((shader != null) ? shader.Name : StringView(src.ShaderName));

		ForgetPreviewTextures();
		if (Context.Resources != null)
		{
			for (int i = 0; (i < src.TextureSlots.Count) && (i < src.TextureIds.Count); i++)
			{
				if (src.TextureIds[i].IsNil)
					continue;
				var proxy = Context.Resources.Bind<Texture>(src.TextureIds[i]);
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
			if (let mc = meshes.Get(mShape))
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
		let scene = PreviewScene;
		if ((scene == null) || !mShape.IsAssigned)
			return;
		if (let meshes = scene.GetSystem<MeshComponentManager>())
		{
			if (let mc = meshes.Get(mShape))
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
		MaterialPreviewPrefs.Load(Context.ProjectEditorSettings, InstanceId, ref mPreviewShape, ref mPreviewMeshGuid);
	}

	private void SavePreviewPref()
	{
		if (MaterialPreviewPrefs.Save(Context.ProjectEditorSettings, InstanceId, mPreviewShape, mPreviewMeshGuid))
			Context.RequestProjectEditorSettingsSave();
	}

	/// Puts the chosen mesh of the project, or the chosen shape, on the preview entity and frames
	/// the camera on it.
	private void ApplyPreviewMesh()
	{
		let scene = PreviewScene;
		if ((scene == null) || !mShape.IsAssigned)
			return;
		let meshes = scene.GetSystem<MeshComponentManager>();
		let mc = (meshes != null) ? meshes.Get(mShape) : null;
		if (mc == null)
			return;

		if (!mPreviewMeshGuid.IsNil && (Context.Resources != null))
		{
			mc.Mesh.SetDirect(null);
			DeleteAndNullify!(mPreviewMesh);
			mc.Mesh.SetId(mPreviewMeshGuid);
			mc.Mesh.Bind(Context.Resources);
			FramePreview();
			return;
		}

		let built = MaterialPreviewShapes.Build(mPreviewShape);
		mc.Mesh.SetId(.());
		mc.Mesh.SetDirect(built); // runtime built, not an asset
		delete mPreviewMesh;
		mPreviewMesh = built;
		FramePreview();
	}

	/// The orbit camera framed on what the preview shows.
	private void FramePreview()
	{
		let scene = PreviewScene;
		let meshes = (scene != null) ? scene.GetSystem<MeshComponentManager>() : null;
		let mc = ((meshes != null) && mShape.IsAssigned) ? meshes.Get(mShape) : null;
		let mesh = (mc != null) ? mc.Mesh.Get : null;
		var radius = 1.0f;
		var center = Float3(0.0f, 0.0f, 0.0f);
		if ((mesh != null) && (mesh.VertexCount > 0))
		{
			center = mesh.Bounds.Center();
			radius = Math.Max(0.25f, Length(mesh.Bounds.Extents()));
		}
		if ((mPane != null) && (mPane.Viewport != null))
			mPane.Viewport.Frame(center, radius);
	}
}
