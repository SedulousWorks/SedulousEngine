namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using Sedulous.Core.Mathematics;
using Sedulous.Renderer;
using Sedulous.Renderer.Passes;
using Sedulous.RHI;

/// Editor page for previewing .skeleton files in a 3D viewport.
///
/// Has no mesh - just debug-draws the bone hierarchy as colored lines so the
/// shape and orientation are visible. World bind poses are computed once at
/// construction by walking parents-before-children.
class SkeletonEditorPage : IEditorPage
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;

	private SkeletonResource mSkeletonRes;
	private PreviewSceneHost mHost ~ delete _;

	// Cached world-space bone positions (in bind pose) for debug draw.
	private Vector3[] mBoneWorldPositions ~ delete _;

	public this(StringView filePath, SkeletonResource skeleton, PreviewSceneHost host)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mSkeletonRes = skeleton;
		mHost = host;
		UpdateTitle();

		ComputeWorldBindPositions();

		// Frame the camera around the bone cloud.
		mHost.FitToBounds(ComputeBounds());

		// Inject debug-draw lines each frame before the scene renders.
		mHost.OnPreRender.Add(new => DrawSkeletonOverlay);
	}

	public ~this()
	{
		if (mSkeletonRes != null)
			mSkeletonRes.ReleaseRef();
	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => false;
	public EditorCommandStack CommandStack => mCommandStack;
	public StringView SaveFileExtension => "";  // read-only preview

	public SkeletonResource Skeleton => mSkeletonRes;
	public PreviewSceneHost Host => mHost;

	public void SetContentView(View view) { mContentView = view; }

	public void Save() { }
	public void SaveAs(StringView path) { }
	public void OnActivated() { }
	public void OnDeactivated() { }
	public void Update(float deltaTime) { }

	public void Dispose()
	{
		delete mContentView;
		mContentView = null;
	}

	private void UpdateTitle()
	{
		mTitle.Clear();
		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(mFilePath, name);
		mTitle.Set(name);
	}

	private void ComputeWorldBindPositions()
	{
		let skeleton = mSkeletonRes?.Skeleton;
		if (skeleton == null || skeleton.Bones.Count == 0) return;

		let count = skeleton.Bones.Count;
		mBoneWorldPositions = new Vector3[count];

		// Walk parents-before-children. The skeleton ensures bones[parentIndex]
		// has parentIndex < own index for any valid import (DCC tools enforce
		// hierarchical order); we fall back to a fixed-point loop otherwise.
		Matrix[] worldMatrices = scope Matrix[count];
		bool[] resolved = scope bool[count];
		int resolvedCount = 0;
		int safetyPasses = 0;

		while (resolvedCount < count && safetyPasses < count + 2)
		{
			for (int i = 0; i < count; i++)
			{
				if (resolved[i]) continue;
				let bone = skeleton.Bones[i];
				if (bone == null) { resolved[i] = true; resolvedCount++; continue; }

				let local = bone.LocalBindPose.ToMatrix();
				if (bone.ParentIndex < 0)
				{
					worldMatrices[i] = bone.RootCorrection * local;
					resolved[i] = true;
					resolvedCount++;
				}
				else if (resolved[bone.ParentIndex])
				{
					worldMatrices[i] = local * worldMatrices[bone.ParentIndex];
					resolved[i] = true;
					resolvedCount++;
				}
			}
			safetyPasses++;
		}

		for (int i = 0; i < count; i++)
			mBoneWorldPositions[i] = worldMatrices[i].Translation;
	}

	private BoundingBox ComputeBounds()
	{
		if (mBoneWorldPositions == null || mBoneWorldPositions.Count == 0)
			return .(Vector3(-1, -1, -1), Vector3(1, 1, 1));

		var min = mBoneWorldPositions[0];
		var max = mBoneWorldPositions[0];
		for (let p in mBoneWorldPositions)
		{
			min = Vector3.Min(min, p);
			max = Vector3.Max(max, p);
		}

		// Pad slightly so a degenerate (single-bone) skeleton still has visible extent.
		let pad = Vector3(0.25f, 0.25f, 0.25f);
		return .(min - pad, max + pad);
	}

	private void DrawSkeletonOverlay(PreviewSceneHost host, ICommandEncoder encoder, int32 frameIndex)
	{
		let skeleton = mSkeletonRes?.Skeleton;
		if (skeleton == null || mBoneWorldPositions == null) return;

		let renderer = host.SceneRenderer;
		if (renderer == null) return;

		let pipeline = renderer.GetPipeline(host.PreviewScene);
		let debug = (pipeline != null) ? pipeline.DebugDraw : renderer.RenderContext.DebugDraw;
		if (debug == null) return;

		let boneColor = Color32(220, 220, 100, 255);
		let jointColor = Color32(255, 180, 80, 255);

		for (int i = 0; i < skeleton.Bones.Count; i++)
		{
			let bone = skeleton.Bones[i];
			if (bone == null) continue;

			let pos = mBoneWorldPositions[i];

			// Joint marker - a small axis cross.
			let s = 0.04f;
			debug.DrawLine(pos - Vector3(s, 0, 0), pos + Vector3(s, 0, 0), jointColor);
			debug.DrawLine(pos - Vector3(0, s, 0), pos + Vector3(0, s, 0), jointColor);
			debug.DrawLine(pos - Vector3(0, 0, s), pos + Vector3(0, 0, s), jointColor);

			// Bone segment to parent.
			if (bone.ParentIndex >= 0 && bone.ParentIndex < mBoneWorldPositions.Count)
				debug.DrawLine(mBoneWorldPositions[bone.ParentIndex], pos, boneColor);
		}
	}
}
