using System;

namespace Sedulous.Xml;

/// The XML declaration.
class XmlDeclaration : XmlNode
{
	private String mVersion = new .("1.0") ~ delete _;
	private String mEncoding = new .("utf-8") ~ delete _;
	private String mStandalone = new .() ~ delete _;

	public this() : base(.Declaration)
	{
	}

	public this(StringView version, StringView encoding, StringView standalone) : base(.Declaration)
	{
		mVersion.Set(version);
		mEncoding.Set(encoding);
		mStandalone.Set(standalone);
	}

	public StringView Version => mVersion;
	public StringView Encoding => mEncoding;
	public StringView Standalone => mStandalone;

	public void SetVersion(StringView version) => mVersion.Set(version);
	public void SetEncoding(StringView encoding) => mEncoding.Set(encoding);
	public void SetStandalone(StringView standalone) => mStandalone.Set(standalone);

	public override void GetInnerText(String output)
	{
	}

	/// Encoding and standalone are written only when set, since an empty attribute is not
	/// the same as an absent one and a declaration with encoding="" is invalid.
	public override void GetOuterXml(String output)
	{
		output.Append("<?xml version=\"");
		output.Append(mVersion);
		output.Append("\"");

		if (!mEncoding.IsEmpty)
		{
			output.Append(" encoding=\"");
			output.Append(mEncoding);
			output.Append("\"");
		}
		if (!mStandalone.IsEmpty)
		{
			output.Append(" standalone=\"");
			output.Append(mStandalone);
			output.Append("\"");
		}
		output.Append("?>");
	}
}
