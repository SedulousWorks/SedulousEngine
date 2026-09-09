using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.Render;

/// One view: WHAT to draw, being a shared scene snapshot, from WHERE, and INTO WHAT.
///
/// It owns its draw list. Pooled, so binding it for a new use keeps that list's storage
/// rather than freeing and reallocating it every frame.
class RenderView
{
	private ExtractedScene mScene = null;
	private ViewCamera mCamera = .();
	private ViewSettings mSettings = .();

	private ITextureView mTarget = null;
	private TextureFormat mTargetFormat = .BGRA8Unorm;
	/// The FULL target, which the colour import and the transient depth are sized to.
	private uint32 mWidth = 0;
	private uint32 mHeight = 0;

	private int32 mViewportX = 0;
	private int32 mViewportY = 0;
	private uint32 mViewportWidth = 0;
	private uint32 mViewportHeight = 0;

	/// Opaque debug draw lists, kept as raw pointers so this stays free of the debug module.
	private void* mDebugScene = null;
	private void* mDebugView = null;
	/// Opaque scene identity, handed to the overlay sources so their per scene state matches
	/// a view without the renderer knowing what a scene is.
	private void* mSceneKey = null;

	private List<DrawItem> mDrawList = new .() ~ delete _;
	private uint32 mSceneItemCount = 0;
	private uint32 mCulledCount = 0;

	/// Binds this view to a snapshot, a camera and a target for the current frame.
	public void Bind(ExtractedScene scene, ViewCamera camera, ViewSettings settings,
		ITextureView target, TextureFormat targetFormat, uint32 width, uint32 height)
	{
		mScene = scene;
		mCamera = camera;
		mSettings = settings;
		mTarget = target;
		mTargetFormat = targetFormat;
		mWidth = width;
		mHeight = height;

		// A stated viewport wins; otherwise the view covers the whole target.
		let hasViewport = settings.ViewportWidth > 0;
		mViewportX = hasViewport ? settings.ViewportX : 0;
		mViewportY = hasViewport ? settings.ViewportY : 0;
		mViewportWidth = hasViewport ? settings.ViewportWidth : width;
		mViewportHeight = (settings.ViewportHeight > 0) ? settings.ViewportHeight : height;

		mDrawList.Clear();
	}

	/// Builds this view's draw list from the bound snapshot: each renderable gets a view
	/// dependent sort key, and the list is then sorted.
	///
	/// With `cull` set, a renderable whose world bounding sphere falls entirely outside the
	/// camera's frustum is rejected first, which is the cheapest work there is.
	///
	/// CATEGORY GENERIC: it reads the base's own sort fields and the category's sort mode,
	/// never casting to a concrete type, so a mesh, a sprite and a particle all sort through
	/// this one path.
	public void BuildDrawList(List<DrawItem> sortScratch, bool cull = false)
	{
		mDrawList.Clear();
		mSceneItemCount = 0;
		mCulledCount = 0;

		if (mScene == null)
			return;

		let viewMatrix = mCamera.View;
		let inverseFar = (mCamera.FarZ > 0.0f) ? (1.0f / mCamera.FarZ) : 1.0f;

		var frustum = BoundingFrustum();
		if (cull)
			frustum = .(mCamera.ViewProjection);

		let categories = CategoryRegistry.Instance;

		for (let data in mScene.Items)
		{
			if (data == null)
				continue;

			mSceneItemCount++;

			if (cull && (Contains(frustum, BoundingSphere(data.WorldCenter, data.WorldRadius))
				== .Disjoint))
			{
				mCulledCount++;
				continue;
			}

			// Forward is negative Z in a right handed view space, so the distance ahead of
			// the camera is the negated Z.
			let viewCenter = TransformPoint(data.WorldCenter, viewMatrix);
			let depth01 = (-viewCenter.Z) * inverseFar;

			let backToFront = categories.Sort(data.Category) == .BackToFront;
			// A front to back category clusters by the producer's batch key, so identical
			// draws stay contiguous and can be fused; a back to front one zeroes it, so
			// depth dominates and the blend order survives.
			let stateBits = backToFront ? (uint32)0 : data.SortBatchKey;
			let depthBits = SortKeys.QuantizeDepth(depth01, backToFront);

			mDrawList.Add(.(SortKeys.MakeSortKey(data.Category, stateBits, depthBits), data));
		}

		DrawItemSorter.RadixSortDrawItems(mDrawList, sortScratch);
	}

	public ExtractedScene Scene => mScene;
	public ViewCamera Camera => mCamera;
	public ViewSettings Settings => mSettings;
	public ITextureView Target => mTarget;
	public TextureFormat TargetFormat => mTargetFormat;
	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public int32 ViewportX => mViewportX;
	public int32 ViewportY => mViewportY;
	public uint32 ViewportWidth => mViewportWidth;
	public uint32 ViewportHeight => mViewportHeight;

	public Span<DrawItem> DrawList => .(mDrawList.Ptr, mDrawList.Count);

	/// What the last build considered, and how much of it the frustum rejected. Both nought
	/// when culling was off, since nothing was tested.
	public uint32 SceneItemCount => mSceneItemCount;
	public uint32 CulledCount => mCulledCount;

	/// A SUB PIXEL jitter on the projection, so every downstream read of the view projection,
	/// the prepass, the forward and the sky alike, uses the same jittered matrix.
	///
	/// Row vector convention: offsetting the third row's first two components shifts clip
	/// space by the jitter times the clip w, which is a constant offset in pixels.
	public void ApplyProjectionJitter(float jitterX, float jitterY)
	{
		mCamera.Projection[2, 0] += jitterX;
		mCamera.Projection[2, 1] += jitterY;
	}

	/// The per SCENE debug draw list, which appears in every view of that scene: physics and
	/// navigation drawing.
	public void SetDebugScene(void* debugDraw) => mDebugScene = debugDraw;
	public void* DebugScene => mDebugScene;

	/// The per VIEW debug draw list, which appears ONLY here: an editor's grid and selection
	/// gizmos, which must not show up in a camera preview of the same scene.
	public void SetDebugView(void* debugDraw) => mDebugView = debugDraw;
	public void* DebugViewList => mDebugView;

	public void SetSceneKey(void* key) => mSceneKey = key;
	public void* SceneKey => mSceneKey;
}
