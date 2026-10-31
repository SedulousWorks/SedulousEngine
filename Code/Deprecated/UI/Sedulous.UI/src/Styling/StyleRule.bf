using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// One style rule: a selector, and the property assignments that go with it.
///
/// Ref counted, so a sheet can hold rules and hand back stable references from its builders.
///
/// Owns the STRING backing of its values, and borrows everything else.
///
/// A StyleValue borrows its payloads, so something must keep them alive. Strings live here
/// because they are copied out of the source text, which does not outlive the sheet. Drawables
/// and other resources belong to the SHEET: that is where the parser's factories put them, and
/// MergeFrom carries a sheet's owned resources across with its rules, so a rule shared into
/// another sheet keeps working after the original dies.
class StyleRule : RefCounted
{
	public struct Entry
	{
		public StyleProperty Prop;
		public StyleValue Value;
	}

	/// A custom property, `--name: value`. The cascade carries these like any other
	/// declaration; `var(--name)` and View.CustomProperty read them, which is the extension
	/// point for a custom layout's per child data.
	public class CustomEntry
	{
		public String Name = new .() ~ delete _;
		public uint64 NameHash = 0;
		public StyleValue Value = .();
	}

	/// OWNED.
	public StyleSelector Selector = new .() ~ delete _;

	private List<Entry> mProperties = new .() ~ delete _;
	private List<CustomEntry> mCustom = new .() ~ DeleteContainerAndItems!(_);

	/// The string backing for this rule's values, copied out of the source text.
	private List<String> mOwnedStrings = new .() ~ DeleteContainerAndItems!(_);

	/// The owning sheet's version counter.
	///
	/// A rule edit bumps it, so only the views whose sheet chain includes THAT sheet rebuild:
	/// a game context's edits never invalidate the editor's caches, and an inline edit on one
	/// view touches that view alone.
	private uint32* mOwnerVersion = null;

	public this() {}

	public void BindOwnerVersion(uint32* version) => mOwnerVersion = version;
	public uint32* OwnerVersion => mOwnerVersion;

	// ---- Setting properties --------------------------------------------------------------------

	public StyleRule Set(StyleProperty property, Color color)
	{
		SetOverwrite(property, StyleValue.Color(color));
		return this;
	}

	public StyleRule Set(StyleProperty property, float value)
	{
		SetOverwrite(property, StyleValue.Float(value));
		return this;
	}

	public StyleRule Set(StyleProperty property, Thickness value)
	{
		SetOverwrite(property, StyleValue.Thickness(value));
		return this;
	}

	public StyleRule Set(StyleProperty property, bool value)
	{
		SetOverwrite(property, StyleValue.Bool(value));
		return this;
	}

	/// BORROWS the drawable, which the SHEET owns. Hand it to StyleSheet.OwnDrawable first;
	/// the parser's factories already do.
	public StyleRule Set(StyleProperty property, Drawable drawable)
	{
		SetOverwrite(property, StyleValue.Drawable(drawable));
		return this;
	}

	/// COPIES the text; the rule keeps the copy alive.
	public StyleRule Set(StyleProperty property, StringView value)
	{
		SetOverwrite(property, StyleValue.String(OwnString(value)));
		return this;
	}

	/// Any value, a length, keyword or variable reference included. Whatever the value borrows
	/// must already be owned by the sheet, or by this rule through TakeOwnership.
	public StyleRule SetValue(StyleProperty property, StyleValue value)
	{
		SetOverwrite(property, value);
		return this;
	}

	/// Copies text into storage this rule owns, and answers a view of it.
	public StringView OwnString(StringView text)
	{
		let owned = new String(text);
		mOwnedStrings.Add(owned);
		return owned;
	}

	// ---- Custom properties ---------------------------------------------------------------------

	public StyleRule SetCustom(StringView name, StyleValue value)
	{
		let hash = HashText(name);
		for (let entry in mCustom)
		{
			if ((entry.NameHash == hash) && (entry.Name == name))
			{
				entry.Value = value;
				Changed();
				return this;
			}
		}

		let entry = new CustomEntry();
		entry.Name.Set(name);
		entry.NameHash = hash;
		entry.Value = value;
		mCustom.Add(entry);
		Changed();
		return this;
	}

	public int CustomCount => mCustom.Count;
	public CustomEntry GetCustom(int index) => mCustom[index];

	/// The custom property by hashed name, or null. The hash is compared first so a miss
	/// costs no string comparison.
	public StyleValue? FindCustom(uint64 nameHash, StringView name)
	{
		for (let entry in mCustom)
		{
			if ((entry.NameHash == nameHash) && (entry.Name == name))
				return entry.Value;
		}
		return null;
	}

	// ---- Reading -------------------------------------------------------------------------------

	/// Removes a property. False when it was not set.
	public bool Remove(StyleProperty property)
	{
		for (int i < mProperties.Count)
		{
			if (mProperties[i].Prop == property)
			{
				mProperties.RemoveAt(i);
				Changed();
				return true;
			}
		}
		return false;
	}

	public int PropertyCount => mProperties.Count;
	public Entry GetProperty(int index) => mProperties[index];

	public StyleValue? GetValue(StyleProperty property)
	{
		for (let entry in mProperties)
		{
			if (entry.Prop == property)
				return entry.Value;
		}
		return null;
	}

	// ---- Internals -----------------------------------------------------------------------------

	private void Changed()
	{
		if (mOwnerVersion != null)
			(*mOwnerVersion)++;
	}

	private void SetOverwrite(StyleProperty property, StyleValue value)
	{
		Changed();
		for (int i < mProperties.Count)
		{
			if (mProperties[i].Prop == property)
			{
				mProperties[i].Value = value;
				return;
			}
		}
		mProperties.Add(.() { Prop = property, Value = value });
	}
}
