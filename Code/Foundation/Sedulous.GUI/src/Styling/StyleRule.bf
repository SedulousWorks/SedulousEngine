namespace Sedulous.GUI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// A single style rule: a selector plus a set of property assignments.
/// When the selector matches a view, the properties are applied.
public class StyleRule
{
	public StyleSelector Selector ~ delete _;
	private List<(StyleProperty Prop, StyleValue Value)> mProperties = new .() ~ delete _;

	public this()
	{
		Selector = new StyleSelector();
	}

	/// Set a color property.
	public StyleRule Set(StyleProperty prop, Color color)
	{
		mProperties.Add((prop, .ColorVal(color)));
		return this;
	}

	/// Set a float property.
	public StyleRule Set(StyleProperty prop, float value)
	{
		mProperties.Add((prop, .FloatVal(value)));
		return this;
	}

	/// Set a thickness property.
	public StyleRule Set(StyleProperty prop, Thickness value)
	{
		mProperties.Add((prop, .ThicknessVal(value)));
		return this;
	}

	/// Set a drawable property. The StyleSheet owns the drawable.
	public StyleRule Set(StyleProperty prop, Drawable drawable)
	{
		mProperties.Add((prop, .DrawableRef(drawable)));
		return this;
	}

	/// Set a bool property.
	public StyleRule Set(StyleProperty prop, bool value)
	{
		mProperties.Add((prop, .BoolVal(value)));
		return this;
	}

	/// Number of properties in this rule.
	public int PropertyCount => mProperties.Count;

	/// Get property assignment at index.
	public (StyleProperty Prop, StyleValue Value) GetProperty(int index) => mProperties[index];

	/// Try to find a specific property in this rule.
	public StyleValue? GetValue(StyleProperty prop)
	{
		for (let entry in mProperties)
		{
			if (entry.Prop == prop)
				return entry.Value;
		}
		return null;
	}
}
