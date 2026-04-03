using System;
using System.Collections;

namespace Sedulous.Xml;

using internal Sedulous.Xml;

/// <summary>
/// Represents an element node in an XML document.
/// </summary>
class XmlElement : XmlNode
{
	private String mTagName = new .() ~ delete _;
	private String mPrefix = new .() ~ delete _;
	private String mLocalName = new .() ~ delete _;
	private String mNamespaceUri = new .() ~ delete _;
	private List<XmlAttribute> mAttributes = new .() ~ DeleteContainerAndItems!(_);

	// Local namespace declarations on this element
	private Dictionary<String, String> mLocalNamespaces ~ DeleteDictionaryAndKeysAndValues!(_);

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

	// ---- Name Properties ----

	/// <summary>
	/// Gets the full tag name (including prefix if present).
	/// </summary>
	public StringView TagName => mTagName;

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
	/// Sets the tag name.
	/// </summary>
	public void SetTagName(StringView name)
	{
		mTagName.Set(name);
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

		mTagName.Clear();
		if (!prefix.IsEmpty)
		{
			mTagName.Append(prefix);
			mTagName.Append(':');
		}
		mTagName.Append(localName);
	}

	// ---- Attribute Access ----

	/// <summary>
	/// Gets the number of attributes.
	/// </summary>
	public int AttributeCount => mAttributes.Count;

	/// <summary>
	/// Enumerates all attributes.
	/// </summary>
	public List<XmlAttribute>.Enumerator Attributes => mAttributes.GetEnumerator();

	/// <summary>
	/// Returns true if the element has an attribute with the given name.
	/// </summary>
	public bool HasAttribute(StringView name)
	{
		for (let attr in mAttributes)
		{
			if (attr.Name == name)
				return true;
		}
		return false;
	}

	/// <summary>
	/// Returns true if the element has an attribute with the given namespace and local name.
	/// </summary>
	public bool HasAttributeNS(StringView namespaceUri, StringView localName)
	{
		for (let attr in mAttributes)
		{
			if (attr.NamespaceUri == namespaceUri && attr.LocalName == localName)
				return true;
		}
		return false;
	}

	/// <summary>
	/// Gets the value of an attribute by name.
	/// Returns empty string if the attribute doesn't exist.
	/// </summary>
	public StringView GetAttribute(StringView name)
	{
		for (let attr in mAttributes)
		{
			if (attr.Name == name)
				return attr.Value;
		}
		return "";
	}

	/// <summary>
	/// Gets the value of an attribute by namespace and local name.
	/// Returns empty string if the attribute doesn't exist.
	/// </summary>
	public StringView GetAttributeNS(StringView namespaceUri, StringView localName)
	{
		for (let attr in mAttributes)
		{
			if (attr.NamespaceUri == namespaceUri && attr.LocalName == localName)
				return attr.Value;
		}
		return "";
	}

	/// <summary>
	/// Gets an attribute node by name.
	/// Returns null if the attribute doesn't exist.
	/// </summary>
	public XmlAttribute GetAttributeNode(StringView name)
	{
		for (let attr in mAttributes)
		{
			if (attr.Name == name)
				return attr;
		}
		return null;
	}

	/// <summary>
	/// Gets an attribute node by namespace and local name.
	/// Returns null if the attribute doesn't exist.
	/// </summary>
	public XmlAttribute GetAttributeNodeNS(StringView namespaceUri, StringView localName)
	{
		for (let attr in mAttributes)
		{
			if (attr.NamespaceUri == namespaceUri && attr.LocalName == localName)
				return attr;
		}
		return null;
	}

	/// <summary>
	/// Sets an attribute value. Creates the attribute if it doesn't exist.
	/// </summary>
	public void SetAttribute(StringView name, StringView value)
	{
		for (let attr in mAttributes)
		{
			if (attr.Name == name)
			{
				attr.SetValue(value);
				return;
			}
		}

		// Create new attribute
		let attr = new XmlAttribute(name, value);
		attr.SetOwnerElement(this);
		mAttributes.Add(attr);

		// Check if this is a namespace declaration
		if (attr.IsNamespaceDeclaration)
		{
			DeclareNamespace(attr.DeclaredPrefix, attr.DeclaredNamespaceUri);
		}
	}

