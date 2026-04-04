namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Entry in a sorted render data batch.
struct SortableRenderData
{
	/// Index into the category's data array.
	public int32 Index;

	/// Sorting key (lower = renders first).
	public uint64 SortKey;
}

/// A batch of sorted render data within a single category.
/// Passes iterate these to issue draw calls.
struct RenderDataBatch
{
	/// Sorted indices into the category's data array.
	public Span<SortableRenderData> Entries;
}

/// Per-view container of all extracted render data for one frame.
/// Component managers add data during extraction (PostTransform phase).
/// The renderer sorts and batches before passes execute.
class ExtractedRenderData : IDisposable
{
	// Per-category storage
	private List<MeshRenderData>[RenderCategories.Count] mMeshData;
	private List<LightRenderData> mLightData = new .() ~ delete _;
	private List<DecalRenderData> mDecalData = new .() ~ delete _;

	// Sorted batches (populated by SortAndBatch)
	private List<SortableRenderData>[RenderCategories.Count] mSortedBatches;

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
		{
			mMeshData[i] = new .();
			mSortedBatches[i] = new .();
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

	/// Adds a mesh render data entry to a category.
	public void AddMesh(RenderDataCategory category, MeshRenderData data)
	{
		if (category.Value < RenderCategories.Count)
			mMeshData[category.Value].Add(data);
	}

	/// Adds a light render data entry.
	public void AddLight(LightRenderData data)
	{
		mLightData.Add(data);
	}

	/// Adds a decal render data entry.
	public void AddDecal(DecalRenderData data)
	{
		mDecalData.Add(data);
	}

	// ==================== Sorting ====================

	/// Sorts all categories by their sort functions and builds batches.
	/// Call once after all data has been added, before rendering.
	public void SortAndBatch()
	{
		for (int i = 0; i < RenderCategories.Count; i++)
		{
			let category = RenderDataCategory((uint16)i);
			let sortFunc = RenderCategories.GetSortFunc(category);
			let meshes = mMeshData[i];
			let sorted = mSortedBatches[i];

			sorted.Clear();

			// Build sortable entries
			for (int32 j = 0; j < meshes.Count; j++)
			{
				sorted.Add(.()
				{
					Index = j,
					SortKey = sortFunc(meshes[j].Base, mViewMatrix)
				});
			}

			// Sort by key
			if (sorted.Count > 1)
			{
				sorted.Sort(scope (a, b) => {
					if (a.SortKey < b.SortKey) return -1;
					if (a.SortKey > b.SortKey) return 1;
					return 0;
				});
			}
		}
	}

	// ==================== Accessing Data ====================

	/// Gets the sorted batch for a category.
	public Span<SortableRenderData> GetSortedBatch(RenderDataCategory category)
	{
		if (category.Value < RenderCategories.Count)
			return mSortedBatches[category.Value];
		return default;
	}

	/// Gets the mesh render data array for a category.
	public Span<MeshRenderData> GetMeshData(RenderDataCategory category)
	{
		if (category.Value < RenderCategories.Count)
			return mMeshData[category.Value];
		return default;
	}

	/// Gets all light data.
	public Span<LightRenderData> Lights => mLightData;

	/// Gets all decal data.
	public Span<DecalRenderData> Decals => mDecalData;

	/// Gets mesh render data by sorted index.
	public ref MeshRenderData GetMesh(RenderDataCategory category, int32 sortedIndex)
	{
		let sorted = mSortedBatches[category.Value];
		return ref mMeshData[category.Value][sorted[sortedIndex].Index];
	}

	// ==================== Clear ====================

	/// Clears all data for reuse next frame.
	public void Clear()
	{
		for (int i = 0; i < RenderCategories.Count; i++)
		{
			mMeshData[i].Clear();
			mSortedBatches[i].Clear();
		}
		mLightData.Clear();
		mDecalData.Clear();
	}

	public ~this()
	{
		Dispose();
	}

	public void Dispose()
	{
		for (int i = 0; i < RenderCategories.Count; i++)
		{
			delete mMeshData[i];
			mMeshData[i] = null;
			delete mSortedBatches[i];
			mSortedBatches[i] = null;
		}
	}
}
