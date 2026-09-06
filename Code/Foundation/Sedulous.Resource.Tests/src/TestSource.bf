using Sedulous.Core.Serialization;

namespace Sedulous.Resource.Tests;

/// The SOURCE object: full authoring fidelity, stored in the content database.
[Serializable]
class TestSource
{
	public int32 Width;
	public int32 Height;
	/// Editor-only, and deliberately so: it is stored on the source and must never reach
	/// the product.
	public int32 EditorNotePosition;
}