	/// <summary>
	/// Sets an attribute value with namespace. Creates the attribute if it doesn't exist.
	/// </summary>
	public void SetAttributeNS(StringView namespaceUri, StringView qualifiedName, StringView value)
	{
		let prefix = scope String();
		let localName = scope String();
		XmlLexer.SplitQualifiedName(qualifiedName, prefix, localName);

		for (let attr in mAttributes)
		{
			if (attr.NamespaceUri == namespaceUri && attr.LocalName == localName)
			{
				attr.SetValue(value);
				return;
			}
		}

		// Create new attribute
		let attr = new XmlAttribute(prefix, localName, namespaceUri, value);
		attr.SetOwnerElement(this);
		mAttributes.Add(attr);
	}

	/// <summary>
	/// Adds an attribute node to this element.
	/// </summary>
	public void SetAttributeNode(XmlAttribute attr)
	{
		// Remove existing attribute with same name
		for (var i = 0; i < mAttributes.Count; i++)
		{
			if (mAttributes[i].Name == attr.Name)
			{
				let old = mAttributes[i];
				old.SetOwnerElement(null);
				delete old;
				mAttributes.RemoveAt(i);
				break;
			}
		}

		attr.SetOwnerElement(this);
		mAttributes.Add(attr);

		// Check if this is a namespace declaration
		if (attr.IsNamespaceDeclaration)
		{
			DeclareNamespace(attr.DeclaredPrefix, attr.DeclaredNamespaceUri);
		}
	}

	/// <summary>
	/// Removes an attribute by name.
	/// </summary>
	public void RemoveAttribute(StringView name)
	{
		for (var i = 0; i < mAttributes.Count; i++)
		{
			if (mAttributes[i].Name == name)
			{
				let attr = mAttributes[i];
				attr.SetOwnerElement(null);
				delete attr;
				mAttributes.RemoveAt(i);
				return;
			}
		}
	}

	/// <summary>
	/// Removes an attribute by namespace and local name.
	/// </summary>
	public void RemoveAttributeNS(StringView namespaceUri, StringView localName)
	{
		for (var i = 0; i < mAttributes.Count; i++)
		{
			if (mAttributes[i].NamespaceUri == namespaceUri && mAttributes[i].LocalName == localName)
			{
				let attr = mAttributes[i];
				attr.SetOwnerElement(null);
				delete attr;
				mAttributes.RemoveAt(i);
				return;
			}
		}
	}

	/// <summary>
	/// Removes an attribute node.
	/// </summary>
	public void RemoveAttributeNode(XmlAttribute attr)
	{
		for (var i = 0; i < mAttributes.Count; i++)
		{
			if (mAttributes[i] == attr)
			{
				attr.SetOwnerElement(null);
				mAttributes.RemoveAt(i);
				return;
			}
		}
	}

	/// <summary>
	/// Removes all attributes.
	/// </summary>
	public void ClearAttributes()
	{
		for (let attr in mAttributes)
		{
			attr.SetOwnerElement(null);
			delete attr;
		}
		mAttributes.Clear();

		if (mLocalNamespaces != null)
			mLocalNamespaces.Clear();
	}

	// ---- Namespace Handling ----

	/// <summary>
	/// Declares a namespace on this element.
	/// </summary>
	public void DeclareNamespace(StringView prefix, StringView uri)
	{
		if (mLocalNamespaces == null)
			mLocalNamespaces = new .();

		let uriValue = new String(uri);

		// Check if prefix already exists
		String existingKey = null;
		for (let (key, value) in mLocalNamespaces)
		{
			if (key == prefix)
			{
				existingKey = key;
				delete value;
				break;
			}
		}

		if (existingKey != null)
		{
			mLocalNamespaces[existingKey] = uriValue;
		}
		else
		{
			let prefixKey = new String(prefix);
			mLocalNamespaces[prefixKey] = uriValue;
		}
	}

	/// <summary>
	/// Resolves a namespace prefix to its URI.
	/// Searches this element and its ancestors.
	/// </summary>
	public StringView ResolveNamespacePrefix(StringView prefix)
	{
		// Check local declarations
		if (mLocalNamespaces != null)
		{
			if (mLocalNamespaces.TryGetValue(scope String(prefix), let uri))
				return uri;
		}

		// Check parent
		if (let parentElem = Parent as XmlElement)
			return parentElem.ResolveNamespacePrefix(prefix);

		// Built-in prefixes
		if (prefix == "xml")
			return XmlNamespaces.Xml;
		if (prefix == "xmlns")
			return XmlNamespaces.Xmlns;

		return "";
	}

