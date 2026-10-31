using System;
using System.Collections;

namespace Sedulous.UI;

/// A parsed `transition:` list, shared by every StyleValue carrying it.
///
/// An EMPTY list is `transition: none`, which is not the same as having no list at all: none
/// still wins the cascade over an inherited `all`.
class TransitionList : RefCounted
{
	public List<TransitionSpec> Specs = new .() ~ delete _;

	public this() {}

	/// The entry governing a property: the LAST one naming it or naming `all`, since CSS lets
	/// later entries override earlier ones. Null when nothing covers it.
	public TransitionSpec? Find(StyleProperty property)
	{
		TransitionSpec? found = null;
		for (let spec in Specs)
		{
			if ((spec.Property == property) || (spec.Property == .COUNT))
				found = spec;
		}
		return found;
	}
}
