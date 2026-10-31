using System;
using System.Collections;
using Sedulous.Image;

namespace Sedulous.UI;

/// Theme images, keyed by "styleClass:propertyName".
///
/// Hand one to a textured theme factory to build a fully image skinned sheet.
///
/// The images themselves are BORROWED; whoever loaded them owns them and must outlive this.
class ThemeImageSet
{
	private Dictionary<String, ThemeImageEntry> mImages = new .() ~ DeleteDictionaryAndKeys!(_);
	private Dictionary<String, List<ThemeStateEntry>> mStateGroups
		= new .() ~ DeleteStateGroups(_);

	public this() {}

	private static void DeleteStateGroups(Dictionary<String, List<ThemeStateEntry>> groups)
	{
		for (let pair in groups)
		{
			delete pair.key;
			DeleteContainerAndItems!(pair.value);
		}
		delete groups;
	}

	/// Adds one image for a drawable key, using nine slice when the slices say to. A null
	/// image is IGNORED rather than stored, so a theme can offer images it does not have.
	public void AddImage(StringView drawableKey, ImageData image, NineSlice slices = .())
	{
		if (image == null)
			return;

		ThemeImageEntry entry = .();
		entry.Image = image;
		entry.Slices = slices;
		entry.IsNineSlice = slices.IsValid;

		if (mImages.TryGetAlt(drawableKey, let existingKey, ?))
		{
			mImages[existingKey] = entry;
			return;
		}
		mImages[new String(drawableKey)] = entry;
	}

	/// Adds the state variants for a drawable key, which a theme turns into a state list.
	/// Each null variant is simply absent, so a theme can supply a hover image and no other.
	public void AddStateImages(StringView drawableKey, ImageData normal, ImageData hover = null,
		ImageData pressed = null, ImageData disabled = null, ImageData focused = null,
		NineSlice slices = .())
	{
		let group = new List<ThemeStateEntry>();

		AddStateImage(group, drawableKey, .Normal, normal, "Normal", slices);
		AddStateImage(group, drawableKey, .Hover, hover, "Hover", slices);
		AddStateImage(group, drawableKey, .Pressed, pressed, "Pressed", slices);
		AddStateImage(group, drawableKey, .Disabled, disabled, "Disabled", slices);
		AddStateImage(group, drawableKey, .Focused, focused, "Focused", slices);

		if (mStateGroups.TryGetAlt(drawableKey, let existingKey, let existingGroup))
		{
			DeleteContainerAndItems!(existingGroup);
			mStateGroups[existingKey] = group;
			return;
		}
		mStateGroups[new String(drawableKey)] = group;
	}

	private void AddStateImage(List<ThemeStateEntry> group, StringView drawableKey,
		ControlState state, ImageData image, StringView suffix, NineSlice slices)
	{
		if (image == null)
			return;

		let internalKey = scope $"{drawableKey}_{suffix}";
		AddImage(internalKey, image, slices);
		group.Add(new ThemeStateEntry(state, internalKey));
	}

	/// BORROWED.
	public Dictionary<String, ThemeImageEntry> Images => mImages;
	/// BORROWED.
	public Dictionary<String, List<ThemeStateEntry>> StateGroups => mStateGroups;

	public ThemeImageEntry? GetEntry(StringView key)
	{
		if (mImages.TryGetValueAlt(key, let entry))
			return entry;
		return null;
	}
}
