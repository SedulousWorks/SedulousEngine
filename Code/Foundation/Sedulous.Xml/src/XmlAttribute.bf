using System;

namespace Sedulous.Xml;

/// A name and a value on an element.
///
/// It is a node, but not a child one: an element owns its attributes in a list of their
/// own, so an attribute never appears in the sibling chain.
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

	/// The name as written, prefix included.
	public StringView Name => mName;
	public StringView Prefix => mPrefix;
	public StringView LocalName => mLocalName;
	public StringView NamespaceUri => mNamespaceUri;
	public StringView Value => mValue;

	/// The element this belongs to. Not the parent: an attribute is not a child node.
	public XmlElement OwnerElement => mOwnerElement;

	public void SetName(StringView name)
	{
		mName.Set(name);
		XmlLexer.SplitQualifiedName(name, mPrefix, mLocalName);
	}

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

	public void SetValue(StringView value) => mValue.Set(value);
	public void SetOwnerElement(XmlElement element) => mOwnerElement = element;

	/// True for xmlns and for xmlns:something, which bind namespaces rather than carrying
	/// data, and which the parser consumes rather than treating as ordinary attributes.
	public bool IsNamespaceDeclaration => (mName == "xmlns") || (mPrefix == "xmlns");

	/// The prefix this declaration binds. Empty for the default declaration, which binds
	/// no prefix at all rather than one named "".
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

	public StringView DeclaredNamespaceUri => IsNamespaceDeclaration ? (StringView)mValue : "";

	public override void GetInnerText(String output) => output.Append(mValue);

	public override void GetOuterXml(String output)
	{
		output.Append(mName);
		output.Append("=\"");
		EscapeAttributeValue(mValue, output);
		output.Append('"');
	}
}
