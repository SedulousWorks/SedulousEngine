namespace Sedulous.Editor.Core;

using System;

/// Hide this field from the reflection-based inspector.
[AttributeUsage(.Field)]
struct HideInInspectorAttribute : Attribute { }

/// Constrain a numeric field to a range. Inspector shows a slider.
[AttributeUsage(.Field)]
struct RangeAttribute : Attribute
{
	public float Min;
	public float Max;

	public this(float min, float max)
	{
		Min = min;
		Max = max;
	}
}

/// Group this field under a category in the inspector (Expander section).
[AttributeUsage(.Field)]
struct CategoryAttribute : Attribute
{
	public StringView Name;

	public this(StringView name)
	{
		Name = name;
	}
}

/// Show tooltip text when hovering the field label in the inspector.
[AttributeUsage(.Field)]
struct TooltipAttribute : Attribute
{
	public StringView Text;

	public this(StringView text)
	{
		Text = text;
	}
}
