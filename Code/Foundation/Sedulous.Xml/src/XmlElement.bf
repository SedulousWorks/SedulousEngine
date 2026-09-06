using System;
using System.Collections;

namespace Sedulous.Xml;

/// An element: a tag name, attributes, namespace declarations, and children.
///
/// Attributes are OWNED and deleted with the element. RemoveAttributeNode is the one way
/// to get one back out alive, which is why it alone does not delete.
class XmlElement : XmlNode
{
	private String mTagName = new .() ~ delete _;
	private String mPrefix = new .() ~ delete _;
	private String mLocalName = new .() ~ delete _;
	private String mNamespaceUri = new .() ~ delete _;
	private List<XmlAttribute> mAttributes = new .() ~ delete _;
	/// Prefix to URI, for the declarations made ON THIS element. A lookup walks up the
	/// tree, so an inner declaration shadows an outer one without either knowing.
	private Dictionary<String, String> mLocalNamespaces = new .() ~ delete _;

	public this() : base(.Element)
	{
	}

	public this(StringView tagName) : base(.Element)
	{
		SetTagName(tagName);
	}

	public this(StringView prefix, StringView localName, StringView namespaceUri) : base(.Element)
	{
		SetQualifiedName(prefix, localName, namespaceUri);
	}

	public ~this()
	{
		for (let attribute in mAttributes)
			delete attribute;
		ClearLocalNamespaces();
	}

	public StringView TagName => mTagName;
	public StringView Prefix => mPrefix;
	public StringView LocalName => mLocalName;
	public StringView NamespaceUri => mNamespaceUri;

	public void SetTagName(StringView name)
	{
		mTagName.Set(name);
		XmlLexer.SplitQualifiedName(name, mPrefix, mLocalName);
	}

	public void SetQualifiedName(StringView prefix, StringView localName, StringView namespaceUri)
	{
		mPrefix.Set(prefix);
		mLocalName.Set(localName);
		mNamespaceUri.Set(namespaceUri);

		mTagName.Clear();
		if (!prefix.IsEmpty)
		{
			mTagName.Append(prefix);
			mTagName.Append(':');
		}
		mTagName.Append(localName);
	}

	// ---- attributes ----

	public int AttributeCount => mAttributes.Count;
	public List<XmlAttribute> Attributes => mAttributes;

	public bool HasAttribute(StringView name) => GetAttributeNode(name) != null;
	public bool HasAttributeNS(StringView namespaceUri, StringView localName) => GetAttributeNodeNS(namespaceUri, localName) != null;

	/// An absent attribute reads as empty. A caller that has to tell an absent attribute
	/// from an empty one asks HasAttribute.
	public StringView GetAttribute(StringView name)
	{
		let attribute = GetAttributeNode(name);
		return (attribute != null) ? attribute.Value : "";
	}

	public StringView GetAttributeNS(StringView namespaceUri, StringView localName)
	{
		let attribute = GetAttributeNodeNS(namespaceUri, localName);
		return (attribute != null) ? attribute.Value : "";
	}

	public XmlAttribute GetAttributeNode(StringView name)
	{
		for (let attribute in mAttributes)
		{
			if (attribute.Name == name)
				return attribute;
		}
		return null;
	}

	public XmlAttribute GetAttributeNodeNS(StringView namespaceUri, StringView localName)
	{
		for (let attribute in mAttributes)
		{
			if ((attribute.NamespaceUri == namespaceUri) && (attribute.LocalName == localName))
				return attribute;
		}
		return null;
	}

	public void SetAttribute(StringView name, StringView value)
	{
		if (let existing = GetAttributeNode(name))
		{
			existing.SetValue(value);
			return;
		}

		let attribute = new XmlAttribute(name, value);
		attribute.SetOwnerElement(this);
		mAttributes.Add(attribute);

		// Setting xmlns or xmlns:x binds a namespace as well as storing an attribute.
		if (attribute.IsNamespaceDeclaration)
			DeclareNamespace(attribute.DeclaredPrefix, attribute.DeclaredNamespaceUri);
	}

	public void SetAttributeNS(StringView namespaceUri, StringView qualifiedName, StringView value)
	{
		let prefix = scope String();
		let localName = scope String();
		XmlLexer.SplitQualifiedName(qualifiedName, prefix, localName);

		if (let existing = GetAttributeNodeNS(namespaceUri, localName))
		{
			existing.SetValue(value);
			return;
		}

		let attribute = new XmlAttribute(prefix, localName, namespaceUri, value);
		attribute.SetOwnerElement(this);
		mAttributes.Add(attribute);
	}

	/// Takes ownership of the node, replacing and DELETING any attribute of the same name.
	public void SetAttributeNode(XmlAttribute attribute)
	{
		for (int i < mAttributes.Count)
		{
			if (mAttributes[i].Name == attribute.Name)
			{
				mAttributes[i].SetOwnerElement(null);
				delete mAttributes[i];
				mAttributes.RemoveAt(i);
				break;
			}
		}

		attribute.SetOwnerElement(this);
		mAttributes.Add(attribute);
		if (attribute.IsNamespaceDeclaration)
			DeclareNamespace(attribute.DeclaredPrefix, attribute.DeclaredNamespaceUri);
	}

	public void RemoveAttribute(StringView name)
	{
		for (int i < mAttributes.Count)
		{
			if (mAttributes[i].Name == name)
			{
				mAttributes[i].SetOwnerElement(null);
				delete mAttributes[i];
				mAttributes.RemoveAt(i);
				return;
			}
		}
	}

