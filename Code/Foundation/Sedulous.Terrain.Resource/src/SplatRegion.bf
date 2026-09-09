namespace Sedulous.Terrain.Resource;

/// The INCLUSIVE texel rectangle a paint touched.
///
/// What a stroke's undo snapshots, and what the GPU re-upload can be bounded to. Empty when
/// nothing was in range.
struct SplatRegion
{
	public int32 MinX = int32.MaxValue;
	public int32 MinY = int32.MaxValue;
	public int32 MaxX = -1;
	public int32 MaxY = -1;

	public this() {}

	public bool IsEmpty => (MaxX < MinX) || (MaxY < MinY);
	public int32 Width => IsEmpty ? 0 : (MaxX - MinX + 1);
	public int32 Height => IsEmpty ? 0 : (MaxY - MinY + 1);

	public void Add(int32 x, int32 y) mut
	{
		MinX = (x < MinX) ? x : MinX;
		MinY = (y < MinY) ? y : MinY;
		MaxX = (x > MaxX) ? x : MaxX;
		MaxY = (y > MaxY) ? y : MaxY;
	}
}
