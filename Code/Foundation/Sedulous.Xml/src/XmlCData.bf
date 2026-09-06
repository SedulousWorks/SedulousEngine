using System;

namespace Sedulous.Xml;

/// A CDATA section: character data that is not scanned for markup.
///
/// It writes out verbatim rather than escaped, which is the entire point of the section.
class XmlCData : XmlNode
{
	private String mData = new .() ~ delete _;

	public this() : base(.CData)
	{
	}

	public this(StringView data) : base(.CData)
	{
		mData.Set(data);
	}

	public StringView Data => mData;

	public void SetData(StringView data) => mData.Set(data);
	public void Clear() => mData.Clear();

	public override void GetInnerText(String output) => output.Append(mData);

	public override void GetOuterXml(String output)
	{
		output.Append("<![CDATA[");
		output.Append(mData);
		output.Append("]]>");
	}
}
