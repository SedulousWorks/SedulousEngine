using System;

namespace Sedulous.Core.Serialization;

/// Keeps a field OUT of the body [Serializable] generates.
///
/// For state that is not part of what the object IS: a handle resolved after loading, a cache
/// rebuilt from the rest, or bulk that travels beside the envelope rather than inside it. A
/// baked navmesh is the second kind, and writing megabytes of it into a text envelope is what
/// this exists to prevent.
///
/// FIELD ORDER IS THE BINARY FORMAT, so adding or removing this on an existing type changes
/// what old data means exactly as inserting a field would.
[AttributeUsage(.Field, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct NotSerializedAttribute : Attribute
{
}
