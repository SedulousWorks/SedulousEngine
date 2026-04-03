using System;

namespace Sedulous.Xml;

/// <summary>
/// Represents a CDATA section node in an XML document.
/// CDATA sections contain text that should not be parsed for markup.
/// </summary>
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

	/// <summary>
	/// Gets the CDATA content.
	/// </summary>
	public StringView Data => mData;

	/// <summary>
	/// Sets the CDATA content.
	/// </summary>
	public void SetData(StringView data)
	{
		mData.Set(data);
	}

	/// <summary>
	/// Clears the CDATA content.
	/// </summary>
	public void Clear()
	{
		mData.Clear();
	}

	public override void GetInnerText(String output)
	{
		output.Append(mData);
	}

	public override void GetOuterXml(String output)
	{
		output.Append("<![CDATA[");
		output.Append(mData);
		output.Append("]]>");
	}
}
