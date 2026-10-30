using System;

namespace Sedulous.Core;

/// A private field an inspector shows as a row, as it shows a public one: state code reaches
/// through methods (a particle system's module lists, its effect's sub-emitter links) that an
/// editor still edits in place.
///
/// For the inspector's rows ALONE: what serialises the type or describes it to an agent (the MCP
/// tools' field JSON) still sees only public fields, so marking a field changes no record and no
/// tool's answer. Its type must reflect its fields (a [Reflect] naming NonStaticFields).
[AttributeUsage(.Field,
	.NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct InspectorFieldAttribute : Attribute
{
}
