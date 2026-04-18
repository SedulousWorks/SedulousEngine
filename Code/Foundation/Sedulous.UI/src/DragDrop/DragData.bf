namespace Sedulous.UI;

using System;

/// Base class for drag-and-drop payload data.
/// Subclass to carry typed data. The Format string enables type matching
/// between drag sources and drop targets.
public class DragData
{
	private String mFormat ~ delete _;

	/// Format string for type identification (e.g. "view/reorder", "text/plain").
	public StringView Format => mFormat;

	public this(StringView format)
	{
		mFormat = new String(format);
	}
}
