using System;

namespace Sedulous.Net.Replication;

/// Marks a component field for replication.
///
/// A real attribute rather than a string keyed property mark looked up through reflection
/// tables, so a typo is a compile error rather than a field that silently never
/// replicates.
///
/// ReflectUser is what makes this work at all: marking one field turns on field reflection
/// for the containing type, so the codec that reads the mark can also read the layout. The
/// marker switches on the machinery that acts on it, and a component author states the
/// intent once.
[AttributeUsage(.Field, .ReflectAttribute, ReflectUser = .Type | .NonStaticFields)]
struct ReplicatedAttribute : Attribute
{
}
