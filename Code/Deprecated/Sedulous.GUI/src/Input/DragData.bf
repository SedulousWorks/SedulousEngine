using System;
using System.Collections;

namespace Sedulous.GUI;

/// Standard format identifiers for drag data.
public static class DragDataFormats
{
	/// Plain text format.
	public const String Text = "text/plain";
	/// File path format.
	public const String FilePath = "application/file-path";
	/// UI element reference format.
	public const String UIElement = "application/ui-element";
	/// Custom application-specific format.
	public const String Custom = "application/custom";
}

/// Base class for drag data.
/// Contains format-based data dictionary for flexible data transfer.
public class DragData
{
	private Dictionary<String, Object> mData = new .() ~ {
		for (let pair in _)
			delete pair.key;
		delete _;
	};
	private String mFormat ~ delete _;

	/// Creates drag data with a primary format identifier.
	public this(StringView format)
	{
		mFormat = new String(format);
	}

	/// The primary format identifier.
	public StringView Format => mFormat;

	/// Sets data for a format.
	public void SetData(StringView format, Object data)
	{
		let key = scope String(format);
		if (mData.TryGetValue(key, let existing))
		{
			mData[key] = data;
		}
		else
		{
			mData[new String(format)] = data;
		}
	}

	/// Gets data for a format.
	public Object GetData(StringView format)
	{
		let key = scope String(format);
		if (mData.TryGetValue(key, let value))
			return value;
		return null;
	}

	/// Gets typed data for a format.
	public T GetData<T>(StringView format) where T : class
	{
		return GetData(format) as T;
	}

	/// Checks if data is available for a format.
	public bool HasFormat(StringView format)
	{
		let key = scope String(format);
		return mData.ContainsKey(key);
	}

	/// Gets all available formats.
	public void GetFormats(List<StringView> formats)
	{
		for (let key in mData.Keys)
			formats.Add(key);
	}
}

/// Drag data containing text.
public class TextDragData : DragData
{
	private String mText ~ delete _;

	/// Creates text drag data.
	public this(StringView text) : base(DragDataFormats.Text)
	{
		mText = new String(text);
		SetData(DragDataFormats.Text, mText);
	}

	/// The text content.
	public StringView Text => mText;
}

/// Drag data containing a UI element reference.
public class ElementDragData : DragData
{
	private ElementHandle<UIElement> mElement;

	/// Creates element drag data.
	public this(UIElement element) : base(DragDataFormats.UIElement)
	{
		mElement = element;
		SetData(DragDataFormats.UIElement, this);
	}

	/// Gets the element (may return null if element was deleted).
	public UIElement GetElement() => mElement.TryResolve();

	/// The element handle.
	public ElementHandle<UIElement> ElementHandle => mElement;
}
