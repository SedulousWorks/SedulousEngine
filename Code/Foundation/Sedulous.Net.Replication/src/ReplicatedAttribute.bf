using System;

namespace Sedulous.Net.Replication;

/// Marks a component field for replication.
///
/// DIVERGES from Raptor, which carries the mark as a string keyed property attribute
/// (`net.replicated`) looked up through its own reflection tables. Beef has real attributes,
/// so the mark is a type and a typo is a compile error rather than a field that silently
/// never replicates.
///
/// ReflectUser is what makes this work at all: marking one field turns on field reflection
/// for the containing type, so the codec that reads the mark can also read the layout. The
/// marker switches on the machinery that acts on it, and a component author states the
/// intent once.
[AttributeUsage(.Field, .ReflectAttribute, ReflectUser = .Type | .NonStaticFields)]
struct ReplicatedAttribute : Attribute
{
}
