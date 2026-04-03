using System;

namespace Sedulous.Xml;

/// <summary>
/// Represents an attribute of an XML element.
/// </summary>
class XmlAttribute : XmlNode
{
	private String mName = new .() ~ delete _;
	private String mPrefix = new .() ~ delete _;
	private String mLocalName = new .() ~ delete _;
	private String mNamespaceUri = new .() ~ delete _;
	private String mValue = new .() ~ delete _;
	private XmlElement mOwnerElement;

	public this() : base(.Attribute)
	{
	}

	public this(StringView name, StringView value) : base(.Attribute)
	{
		SetName(name);
		mValue.Set(value);
	}

	public this(StringView prefix, StringView localName, StringView namespaceUri, StringView value) : base(.Attribute)
	{
		SetQualifiedName(prefix, localName, namespaceUri);
		mValue.Set(value);
	}

	/// <summary>
	/// Gets the full attribute name (including prefix if present).
	/// </summary>
	public StringView Name => mName;

	/// <summary>
	/// Gets the namespace prefix.
	/// </summary>
	public StringView Prefix => mPrefix;

	/// <summary>
	/// Gets the local name (without prefix).
	/// </summary>
	public StringView LocalName => mLocalName;

	/// <summary>
	/// Gets the namespace URI.
	/// </summary>
	public StringView NamespaceUri => mNamespaceUri;

	/// <summary>
	/// Gets the attribute value.
	/// </summary>
	public StringView Value => mValue;

	/// <summary>
	/// Gets the element that owns this attribute.
	/// </summary>
	public XmlElement OwnerElement => mOwnerElement;

	/// <summary>
	/// Sets the attribute name.
	/// </summary>
	public void SetName(StringView name)
	{
		mName.Set(name);
		XmlLexer.SplitQualifiedName(name, mPrefix, mLocalName);
	}

	/// <summary>
	/// Sets the qualified name with explicit namespace.
	/// </summary>
	public void SetQualifiedName(StringView prefix, StringView localName, StringView namespaceUri)
	{
		mPrefix.Set(prefix);
		mLocalName.Set(localName);
		mNamespaceUri.Set(namespaceUri);

		mName.Clear();
		if (!prefix.IsEmpty)
		{
			mName.Append(prefix);
			mName.Append(':');
		}
		mName.Append(localName);
	}

	/// <summary>
	/// Sets the attribute value.
	/// </summary>
	public void SetValue(StringView value)
	{
		mValue.Set(value);
	}

	/// <summary>
	/// Sets the owner element.
	/// </summary>
	internal void SetOwnerElement(XmlElement element)
	{
		mOwnerElement = element;
	}

	/// <summary>
	/// Returns true if this attribute is a namespace declaration (xmlns or xmlns:prefix).
	/// </summary>
	public bool IsNamespaceDeclaration
	{
		get
		{
			return mName == "xmlns" || mPrefix == "xmlns";
		}
	}

	/// <summary>
	/// For namespace declarations, gets the declared prefix.
	/// Returns empty string for default namespace (xmlns="...").
	/// </summary>
	public StringView DeclaredPrefix
	{
		get
		{
			if (mName == "xmlns")
				return "";
			if (mPrefix == "xmlns")
				return mLocalName;
			return "";
		}
	}

	/// <summary>
	/// For namespace declarations, gets the declared namespace URI.
	/// </summary>
	public StringView DeclaredNamespaceUri
	{
		get
		{
			if (IsNamespaceDeclaration)
				return mValue;
			return "";
		}
	}

	public override void GetInnerText(String output)
	{
		output.Append(mValue);
	}

	public override void GetOuterXml(String output)
	{
		output.Append(mName);
		output.Append("=\"");
		XmlWriter.EscapeAttributeValue(mValue, output);
		output.Append('"');
	}
}
