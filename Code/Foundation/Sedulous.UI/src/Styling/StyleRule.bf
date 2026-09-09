using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// One style rule: a selector, and the property assignments that go with it.
///
/// Ref counted, so a sheet can hold rules and hand back stable references from its builders.
///
/// OWNS THE BACKING for every value it stores. A StyleValue borrows its drawable, string,
/// variable reference and transition list, so something has to keep them alive; the rule
/// holding a value is the natural owner, and it makes a rule self contained rather than
/// depending on the sheet having been told separately.
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

	// The backing this rule keeps alive for its borrowed StyleValue payloads.
	private List<String> mOwnedStrings = new .() ~ DeleteContainerAndItems!(_);
	private List<Drawable> mOwnedDrawables = new .() ~ ReleaseAll(_);
	private List<RefCounted> mOwnedResources = new .() ~ ReleaseAllResources(_);

	/// The owning sheet's version counter.
	///
	/// A rule edit bumps it, so only the views whose sheet chain includes THAT sheet rebuild:
	/// a game context's edits never invalidate the editor's caches, and an inline edit on one
	/// view touches that view alone.
	private uint32* mOwnerVersion = null;

	public this() {}

	private static void ReleaseAll(List<Drawable> drawables)
	{
		for (let drawable in drawables)
			drawable.ReleaseRef();
		delete drawables;
	}

	private static void ReleaseAllResources(List<RefCounted> resources)
	{
		for (let resource in resources)
			resource.ReleaseRef();
		delete resources;
	}

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

	/// CONSUMES the caller's reference on the drawable; the rule keeps it alive.
	public StyleRule Set(StyleProperty property, Drawable drawable)
	{
		mOwnedDrawables.Add(drawable);
		SetOverwrite(property, StyleValue.Drawable(drawable));
		return this;
	}

	/// COPIES the text; the rule keeps the copy alive.
	public StyleRule Set(StyleProperty property, StringView value)
	{
		SetOverwrite(property, StyleValue.String(OwnString(value)));
		return this;
	}

	/// Any value, a length, keyword or variable reference included. The caller is responsible
	/// for having handed this rule anything the value borrows, through TakeOwnership.
	public StyleRule SetValue(StyleProperty property, StyleValue value)
	{
		SetOverwrite(property, value);
		return this;
	}

	/// Keeps a ref counted payload alive for as long as this rule, for a value built
	/// elsewhere. CONSUMES the caller's reference.
	public void TakeOwnership(RefCounted resource)
	{
		mOwnedResources.Add(resource);
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
