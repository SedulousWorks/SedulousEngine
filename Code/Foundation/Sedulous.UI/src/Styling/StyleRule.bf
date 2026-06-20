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
		// Drawable values held by the rule were AddRef'd on Set; string
		// values had a copy allocated on Set. Release / free here so
		// the rule's owned references don't outlive its declaration.
		for (let entry in mProperties)
		{
			if (entry.Value case .DrawableRef(let d))
				d?.ReleaseRef();
			else if (entry.Value case .StringRef(let s))
				delete s;
		}
	}

	/// Set a color property. If the property already has a value on
	/// this rule, the existing entry is overwritten.
	public StyleRule Set(StyleProperty prop, Color32 color)
	{
		SetValueOverwrite(prop, .ColorVal(color));
		return this;
	}

	/// Set a float property. Overwrites if `prop` already exists.
	public StyleRule Set(StyleProperty prop, float value)
	{
		SetValueOverwrite(prop, .FloatVal(value));
		return this;
	}

	/// Set a thickness property. Overwrites if `prop` already exists.
	public StyleRule Set(StyleProperty prop, Thickness value)
	{
		SetValueOverwrite(prop, .ThicknessVal(value));
		return this;
	}

	/// Set a drawable property. Overwrites if `prop` already exists;
	/// the previous drawable (if any) is released.
	///
	/// By default the rule AddRefs `drawable` on capture and Releases
	/// it when the rule is destroyed, so the caller keeps their own
	/// ref. This matches the typical `Set(prop, sheet.OwnColor(c))`
	/// pattern where the sheet independently owns the drawable.
	///
	/// Pass `consumeRef: true` to skip the AddRef - the caller hands
	/// their ref to the rule. Use this for one-liner
	/// `Set(prop, new XxxDrawable(...), consumeRef: true)` patterns
	/// where the drawable has no other home.
	public StyleRule Set(StyleProperty prop, Drawable drawable, bool consumeRef = false)
	{
		// Find existing entry to replace.
		for (int i = 0; i < mProperties.Count; i++)
		{
			if (mProperties[i].Prop != prop) continue;

			if (mProperties[i].Value case .DrawableRef(let prevD))
			{
				if (prevD === drawable)
				{
					// Same drawable - if the caller wanted to hand off
					// their ref (consume), we already have it through
					// the existing entry; release the caller's ref.
					if (consumeRef && drawable != null)
						drawable.ReleaseRef();
					return this;
				}
				prevD?.ReleaseRef();
			}
			if (!consumeRef && drawable != null)
				drawable.AddRef();
			mProperties[i] = (prop, .DrawableRef(drawable));
			return this;
		}

		if (!consumeRef && drawable != null)
			drawable.AddRef();
		mProperties.Add((prop, .DrawableRef(drawable)));
		return this;
	}

	/// Set a bool property. Overwrites if `prop` already exists.
	public StyleRule Set(StyleProperty prop, bool value)
	{
		SetValueOverwrite(prop, .BoolVal(value));
		return this;
	}

	/// Set a string property (e.g. `FontFamily`). The rule owns a copy
	/// of the string view's contents; overwriting frees the previous.
	public StyleRule Set(StyleProperty prop, StringView value)
	{
		let copy = new String(value);
		for (int i = 0; i < mProperties.Count; i++)
		{
			if (mProperties[i].Prop != prop) continue;
			let prev = mProperties[i].Value;
			if (prev case .StringRef(let oldS))
				delete oldS;
			else if (prev case .DrawableRef(let oldD))
				oldD?.ReleaseRef();
			mProperties[i] = (prop, .StringRef(copy));
			return this;
		}
		mProperties.Add((prop, .StringRef(copy)));
		return this;
	}

	/// Remove a property from this rule. Releases / frees any owned
	/// resources stored at the value. No-op if not set.
	public bool Remove(StyleProperty prop)
	{
		for (int i = 0; i < mProperties.Count; i++)
		{
			if (mProperties[i].Prop != prop) continue;
			let v = mProperties[i].Value;
			if (v case .DrawableRef(let d))
				d?.ReleaseRef();
			else if (v case .StringRef(let s))
				delete s;
			mProperties.RemoveAt(i);
			return true;
		}
		return false;
	}

	/// Internal overwrite helper for primitive values. Drawable and
	/// string values go through their own typed overloads so the
	/// AddRef/Release and copy lifecycle stays explicit. Cleans up the
	/// previous owned resource if overwriting a DrawableRef / StringRef.
	private void SetValueOverwrite(StyleProperty prop, StyleValue value)
	{
		for (int i = 0; i < mProperties.Count; i++)
		{
			if (mProperties[i].Prop != prop) continue;
			let prev = mProperties[i].Value;
			if (prev case .DrawableRef(let d))
				d?.ReleaseRef();
			else if (prev case .StringRef(let s))
				delete s;
			mProperties[i] = (prop, value);
			return;
		}
		mProperties.Add((prop, value));
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
