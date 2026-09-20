using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Animation;
using Sedulous.Engine.Render;
using Sedulous.UI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// The preview half: the scene, the transport, the rig pickers with their preference, the
/// graph built for the player, and the per frame tick that draws the pose and rings the
/// active state on the canvas.
extension AnimationGraphEditorPage
{
	private void BuildPreviewScene()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
		if (scene == null)
			return;
		let sun = scene.CreateEntity("Sun");
		var st = Transform();
		st.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.35f) * Quaternion.FromAxisAngle(.(1, 0, 0), -1.05f);
		scene.SetLocalTransform(sun, st);
		if (let lights = scene.GetSystem<LightComponentManager>())
			lights.Add(sun).CastsShadows = false;
		mMeshEntity = scene.CreateEntity("PreviewMesh");
		if (let meshes = scene.GetSystem<MeshComponentManager>())
			meshes.Add(mMeshEntity);
	}

	private MeshComponent* PreviewComponent()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
		let meshes = (scene != null) ? scene.GetSystem<MeshComponentManager>() : null;
		return ((meshes != null) && mMeshEntity.IsAssigned) ? meshes.Get(mMeshEntity) : null;
	}

	/// Detaches the page's skinning matrices from the preview entity, ahead of deleting the
	/// player they point into.
	private void ClearPreviewOverrides()
	{
		if (let mc = PreviewComponent())
		{
			mc.Mesh.SetId(.());
			mc.Mesh.SetDirect(null);
			mc.BoneMatrices = null;
			mc.PrevBoneMatrices = null;
			mc.BoneCount = 0;
		}
	}

	private void DeletePlayer()
	{
		DeleteAndNullify!(mPlayer);
		DeleteAndNullify!(mPreviewGraph);
		mPlayerSkeleton = null;
	}

	private View BuildTransport()
	{
		let transport = new FlexLayout();
		transport.Direction = .Horizontal;
		transport.Spacing = 6.0f;
		transport.Padding = .(6, 4);

		mSkeletonButton = new Button("Skeleton: (none)");
		mSkeletonButton.OnClick.Add(new [=this](btn) => { PickPreviewSkeleton(); });
		transport.AddView(mSkeletonButton);
		mMeshButton = new Button("Mesh: (none)");
		mMeshButton.OnClick.Add(new [=this](btn) => { PickPreviewMesh(); });
		transport.AddView(mMeshButton);
		mPlayButton = new Button("Pause");
		mPlayButton.OnClick.Add(new [=this](btn) =>
			{
				mPreviewPlaying = !mPreviewPlaying;
				mPlayButton.SetText(mPreviewPlaying ? "Pause" : "Play");
			});
		transport.AddView(mPlayButton);
		let restart = new Button("Restart");
		restart.OnClick.Add(new [=this](btn) => { RebuildPreviewGraph(); });
		transport.AddView(restart);

		mSkeletonToggle = new Button("Bones: on");
		mSkeletonToggle.OnClick.Add(new [=this](btn) =>
			{
				mShowSkeleton = !mShowSkeleton;
				mSkeletonToggle.SetText(mShowSkeleton ? "Bones: on" : "Bones: off");
			});
		transport.AddView(mSkeletonToggle);
		mMeshToggle = new Button("Mesh: on");
		mMeshToggle.OnClick.Add(new [=this](btn) =>
			{
				mShowMesh = !mShowMesh;
				mMeshToggle.SetText(mShowMesh ? "Mesh: on" : "Mesh: off");
			});
		transport.AddView(mMeshToggle);

		mPreviewStatus = new Label();
		mPreviewStatus.FontSize.Value = 12.0f;
		mPreviewStatus.VAlign.Value = .Middle;
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		transport.AddView(mPreviewStatus, grow);
		return transport;
	}

	private void RefreshPickLabels()
	{
		let skeleton = scope String("Skeleton: ");
		AssetLabel(mSkeletonGuid, skeleton);
		mSkeletonButton.SetText(skeleton);
		let mesh = scope String("Mesh: ");
		AssetLabel(mPreviewMeshId, mesh);
		mMeshButton.SetText(mesh);
	}

	private void BindSkeleton()
	{
		mSkeleton.Forget();
		mSkeleton = default;
		if (!mSkeletonGuid.IsNil && (mContext.Resources != null))
		{
			mSkeleton = mContext.Resources.Bind<Skeleton>(mSkeletonGuid);
			mSkeleton.Retain();
		}
	}

	/// Points the preview entity at the mesh asset, bound through the manager so a late cook
	/// or a reload follows; nil clears it and the skinning with it.
	private void ApplyPreviewMesh()
	{
		let mc = PreviewComponent();
		if (mc == null)
			return;
		if (!mPreviewMeshId.IsNil && (mContext.Resources != null))
		{
			mc.Mesh.SetDirect(null);
			mc.Mesh.SetId(mPreviewMeshId);
			mc.Mesh.Bind(mContext.Resources);
		}
		else
		{
			mc.Mesh.SetId(.());
			mc.Mesh.SetDirect(null);
			mc.BoneMatrices = null;
			mc.BoneCount = 0;
		}
	}

	private void LoadPreviewPref()
	{
		if (!GraphPreviewPrefs.Load(mContext.ProjectEditorSettings, InstanceId, ref mSkeletonGuid, ref mPreviewMeshId))
			return;
		BindSkeleton();
		ApplyPreviewMesh();
		RefreshPickLabels();
	}

	private void SavePreviewPref()
	{
		if (GraphPreviewPrefs.Save(mContext.ProjectEditorSettings, InstanceId, mSkeletonGuid, mPreviewMeshId))
			mContext.RequestProjectEditorSettingsSave();
	}

	private void PickPreviewSkeleton()
	{
		let ctx = Ctx;
		if ((ctx == null) || (mContext.Project == null))
			return;
		let dialog = new AssetPickerDialog(mContext, scope StringView[]("SkeletonAsset"));
		dialog.OnPicked = new [=this](picked) =>
			{
				mSkeletonGuid = picked;
				BindSkeleton();
				RefreshPickLabels();
				RebuildPreviewGraph();
				SavePreviewPref();
			};
		dialog.Show(ctx);
	}

	private void PickPreviewMesh()
	{
		let ctx = Ctx;
		if ((ctx == null) || (mContext.Project == null))
			return;
		let dialog = new AssetPickerDialog(mContext, scope StringView[]("SkinnedMeshAsset"));
		dialog.OnPicked = new [=this](picked) =>
			{
				mPreviewMeshId = picked;
				ApplyPreviewMesh();
				RefreshPickLabels();
				SavePreviewPref();
			};
		dialog.Show(ctx);
	}

	/// Builds the runtime graph from the stored source and a player for it on the picked
	/// skeleton; nothing without a skeleton, a cooked one, or a layer.
	private void RebuildPreviewGraph()
	{
		ClearPreviewOverrides();
		DeletePlayer();
		mLastHighlightedNode = -1;
		if ((mAsset == null) || (mContext.Resources == null))
			return;
		let skeleton = mSkeleton.Get;
		if ((skeleton == null) || (skeleton.BoneCount <= 0))
			return;
		mDoc.Store(mAsset.Source);
		mPreviewGraph = new AnimationGraph();
		mAsset.Source.BuildInto(mContext.Resources, mPreviewGraph);
		if (mPreviewGraph.Layers.IsEmpty)
			return;
		mPlayer = new AnimationGraphPlayer(mPreviewGraph, skeleton);
		mPlayerSkeleton = skeleton;
	}

	private void UpdatePreview(float dt)
	{
		if (mSkeleton.Get !== mPlayerSkeleton)
			RebuildPreviewGraph();
		if (mPlayer == null)
		{
			if (mPreviewStatus != null)
				mPreviewStatus.SetText(mSkeletonGuid.IsNil ? "pick a skeleton to preview" : "(skeleton not cooked yet)");
			return;
		}
		if (mPreviewPlaying)
			mPlayer.Update(dt);

		let layerIndex = Math.Min(mSelectedLayer, (int32)mPreviewGraph.Layers.Count - 1);
		let current = mPlayer.GetCurrentStateIndex(layerIndex);
		if (mPreviewStatus != null)
		{
			let status = scope String();
			let layer = CurrentLayer;
			if ((layer != null) && layer.HasState(current))
				status.Append(layer.States[current].Name);
			if (mPlayer.IsTransitioning(layerIndex))
				status.Append("  (transitioning)");
			mPreviewStatus.SetText(status);
		}
		HighlightNode((current >= 0) ? StateToNode(current) : -1);

		if ((mPreview == null) || !mPreview.IsValid)
			return;
		let scene = mPreview.Scene;
		let mc = PreviewComponent();
		if ((scene != null) && (mc != null))
		{
			let meshVisible = mShowMesh && (mc.Mesh.Get != null);
			scene.SetActive(mMeshEntity, meshVisible);
			if (meshVisible)
			{
				let mats = mPlayer.GetSkinningMatrices();
				mc.BoneMatrices = mats.Ptr;
				mc.BoneCount = (uint32)mats.Length;
			}
		}

		let draw = mPreview.SceneDebugDraw;
		draw.DrawGrid(.(0.0f, 0.0f, 0.0f), 4.0f, 8, .(0.25f, 0.25f, 0.28f, 1.0f));
		if (mShowSkeleton)
			SkeletonWireframe.Draw(draw, mPlayerSkeleton, mPlayer.GetLocalPoses(), mWorldScratch);
	}
}
