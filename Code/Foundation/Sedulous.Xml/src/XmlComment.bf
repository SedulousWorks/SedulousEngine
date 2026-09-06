using System;

namespace Sedulous.Xml;

/// A comment.
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

	public StringView Text => mText;

	public void SetText(StringView text) => mText.Set(text);
	public void Clear() => mText.Clear();

	/// A comment contributes no text: it is not content, and a caller reading the text of
	/// a document should not see it.
	public override void GetInnerText(String output)
	{
	}

	public override void GetOuterXml(String output)
	{
		output.Append("<!--");
		output.Append(mText);
		output.Append("-->");
	}
}