	/// <summary>
	/// Resolves a namespace URI to its prefix.
	/// Searches this element and its ancestors.
	/// </summary>
	public StringView ResolveNamespaceUri(StringView uri)
	{
		// Check local declarations
		if (mLocalNamespaces != null)
		{
			for (let (prefix, nsUri) in mLocalNamespaces)
			{
				if (nsUri == uri)
					return prefix;
			}
		}

		// Check parent
		if (let parentElem = Parent as XmlElement)
			return parentElem.ResolveNamespaceUri(uri);

		// Built-in namespaces
		if (uri == XmlNamespaces.Xml)
			return "xml";
		if (uri == XmlNamespaces.Xmlns)
			return "xmlns";

		return "";
	}

	// ---- Child Element Access ----

	/// <summary>
	/// Gets the first child element.
	/// </summary>
	public XmlElement FirstChildElement
	{
		get
		{
			var child = FirstChild;
			while (child != null)
			{
				if (let elem = child as XmlElement)
					return elem;
				child = child.NextSibling;
			}
			return null;
		}
	}

	/// <summary>
	/// Gets the last child element.
	/// </summary>
	public XmlElement LastChildElement
	{
		get
		{
			var child = LastChild;
			while (child != null)
			{
				if (let elem = child as XmlElement)
					return elem;
				child = child.PrevSibling;
			}
			return null;
		}
	}

	/// <summary>
	/// Gets the next sibling element.
	/// </summary>
	public XmlElement NextSiblingElement
	{
		get
		{
			var sibling = NextSibling;
			while (sibling != null)
			{
				if (let elem = sibling as XmlElement)
					return elem;
				sibling = sibling.NextSibling;
			}
			return null;
		}
	}

	/// <summary>
	/// Gets the previous sibling element.
	/// </summary>
	public XmlElement PrevSiblingElement
	{
		get
		{
			var sibling = PrevSibling;
			while (sibling != null)
			{
				if (let elem = sibling as XmlElement)
					return elem;
				sibling = sibling.PrevSibling;
			}
			return null;
		}
	}

	/// <summary>
	/// Gets the first child element with the given tag name.
	/// </summary>
	public XmlElement GetFirstChildElement(StringView tagName)
	{
		var child = FirstChild;
		while (child != null)
		{
			if (let elem = child as XmlElement)
			{
				if (elem.TagName == tagName)
					return elem;
			}
			child = child.NextSibling;
		}
		return null;
	}

	/// <summary>
	/// Gets all direct child elements with the given tag name.
	/// </summary>
	public void GetChildElements(StringView tagName, List<XmlElement> results)
	{
		var child = FirstChild;
		while (child != null)
		{
			if (let elem = child as XmlElement)
			{
				if (tagName.IsEmpty || elem.TagName == tagName)
					results.Add(elem);
			}
			child = child.NextSibling;
		}
	}

	/// <summary>
	/// Gets all descendant elements with the given tag name (recursive).
	/// </summary>
	public void GetDescendantElements(StringView tagName, List<XmlElement> results)
	{
		var child = FirstChild;
		while (child != null)
		{
			if (let elem = child as XmlElement)
			{
				if (tagName.IsEmpty || elem.TagName == tagName)
					results.Add(elem);
				elem.GetDescendantElements(tagName, results);
			}
			child = child.NextSibling;
		}
	}

	// ---- Text Content ----

	/// <summary>
	/// Gets the combined text content of all descendant text nodes.
	/// </summary>
	public void GetTextContent(String output)
	{
		GetInnerText(output);
	}

	/// <summary>
	/// Sets the text content, removing all children and adding a single text node.
	/// </summary>
	public void SetTextContent(StringView text)
	{
		ClearChildren();
		if (!text.IsEmpty)
		{
			let textNode = new XmlText(text);
			AppendChild(textNode);
		}
	}

	// ---- XmlNode Overrides ----

	public override void GetInnerText(String output)
	{
		var child = FirstChild;
		while (child != null)
		{
			child.GetInnerText(output);
			child = child.NextSibling;
		}
	}

	public override void GetOuterXml(String output)
	{
		output.Append('<');
		output.Append(mTagName);

		// Write attributes
		for (let attr in mAttributes)
		{
			output.Append(' ');
			attr.GetOuterXml(output);
		}

		if (!HasChildren)
		{
			// Self-closing tag
			output.Append("/>");
		}
		else
		{
			output.Append('>');

			// Write children
			var child = FirstChild;
			while (child != null)
			{
				child.GetOuterXml(output);
				child = child.NextSibling;
			}

			// Closing tag
			output.Append("</");
			output.Append(mTagName);
			output.Append('>');
		}
	}
}
