using System;

namespace Sedulous.Pipeline.Importer;

/// One checkbox the import dialog renders, pointing straight at the field it controls.
///
/// A DECLARATIVE description rather than a reflected one: an importer returns its list, and
/// the dialog needs to know nothing about the options type.
struct ImportToggle
{
	/// The checkbox's text.
	public StringView Label;
	/// Its tooltip, or empty for none.
	public StringView Description;
	/// BORROWED, and pointing into the options object that outlives the dialog.
	public bool* Value;

	public this(StringView label, StringView description, bool* value)
	{
		Label = label;
		Description = description;
		Value = value;
	}
}
