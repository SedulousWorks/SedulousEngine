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

	// Scratch buffers for radix sort. Per-view instance; safe under parallel
	// view extraction since each view has its own ExtractedRenderData.
	private struct SortPair
	{
		public uint64 Key;
		public RenderData Value;
	}
	private List<SortPair> mSortPairsA = new .() ~ delete _;
	private List<SortPair> mSortPairsB = new .() ~ delete _;

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

	/// Sorts each category in place by entry.SortKey. Assumes SortKey was
	/// already populated by the extractor (inline during the parallel
	/// extraction pass). Use this instead of SortAndBatch when the
	/// extractor knows how to compute its own sort key.
	///
	/// Uses LSD radix sort on the uint64 SortKey - O(N) instead of the
	/// O(N log N) of a comparison sort, with much better cache behavior
	/// (key+ptr pairs are 16 bytes and traversed sequentially per pass).
	public void SortOnly()
	{
		for (int i = 0; i < RenderCategories.Count; i++)
		{
			let list = mCategories[i];
			if (list.Count > 1)
				RadixSortByKey(list);
		}
	}

	/// LSD radix sort by uint64 SortKey: 8 byte-level passes, each pass
	/// distributes (key, ptr) pairs into 256 bins by one byte of the key.
	/// Buffers ping-pong; after 8 passes the sorted result is back in mSortPairsA.
	private void RadixSortByKey(List<RenderData> list)
	{
		let n = list.Count;
		mSortPairsA.Count = n;
		mSortPairsB.Count = n;

		// Seed the working buffer with (key, ptr) pairs.
		for (int i = 0; i < n; i++)
		{
			let entry = list[i];
			mSortPairsA[i] = .() { Key = entry.SortKey, Value = entry };
		}

		uint32[256] hist = ?;
		bool sourceIsA = true;

		for (int pass = 0; pass < 8; pass++)
		{
			let shift = pass * 8;
			let src = sourceIsA ? mSortPairsA : mSortPairsB;
			let dst = sourceIsA ? mSortPairsB : mSortPairsA;

			// Histogram: count entries per bucket.
			for (int b = 0; b < 256; b++) hist[b] = 0;
			for (int i = 0; i < n; i++)
				hist[(uint8)(src[i].Key >> shift)]++;

			// Prefix-sum into write offsets per bucket (turns hist into "next write pos").
			uint32 sum = 0;
			for (int b = 0; b < 256; b++)
			{
				let c = hist[b];
				hist[b] = sum;
				sum += c;
			}

			// Scatter into dst at the bucketed offset.
			for (int i = 0; i < n; i++)
			{
				let entry = src[i];
				let bucket = (uint8)(entry.Key >> shift);
				dst[hist[bucket]] = entry;
				hist[bucket]++;
			}

			sourceIsA = !sourceIsA;
		}

		// 8 passes is even -> sorted result is back in mSortPairsA. Write
		// ordered pointers back into the category list.
		for (int i = 0; i < n; i++)
			list[i] = mSortPairsA[i].Value;
	}

	/// Computes sort keys and sorts each category in place. Retained for
	/// callers that don't populate SortKey during extraction; new code
	/// should inline SortKey and call SortOnly() instead.
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

	// ==================== Sort key helpers (extractor-inline use) ====================

	/// Compute the front-to-back sort key for opaque / masked geometry.
	/// Material key in the upper 32 bits (minimize state changes), view-space
	/// depth in the lower 32 (closer first). Mirrors RenderCategories.SortFrontToBack.
	public static uint64 ComputeFrontToBackSortKey(Vector3 worldPos, in Matrix viewMatrix, uint32 materialKey)
	{
		let viewPos = Vector3.Transform(worldPos, viewMatrix);
		let depth = Math.Max(viewPos.Z, 0);
		uint32 depthBits = (uint32)(depth * 1000.0f);
		return ((uint64)materialKey << 32) | (uint64)depthBits;
	}

	/// Compute the back-to-front sort key for transparent / particle geometry.
	/// Inverted depth so further objects sort first. Mirrors
	/// RenderCategories.SortBackToFront.
	public static uint64 ComputeBackToFrontSortKey(Vector3 worldPos, in Matrix viewMatrix)
	{
		let viewPos = Vector3.Transform(worldPos, viewMatrix);
		let depth = Math.Max(viewPos.Z, 0);
		uint32 depthBits = (uint32)(depth * 1000.0f);
		return (uint64)(uint32.MaxValue - depthBits);
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
