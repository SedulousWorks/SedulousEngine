using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A `var(--name, fallback)` reference.
///
/// Resolved against the view's custom properties at COMPUTE time, never at parse time: what a
/// variable means depends on where the view sits in the tree, so the same sheet gives
/// different answers to different views.
///
/// Shared by every copy of the StyleValue carrying it, and immutable once built.
class VariableReference : RefCounted
{
	/// Including the leading two dashes.
	public String Name = new .() ~ delete _;
	public uint64 NameHash = 0;
	/// Used when the variable is unset. May itself be a reference, giving nested fallbacks.
	///
	/// DIVERGES from Raptor, which boxes this in a StyleValueBox object purely so that C++
	/// can define StyleValue without the type referring to itself. Beef needs no such trick:
	/// StyleValue is a struct holding only a REFERENCE to this class, so the sizes resolve.
	/// A fallback of kind None means there is none.
	public StyleValue Fallback = .None;

	public this() {}

	public this(StringView name)
	{
		Name.Set(name);
		NameHash = HashText(name);
	}

	public bool HasFallback => !Fallback.IsNone;
}
