using System;

namespace Sedulous.Core;

/// What this IS, in a sentence, for a tooltip or a generated reference page.
///
/// Distinct from [[DisplayNameAttribute]], which is a label. A description explains; a
/// display name only names. On types and properties alike.
[AttributeUsage(.Types | .Field | .Property | .Method,
	.NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct DescriptionAttribute : Attribute
{
	public String Text;

	public this(String text)
	{
		Text = text;
	}
}
