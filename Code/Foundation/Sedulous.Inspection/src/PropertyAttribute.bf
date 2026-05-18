namespace Sedulous.Inspection;

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

	/// Optional display name shown in the inspector (e.g., "Casts Shadows").
	/// When null, the codegen derives a name from the field.
	public String DisplayName;

	/// Optional serialized name matching the key used in Serialize()
	/// (e.g., "CastsShadows"). When null, the codegen derives from the field name.
	public String SerializedName;

	public this(PropertyEditorHint editor, String displayName, String serializedName)
	{
		Editor = editor;
		DisplayName = displayName;
		SerializedName = serializedName;
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

/// Specifies the expected file extension for a ResourceRef field.
/// Used by the asset picker to filter displayed resources.
/// Falls back to showing all resources if not specified.
[AttributeUsage(.Field, .ReflectAttribute)]
struct ResourceRefTypeAttribute : Attribute
{
	public StringView Extension;

	public this(StringView @extension)
	{
		Extension = @extension;
	}
}
