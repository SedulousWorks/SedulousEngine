using System;

namespace Sedulous.Xml;

/// <summary>
/// Represents an XML declaration node (<?xml version="1.0" encoding="utf-8"?>).
/// </summary>
class XmlDeclaration : XmlNode
{
	private String mVersion = new .("1.0") ~ delete _;
	private String mEncoding = new .("utf-8") ~ delete _;
	private String mStandalone = new .() ~ delete _; // "yes", "no", or empty

	public this() : base(.Declaration)
	{
	}

	public this(StringView version, StringView encoding, StringView standalone) : base(.Declaration)
	{
		mVersion.Set(version);
		mEncoding.Set(encoding);
		mStandalone.Set(standalone);
	}

	/// <summary>
	/// Gets the XML version (usually "1.0" or "1.1").
	/// </summary>
	public StringView Version => mVersion;

	/// <summary>
	/// Gets the character encoding.
	/// </summary>
	public StringView Encoding => mEncoding;

	/// <summary>
	/// Gets the standalone declaration ("yes", "no", or empty).
	/// </summary>
	public StringView Standalone => mStandalone;

	/// <summary>
	/// Sets the XML version.
	/// </summary>
	public void SetVersion(StringView version)
	{
		mVersion.Set(version);
	}

	/// <summary>
	/// Sets the character encoding.
	/// </summary>
	public void SetEncoding(StringView encoding)
	{
		mEncoding.Set(encoding);
	}

	/// <summary>
	/// Sets the standalone declaration.
	/// </summary>
	public void SetStandalone(StringView standalone)
	{
		mStandalone.Set(standalone);
	}

	public override void GetInnerText(String output)
	{
		// Declarations do not contribute to inner text
	}

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
