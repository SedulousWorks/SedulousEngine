using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Geometry;
using Sedulous.Animation;
using Sedulous.Engine.Render;
using Sedulous.UI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// The preview half: the scene, the skeleton and mesh pickers with their preference, and
/// the per frame sample.
extension AnimationClipEditorPage
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
		{
			let light = lights.Add(sun);
			light.CastsShadows = false;
		}

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

	private void PickLabel(StringView prefix, Guid id, String outLabel)
	{
		outLabel.Set(prefix);
		if ((mContext.Project != null) && !id.IsNil)
		{
			let inst = mContext.Project.SourceDb.GetInstance(id);
			outLabel.Append((inst != null) ? inst.Name : "(missing)");
		}
		else
			outLabel.Append("(none)");
	}

	private void RefreshPickLabels()
	{
		if (mSkeletonButton != null)
			mSkeletonButton.SetText(PickLabel("Skeleton: ", mSkeletonGuid, .. scope .()));
		if (mMeshButton != null)
			mMeshButton.SetText(PickLabel("Mesh: ", mPreviewMeshId, .. scope .()));
	}

	private void LoadPreviewPref()
	{
		if (!ClipPreviewPrefs.Load(mContext.ProjectEditorSettings, InstanceId, ref mSkeletonGuid, ref mPreviewMeshId))
			return;
		BindSkeleton();
		ApplyPreviewMesh();
		RefreshPickLabels();
	}

	private void SavePreviewPref()
	{
		if (ClipPreviewPrefs.Save(mContext.ProjectEditorSettings, InstanceId, mSkeletonGuid, mPreviewMeshId))
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

	/// Advances the playhead, samples the clip on the skeleton, skins the mesh when there
	/// is one and draws the wireframe.
	private void UpdatePreview(float dt)
	{
		let clip = mClip.Get;
		let skeleton = mSkeleton.Get;
		if ((clip == null) || (clip.Duration <= 0.0f))
		{
			if (mTimeLabel != null)
				mTimeLabel.SetText("(clip not cooked)");
			return;
		}

		if (mPlaying)
		{
			mTime += dt;
			if (mTime > clip.Duration)
			{
				mTime = clip.IsLooping ? (mTime % clip.Duration) : clip.Duration;
				if (!clip.IsLooping)
				{
					mPlaying = false;
					mPlayButton.SetText("Play");
				}
			}
			mScrubbing = true;
			mTimeSlider.Value.Value = mTime / clip.Duration;
			mScrubbing = false;
		}
		if (mTimeLabel != null)
			mTimeLabel.SetText(scope $"{Truncated(mTime):F2}s / {Truncated(clip.Duration):F2}s");

		let scene = (mPreview != null) ? mPreview.Scene : null;
		if ((skeleton == null) || (skeleton.BoneCount <= 0) || (scene == null) || !mPreview.IsValid)
			return;
		let boneCount = skeleton.BoneCount;
		mPoseScratch.Count = boneCount;
		AnimationSampler.SampleClip(clip, skeleton, mTime, mPoseScratch);

		let mc = PreviewComponent();
		if ((mc != null) && (mc.Mesh.Get != null))
		{
			if ((mPreviewPlayer == null) || (mPlayerSkeleton !== skeleton))
			{
				mc.BoneMatrices = null;
				mc.BoneCount = 0;
				delete mPreviewPlayer;
				mPreviewPlayer = new AnimationPlayer(skeleton);
				mPlayerSkeleton = skeleton;
				mPlayerClip = null;
			}
			if (mPlayerClip !== clip)
			{
				mPlayerClip = clip;
				mPreviewPlayer.Play(clip);
			}
			mPreviewPlayer.SetCurrentTime(mTime);
			mPreviewPlayer.Update(0.0f); // resample at mTime without advancing
			let mats = mPreviewPlayer.GetSkinningMatrices();
			mc.BoneMatrices = mats.Ptr;
			mc.BoneCount = (uint32)mats.Length;
		}

		let draw = mPreview.SceneDebugDraw;
		draw.DrawGrid(.(0.0f, 0.0f, 0.0f), 4.0f, 8, .(0.25f, 0.25f, 0.28f, 1.0f));
		SkeletonWireframe.Draw(draw, skeleton, mPoseScratch, mWorldScratch);
	}

	/// To hundredths, so the label does not flicker through float noise.
	private static float Truncated(float seconds) => (float)(int)(seconds * 100.0f) / 100.0f;
}
