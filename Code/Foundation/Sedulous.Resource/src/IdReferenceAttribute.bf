using System;

namespace Sedulous.Resource;

/// Marks a struct as a reference that is an identity alone: an asset named by its guid that
/// nothing binds or loads through a resource manager (a scene, which a level loads whole). Its
/// `Id` field is the guid; `target` is the asset type it names, what a picker offers.
///
/// Tooling reads and writes it through ReferenceShape as it does a Ref<T> (an inspector's picker,
/// an agent's component_set), and a pruned export follows it from a reflected component; a
/// binder that binds each Ref<T> passes it by, since it is no Ref<T>.
[AttributeUsage(.Struct, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct IdReferenceAttribute : Attribute
{
	public Type Target;

	public this(Type target)
	{
		Target = target;
	}
}
