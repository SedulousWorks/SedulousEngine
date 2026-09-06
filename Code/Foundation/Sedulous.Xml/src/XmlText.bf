using System;

namespace Sedulous.Xml;

/// Character data.
class XmlText : XmlNode
{
	private String mText = new .() ~ delete _;
	/// Cached, because the parser asks it of every text node to decide whether the node is
	/// worth keeping, and the answer only changes when the text does.
	private bool mIsWhitespace = true;

	public this() : base(.Text)
	{
	}

	public this(StringView text) : base(.Text)
	{
		SetText(text);
	}

	public StringView Text => mText;

	/// True when the text is nothing but whitespace, which is what a caller ignoring
	/// formatting between elements tests.
	public bool IsWhitespace => mIsWhitespace;

	public void SetText(StringView text)
	{
		mText.Set(text);
		UpdateWhitespaceFlag();
	}

	public void AppendText(StringView text)
	{
		mText.Append(text);
		UpdateWhitespaceFlag();
	}

	public void Clear()
	{
		mText.Clear();
		mIsWhitespace = true;
	}

	public override void GetInnerText(String output) => output.Append(mText);

	public override void GetOuterXml(String output) => EscapeText(mText, output);

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
}
