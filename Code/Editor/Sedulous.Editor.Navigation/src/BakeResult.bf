namespace Sedulous.Editor.Navigation;

struct BakeResult
{
	/// A navmesh was produced and written.
	public bool Baked = false;
	/// The input triangles collected.
	public int TriangleCount = 0;
	/// The zone's Cell Size or Cell Height is not a positive number: nothing was baked.
	public bool UnusableCells = false;
}
