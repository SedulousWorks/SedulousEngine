namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Per-view container of all extracted render data for one frame.
/// Component managers add data during extraction (PostTransform phase).
/// The renderer sorts and batches before passes execute.
///
/// Storage is polymorphic - each category holds a List<RenderData>, and entries
/// are subclasses (MeshRenderData, LightRenderData, DecalRenderData, etc.).
/// The RenderData instances are allocated from RenderContext.FrameAllocator and
/// are only valid until the next BeginFrame() - Clear() drops the references
/// before the allocator is reset.
public class ExtractedRenderData
{
	// Per-category storage (polymorphic - each entry is a RenderData subclass).
	// Lists themselves are retained across frames; element pointers come from the
	// frame allocator and are dropped on Clear().
	private List<RenderData>[RenderCategories.Count] mCategories;

	// View info
	private Matrix mViewMatrix;
	private Matrix mProjectionMatrix;
	private Matrix mViewProjectionMatrix;
	private Vector3 mCameraPosition;
	private float mNearPlane;
	private float mFarPlane;
	private uint32 mViewWidth;
	private uint32 mViewHeight;

	public this()
	{
		for (int i = 0; i < RenderCategories.Count; i++)
			mCategories[i] = new .();
	}

	public ~this()
	{
		for (int i = 0; i < RenderCategories.Count; i++)
		{
			delete mCategories[i];
			mCategories[i] = null;
		}
	}

	// ==================== View Setup ====================

	/// Sets the camera/view data for this frame.
	public void SetView(Matrix view, Matrix projection, Vector3 cameraPosition,
		float nearPlane, float farPlane, uint32 width, uint32 height)
	{
		mViewMatrix = view;
		mProjectionMatrix = projection;
		mViewProjectionMatrix = view * projection;
		mCameraPosition = cameraPosition;
		mNearPlane = nearPlane;
		mFarPlane = farPlane;
		mViewWidth = width;
		mViewHeight = height;
	}

	public Matrix ViewMatrix => mViewMatrix;
	public Matrix ProjectionMatrix => mProjectionMatrix;
	public Matrix ViewProjectionMatrix => mViewProjectionMatrix;
	public Vector3 CameraPosition => mCameraPosition;
	public float NearPlane => mNearPlane;
	public float FarPlane => mFarPlane;
	public uint32 ViewWidth => mViewWidth;
	public uint32 ViewHeight => mViewHeight;

	// ==================== Adding Data ====================

	/// Adds a render data entry to a category.
	/// The data pointer must have been allocated from RenderContext.FrameAllocator -
	/// it is held by reference until Clear() is called.
	public void Add(RenderDataCategory category, RenderData data)
	{
		if (category.Value < RenderCategories.Count)
			mCategories[category.Value].Add(data);
	}

	// ==================== Sorting ====================

	/// Computes sort keys and sorts each category in place.
	/// Call once after all data has been added, before rendering.
	public void SortAndBatch()
	{
		for (int i = 0; i < RenderCategories.Count; i++)
		{
			let category = RenderDataCategory((uint16)i);
			let sortFunc = RenderCategories.GetSortFunc(category);
			let list = mCategories[i];

			// Compute sort keys on the entries themselves
			for (let entry in list)
				entry.SortKey = sortFunc(entry, mViewMatrix);

			// In-place sort by SortKey (lower = renders first)
			if (list.Count > 1)
			{
				list.Sort(scope (a, b) => {
					if (a.SortKey < b.SortKey) return -1;
					if (a.SortKey > b.SortKey) return 1;
					return 0;
				});
			}
		}
	}

	// ==================== Accessing Data ====================

	/// Gets the (sorted) render data list for a category.
	/// Entries are base RenderData - cast to the concrete subclass expected for the category.
	public List<RenderData> GetBatch(RenderDataCategory category)
	{
		if (category.Value < RenderCategories.Count)
			return mCategories[category.Value];
		return null;
	}

	/// Convenience: number of entries in a category.
	public int32 GetBatchCount(RenderDataCategory category)
	{
		if (category.Value < RenderCategories.Count)
			return (int32)mCategories[category.Value].Count;
		return 0;
	}

	/// Convenience: the Light category list (cast-ready for LightBuffer).
	public List<RenderData> Lights => mCategories[RenderCategories.Light.Value];

	/// Convenience: the Decal category list.
	public List<RenderData> Decals => mCategories[RenderCategories.Decal.Value];

	// ==================== Clear ====================

	/// Clears all data references for the next frame.
	/// MUST be called before RenderContext.BeginFrame() resets the frame allocator,
	/// otherwise the lists would dangle at arena-rewound memory.
	public void Clear()
	{
		for (int i = 0; i < RenderCategories.Count; i++)
			mCategories[i].Clear();
	}
}
