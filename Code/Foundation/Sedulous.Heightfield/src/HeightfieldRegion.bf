namespace Sedulous.Heightfield;

/// The INCLUSIVE grid rectangle a brush touched.
///
/// What a stroke's undo snapshots and what the renderer's re-upload can be bounded to.
/// Empty when nothing was in range, which is how a brush off the side of the grid reports
/// that it did nothing.
struct HeightfieldRegion
{
	public int32 MinX = int32.MaxValue;
	public int32 MinZ = int32.MaxValue;
	public int32 MaxX = -1;
	public int32 MaxZ = -1;

	public this() {}

	public bool IsEmpty => (MaxX < MinX) || (MaxZ < MinZ);
	public int32 Width => IsEmpty ? 0 : (MaxX - MinX + 1);
	public int32 Height => IsEmpty ? 0 : (MaxZ - MinZ + 1);

	public void Add(int32 gx, int32 gz) mut
	{
		MinX = (gx < MinX) ? gx : MinX;
		MinZ = (gz < MinZ) ? gz : MinZ;
		MaxX = (gx > MaxX) ? gx : MaxX;
		MaxZ = (gz > MaxZ) ? gz : MaxZ;
	}
}
