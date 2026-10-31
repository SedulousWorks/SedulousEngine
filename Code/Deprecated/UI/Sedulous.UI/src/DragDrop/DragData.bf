using System;

namespace Sedulous.UI;

/// The payload of a drag. Subclass it to carry typed data.
///
/// The format string is what lets a source and a target agree on what is being dragged
/// without either knowing the other's type.
///
/// Ref counted, because the manager holds it for the length of the drag while the source
/// that made it may go away.
class DragData : RefCounted
{
	private String mFormat = new .() ~ delete _;

	public this(StringView format)
	{
		mFormat.Set(format);
	}

	/// Identifies the payload type, such as "view/reorder" or "text/plain".
	public StringView Format => mFormat;
}
