namespace Sedulous.Engine.Core;

using System;

/// Hints for the editor on which property editor to use.
enum PropertyEditorHint
{
	/// Use the default editor for the field type.
	Default,
	/// Use a color picker (for Vector3/Color fields representing colors).
	Color,
	/// Use a file/resource browser (for ResourceRef fields).
	Resource,
	/// Use a slider (for float/int fields with a range).
	Slider
}

/// Marks a component field as editor-visible.
/// Only fields with this attribute appear in the inspector.
/// Runtime-only fields (GPU handles, material instances, etc.) should not have this.
[AttributeUsage(.Field, .ReflectAttribute)]
struct PropertyAttribute : Attribute
{
	/// Editor hint for choosing the appropriate property editor.
	public PropertyEditorHint Editor;

	/// Optional display name override. Empty = use field name.
	public StringView DisplayName;

	public this()
	{
		Editor = .Default;
		DisplayName = default;
	}

	public this(PropertyEditorHint editor)
	{
		Editor = editor;
		DisplayName = default;
	}
}

/// Hide this field from the reflection-based inspector.
[AttributeUsage(.Field)]
struct HideInInspectorAttribute : Attribute { }

/// Constrain a numeric field to a range. Sets min/max on the editor.
/// Use with PropertyEditorHint.Slider for a slider control.
[AttributeUsage(.Field, .ReflectAttribute)]
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
[AttributeUsage(.Field, .ReflectAttribute)]
struct CategoryAttribute : Attribute
{
	public StringView Name;

	public this(StringView name)
	{
		Name = name;
	}
}

/// Show tooltip text when hovering the field label in the inspector.
[AttributeUsage(.Field, .ReflectAttribute)]
struct TooltipAttribute : Attribute
{
	public StringView Text;

	public this(StringView text)
	{
		Text = text;
	}
}
