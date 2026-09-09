using System;
using System.Collections;
using System.Reflection;

namespace Sedulous.PropertyAnimation;

/// A resolved property path: the chain of fields from the component's type down to the leaf.
///
/// The field descriptions are STATIC type metadata, so caching the chain is safe. The nested
/// sub object ADDRESSES are not cached and are re-derived from the live instance on every read
/// and write: a cached sub object pointer is a stale pointer the moment anything structural
/// changes underneath it.
class PropertyBinding
{
	private List<FieldInfo> mChain = new .() ~ delete _;

	/// The chain, outermost first. Empty means the path did not resolve.
	public Span<FieldInfo> Chain => mChain;
	public bool IsResolved => !mChain.IsEmpty;

	public void Add(FieldInfo field) => mChain.Add(field);
	public void Clear() => mChain.Clear();
}
