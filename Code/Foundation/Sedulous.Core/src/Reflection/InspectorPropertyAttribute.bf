using System;

namespace Sedulous.Core;

/// A COMPUTED value the inspector shows as a row: the marked getter's result under the
/// given name, written back through the named setter, or read-only without one.
///
/// For a value that is not a field: a flag inside a class the component only points at,
/// a count. A field is a row by being public; this is the same opt in for a method pair.
[AttributeUsage(.Method, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct InspectorPropertyAttribute : Attribute
{
	public String Name;
	/// The setter, a method taking the getter's type; empty for a read-only row.
	public String Setter;

	public this(String name, String setter = "")
	{
		Name = name;
		Setter = setter;
	}
}
