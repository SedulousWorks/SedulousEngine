using System;

namespace Sedulous.Core;

/// The counted result of this method carries a reference the caller takes: a factory's new
/// object, its one reference handed over.
[AttributeUsage(.Method, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct ScriptReturnsReferenceAttribute : Attribute
{
}
