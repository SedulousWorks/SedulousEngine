using System;

namespace Sedulous.Core;

/// What a Guid member is the id of: the type a reference to it would point at (a collision
/// shape's source mesh names what a mesh cooks to), so an editor's slot offers what can fill it.
///
/// Only a plain Guid needs it: a Ref<T> says its T itself.
[AttributeUsage(.Field | .Property,
	.NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct ReferencesAttribute : Attribute
{
	public Type Target;

	public this(Type target)
	{
		Target = target;
	}
}
