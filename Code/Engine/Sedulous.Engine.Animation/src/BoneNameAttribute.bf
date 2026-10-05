using System;

namespace Sedulous.Engine.Animation;

/// A text field that names a bone of its animator's skeleton (an IK chain's thigh, an aim's
/// head): the inspector offers that skeleton's bones for it rather than free text. The same
/// attribute in both engines (Raptor's `boneName`).
[AttributeUsage(.Field, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct BoneNameAttribute : Attribute
{
}
