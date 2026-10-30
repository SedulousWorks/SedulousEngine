using System;

namespace Sedulous.Core;

/// Four floats a runtime keeps as a colour (a particle's tint, a trail's colour): a reader shows a
/// Float4 marked with it as one colour, as it shows a Color, rather than as its x, y, z and w.
/// `showsAlpha` false keeps its alpha out of what is edited.
[AttributeUsage(.Field | .Property,
	.NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct AsColorAttribute : Attribute
{
	public bool ShowsAlpha;

	public this(bool showsAlpha = true)
	{
		ShowsAlpha = showsAlpha;
	}
}
