using System;

namespace Sedulous.Core.Serialization;

/// A field APPENDED to a layout already in use, which a keyed (text) payload written before
/// it existed does not have: reading one, the field keeps its default rather than failing
/// the whole read, so the files a project has already saved still load.
///
/// TEXT ONLY. A positional (binary) payload cannot tell a missing field from the next one,
/// so there it is read like any other; binary data that predates a field still needs a
/// version bump. For a type stored as text, a manifest or a settings file, this is how its
/// shape grows without refusing every file saved under the old one.
[AttributeUsage(.Field, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct AppendedAttribute : Attribute
{
}
