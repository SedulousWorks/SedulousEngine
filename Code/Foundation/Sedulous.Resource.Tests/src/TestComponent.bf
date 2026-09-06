using Sedulous.Core.Serialization;

namespace Sedulous.Resource.Tests;

/// A component holding a resource reference, to prove what a component stores.
[Serializable]
class TestComponent
{
	public int32 SortOrder;
	public Ref<TestProduct> Mesh;
}
