namespace Sedulous.UI;

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

	public ~this()
	{
		// Drawable values held by the rule were AddRef'd on Set. Release
		// them here so the rule's ref doesn't outlive its declaration.
		for (let entry in mProperties)
		{
			if (entry.Value case .DrawableRef(let d))
				d?.ReleaseRef();
		}
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

	/// Set a drawable property. By default the rule AddRefs `drawable`
	/// on capture and Releases it when the rule is destroyed, so the
	/// caller keeps their own ref. This matches the typical
	/// `Set(prop, sheet.OwnColor(c))` pattern where the sheet
	/// independently owns the drawable.
	///
	/// Pass `consumeRef: true` to skip the AddRef - the caller hands
	/// their ref to the rule. Use this for one-liner
	/// `Set(prop, new XxxDrawable(...), consumeRef: true)` patterns
	/// where the drawable has no other home.
	public StyleRule Set(StyleProperty prop, Drawable drawable, bool consumeRef = false)
	{
		if (!consumeRef && drawable != null)
			drawable.AddRef();
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
