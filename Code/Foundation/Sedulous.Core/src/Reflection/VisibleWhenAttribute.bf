using System;

namespace Sedulous.Core;

/// Show this member only while another member says so.
///
/// Two forms:
///
///   "loop"          visible while `loop` is truthy
///   "mode=1,2"      visible while `mode`'s raw integer value is 1 or 2
///
/// The name on the left is the DEPENDENCY's reflected name, not its display name, because
/// the condition is evaluated against data rather than against a label.
///
/// A STRING rather than a typed expression on purpose: the dependency is named at a point
/// where the compiler cannot check it anyway, and inventing a type for that would only
/// move the failure without removing it. A reader that cannot resolve the name should say
/// so rather than hide the member silently.
[AttributeUsage(.Field | .Property,
	.NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct VisibleWhenAttribute : Attribute
{
	public String Condition;

	public this(String condition)
	{
		Condition = condition;
	}
}
