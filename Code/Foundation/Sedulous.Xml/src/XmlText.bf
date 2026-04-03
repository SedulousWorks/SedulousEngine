using System;

namespace Sedulous.Xml;

/// <summary>
/// Represents a text content node in an XML document.
/// </summary>
class XmlText : XmlNode
{
	private String mText = new .() ~ delete _;
	private bool mIsWhitespace;

	public this() : base(.Text)
	{
	}

	public this(StringView text) : base(.Text)
	{
		SetText(text);
	}

	/// <summary>
	/// Gets the text content.
	/// </summary>
	public StringView Text => mText;

	/// <summary>
	/// Returns true if this text node contains only whitespace.
	/// </summary>
	public bool IsWhitespace => mIsWhitespace;

	/// <summary>
	/// Sets the text content.
	/// </summary>
	public void SetText(StringView text)
	{
		mText.Set(text);
		UpdateWhitespaceFlag();
	}

	/// <summary>
	/// Appends text to this node.
	/// </summary>
	public void AppendText(StringView text)
	{
		mText.Append(text);
		UpdateWhitespaceFlag();
	}

	/// <summary>
	/// Clears the text content.
	/// </summary>
	public void Clear()
	{
		mText.Clear();
		mIsWhitespace = true;
	}

	private void UpdateWhitespaceFlag()
	{
		mIsWhitespace = true;
		for (let c in mText.RawChars)
		{
			if (!XmlLexer.IsWhitespace(c))
			{
				mIsWhitespace = false;
				break;
			}
		}
	}

	public override void GetInnerText(String output)
	{
		output.Append(mText);
	}

	public override void GetOuterXml(String output)
	{
		XmlWriter.EscapeText(mText, output);
	}
}
