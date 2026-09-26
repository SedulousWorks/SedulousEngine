using System;

namespace Sedulous.Core;

/// Read by everyone, written by no generic writer: a script gets a getter and no setter, so
/// an assignment fails to compile, and a tool that writes reflected fields for someone else
/// (an agent's component_set) refuses it.
///
/// For a public field its owner writes itself (a Serialize, a system) that nobody else may,
/// where Beef's `readonly` would lock the owner out too: a network identity's authority is
/// replication's to set and a behaviour's to read. A CONTRACT, not a hint each consumer
/// re-checks; the raw address stays the deliberate way around it (the inspector's own tools).
[AttributeUsage(.Field | .Property,
	.NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct ReadOnlyAttribute : Attribute
{
}
