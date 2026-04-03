using System;

namespace Sedulous.Xml;

/// <summary>
/// Represents a comment node in an XML document.
/// </summary>
class XmlComment : XmlNode
{
	private String mText = new .() ~ delete _;

	public this() : base(.Comment)
	{
	}

	public this(StringView text) : base(.Comment)
	{
		mText.Set(text);
	}

	/// <summary>
	/// Gets the comment text.
	/// </summary>
	public StringView Text => mText;

	/// <summary>
	/// Sets the comment text.
	/// Note: The text should not contain "--" as it's illegal in XML comments.
	/// </summary>
	public void SetText(StringView text)
	{
		mText.Set(text);
	}

	/// <summary>
	/// Clears the comment text.
	/// </summary>
	public void Clear()
	{
		mText.Clear();
	}

	public override void GetInnerText(String output)
	{
		// Comments do not contribute to inner text
	}

	public override void GetOuterXml(String output)
	{
		output.Append("<!--");
		output.Append(mText);
		output.Append("-->");
	}
}