	public void RemoveAttributeNS(StringView namespaceUri, StringView localName)
	{
		for (int i < mAttributes.Count)
		{
			if ((mAttributes[i].NamespaceUri == namespaceUri) && (mAttributes[i].LocalName == localName))
			{
				mAttributes[i].SetOwnerElement(null);
				delete mAttributes[i];
				mAttributes.RemoveAt(i);
				return;
			}
		}
	}

	/// Detaches WITHOUT deleting: the caller takes the node.
	public void RemoveAttributeNode(XmlAttribute attribute)
	{
		for (int i < mAttributes.Count)
		{
			if (mAttributes[i] == attribute)
			{
				attribute.SetOwnerElement(null);
				mAttributes.RemoveAt(i);
				return;
			}
		}
	}

	public void ClearAttributes()
	{
		for (let attribute in mAttributes)
		{
			attribute.SetOwnerElement(null);
			delete attribute;
		}
		mAttributes.Clear();
		ClearLocalNamespaces();
	}

	// ---- namespaces ----

	public void DeclareNamespace(StringView prefix, StringView uri)
	{
		let key = scope String(prefix);
		if (mLocalNamespaces.TryGetAlt<StringView>(prefix, let existingKey, let existingValue))
		{
			delete existingValue;
			mLocalNamespaces[existingKey] = new String(uri);
			return;
		}
		mLocalNamespaces.Add(new String(key), new String(uri));
	}

	/// The URI a prefix is bound to, searching this element and then outwards. Empty when
	/// nothing binds it.
	public StringView ResolveNamespacePrefix(StringView prefix)
	{
		if (mLocalNamespaces.TryGetAlt<StringView>(prefix, ?, let uri))
			return uri;

		if (let parent = Parent as XmlElement)
			return parent.ResolveNamespacePrefix(prefix);

		// The two prefixes that are bound by the specification rather than declared.
		if (prefix == XmlNamespaces.XmlPrefix)
			return XmlNamespaces.Xml;
		if (prefix == XmlNamespaces.XmlnsPrefix)
			return XmlNamespaces.Xmlns;
		return "";
	}

	/// The prefix bound to a URI, searching this element and then outwards.
	public StringView ResolveNamespaceUri(StringView uri)
	{
		for (let entry in mLocalNamespaces)
		{
			if (entry.value == uri)
				return entry.key;
		}

		if (let parent = Parent as XmlElement)
			return parent.ResolveNamespaceUri(uri);

		if (uri == XmlNamespaces.Xml)
			return XmlNamespaces.XmlPrefix;
		if (uri == XmlNamespaces.Xmlns)
			return XmlNamespaces.XmlnsPrefix;
		return "";
	}

	// ---- child element navigation, skipping everything that is not an element ----

	public XmlElement FirstChildElement => NextElement(FirstChild, true);
	public XmlElement NextSiblingElement => NextElement(NextSibling, true);
	public XmlElement LastChildElement => NextElement(LastChild, false);
	public XmlElement PrevSiblingElement => NextElement(PrevSibling, false);

	public XmlElement GetFirstChildElement(StringView tagName)
	{
		for (var child = FirstChild; child != null; child = child.NextSibling)
		{
			if (let element = child as XmlElement)
			{
				if (element.TagName == tagName)
					return element;
			}
		}
		return null;
	}

	/// Direct children only. An empty tag name matches every element.
	public void GetChildElements(StringView tagName, List<XmlElement> results)
	{
		for (var child = FirstChild; child != null; child = child.NextSibling)
		{
			if (let element = child as XmlElement)
			{
				if (tagName.IsEmpty || (element.TagName == tagName))
					results.Add(element);
			}
		}
	}

	/// The whole subtree, in document order. An empty tag name matches every element.
	public void GetDescendantElements(StringView tagName, List<XmlElement> results)
	{
		for (var child = FirstChild; child != null; child = child.NextSibling)
		{
			if (let element = child as XmlElement)
			{
				if (tagName.IsEmpty || (element.TagName == tagName))
					results.Add(element);
				element.GetDescendantElements(tagName, results);
			}
		}
	}

	// ---- text content ----

	public void GetTextContent(String output) => GetInnerText(output);

	/// Replaces every child with a single text node, or with nothing when the text is
	/// empty: an element with no content should have no child, not an empty one.
	public void SetTextContent(StringView text)
	{
		ClearChildren();
		if (!text.IsEmpty)
			AppendChild(new XmlText(text));
	}

	public override void GetInnerText(String output)
	{
		for (var child = FirstChild; child != null; child = child.NextSibling)
			child.GetInnerText(output);
	}

	public override void GetOuterXml(String output)
	{
		output.Append('<');
		output.Append(mTagName);
		for (let attribute in mAttributes)
		{
			output.Append(' ');
			attribute.GetOuterXml(output);
		}

		// An element with no children writes as self closing.
		if (!HasChildren)
		{
			output.Append("/>");
			return;
		}

		output.Append('>');
		for (var child = FirstChild; child != null; child = child.NextSibling)
			child.GetOuterXml(output);
		output.Append("</");
		output.Append(mTagName);
		output.Append('>');
	}

	private void ClearLocalNamespaces()
	{
		for (let entry in mLocalNamespaces)
		{
			delete entry.key;
			delete entry.value;
		}
		mLocalNamespaces.Clear();
	}

	private static XmlElement NextElement(XmlNode start, bool forward)
	{
		for (var node = start; node != null; node = forward ? node.NextSibling : node.PrevSibling)
		{
			if (let element = node as XmlElement)
				return element;
		}
		return null;
	}
}
