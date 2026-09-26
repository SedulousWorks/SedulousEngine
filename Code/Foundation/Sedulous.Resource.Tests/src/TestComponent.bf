using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Resource.Tests;

/// A component holding a resource reference, to prove what a component stores. Its fields are
/// reflected at run time, as a real component's are through [Component].
[Serializable]
[Reflect(.NonStaticFields)]
class TestComponent
{
	public int32 SortOrder;
	public Ref<TestProduct> Mesh;
}
