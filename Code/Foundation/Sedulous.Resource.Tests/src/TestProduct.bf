namespace Sedulous.Resource.Tests;

/// The PRODUCT: what the game actually uses, built from a source by a factory. Lean, with
/// nothing the editor needed.
class TestProduct
{
	public static int Destroyed;

	public int32 Area;
	public int32 BuildCount;

	public ~this()
	{
		Destroyed++;
	}
}
