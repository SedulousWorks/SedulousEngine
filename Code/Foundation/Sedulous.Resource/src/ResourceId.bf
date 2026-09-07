using System;

namespace Sedulous.Resource;

/// A Guid that also says what it names.
///
/// A bare Guid is a resource of unknown type: every bind has to be told the product type
/// separately, and nothing checks that the two agree. Carrying the type in the id means a
/// field declares what it points at, and a bind of the wrong type does not compile.
struct ResourceId<T> where T : class
{
	public Guid Id;

	public this() { Id = default; }
	public this(Guid id) { Id = id; }

	/// A nil id is the unset reference, not a broken one.
	public bool IsNull => Id == default(Guid);
}
