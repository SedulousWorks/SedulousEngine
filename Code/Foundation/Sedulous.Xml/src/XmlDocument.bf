using System;
using System.Collections;

namespace Sedulous.Xml;

/// <summary>
/// Settings for XML parsing.
/// </summary>
struct XmlParseSettings
{
	/// <summary>
	/// Whether to preserve whitespace-only text nodes.
	/// </summary>
	public bool PreserveWhitespace = false;

	/// <summary>
	/// Whether to ignore comments during parsing.
	/// </summary>
	public bool IgnoreComments = false;

	/// <summary>
	/// Whether to ignore processing instructions during parsing.
	/// </summary>
	public bool IgnoreProcessingInstructions = false;

	/// <summary>
	/// Whether to validate namespace declarations.
	/// </summary>
	public bool ValidateNamespaces = true;

	/// <summary>
	/// Creates default settings.
	/// </summary>
	public static XmlParseSettings Default => .();
}

/// <summary>
/// Represents an XML document and provides parsing functionality.
/// </summary>
class XmlDocument : XmlNode
{
	private XmlDeclaration mDeclaration;
	private XmlElement mRootElement;
	private XmlParseSettings mParseSettings;
	private int32 mErrorLine;
	private int32 mErrorColumn;
	private StringView mOriginalText;

	public this() : base(.Document)
	{
		mParseSettings = .Default;
	}

	// ---- Tree Manipulation Overrides ----

	/// <summary>
	/// Appends a child node, tracking declaration and root element.
	/// </summary>
	public new void AppendChild(XmlNode child)
	{
		base.AppendChild(child);

		// Track declaration
		if (let decl = child as XmlDeclaration)
			mDeclaration = decl;

		// Track root element
		if (let elem = child as XmlElement)
		{
			if (mRootElement == null)
				mRootElement = elem;
		}
	}

	// ---- Document Properties ----

	/// <summary>
	/// Gets the XML declaration (if present).
	/// </summary>
	public XmlDeclaration Declaration => mDeclaration;

	/// <summary>
	/// Gets the root element.
	/// </summary>
	public XmlElement RootElement => mRootElement;

	/// <summary>
	/// Gets the line number of the last error.
	/// </summary>
	public int32 ErrorLine => mErrorLine;

	/// <summary>
	/// Gets the column number of the last error.
	/// </summary>
	public int32 ErrorColumn => mErrorColumn;

	// ---- Parsing ----

	/// <summary>
	/// Parses an XML document from text.
	/// </summary>
	public XmlResult Parse(StringView text)
	{
		return Parse(text, .Default);
	}

	/// <summary>
	/// Parses an XML document from text with settings.
	/// </summary>
	public XmlResult Parse(StringView text, XmlParseSettings settings)
	{
		// Clear previous content
		ClearChildren();
		mDeclaration = null;
		mRootElement = null;
		mErrorLine = 1;
		mErrorColumn = 1;
		mParseSettings = settings;
		mOriginalText = text;

		var remaining = text;
		return ParseDocument(ref remaining);
	}

	private XmlResult ParseDocument(ref StringView text)
	{
		// Skip leading whitespace
		SkipWhitespace(ref text);

		if (text.IsEmpty)
			return .NoRootElement;

		// Check for XML declaration
		if (text.StartsWith("<?xml"))
		{
			let result = ParseDeclaration(ref text);
			if (result != .Ok)
				return result;
			SkipWhitespace(ref text);
		}

		// Parse misc (comments, PIs) before root element
		while (!text.IsEmpty)
		{
			if (text.StartsWith("<!--"))
			{
				if (!mParseSettings.IgnoreComments)
				{
					let result = ParseComment(ref text, this);
					if (result != .Ok)
						return result;
				}
				else
				{
					let result = SkipComment(ref text);
					if (result != .Ok)
						return result;
				}
				SkipWhitespace(ref text);
			}
			else if (text.StartsWith("<?"))
			{
				if (!mParseSettings.IgnoreProcessingInstructions)
				{
					let result = ParseProcessingInstruction(ref text, this);
					if (result != .Ok)
						return result;
				}
				else
				{
					let result = SkipProcessingInstruction(ref text);
					if (result != .Ok)
						return result;
				}
				SkipWhitespace(ref text);
			}
			else
			{
				break;
			}
		}

		// Parse root element
		if (text.IsEmpty || !text.StartsWith("<"))
			return .NoRootElement;

		if (text.StartsWith("</"))
			return .TagUnexpectedClose;

		let rootResult = ParseElement(ref text, this);
		if (rootResult != .Ok)
			return rootResult;

		// Parse misc (comments, PIs) after root element
		SkipWhitespace(ref text);

		while (!text.IsEmpty)
		{
			if (text.StartsWith("<!--"))
			{
				if (!mParseSettings.IgnoreComments)
				{
					let result = ParseComment(ref text, this);
					if (result != .Ok)
						return result;
				}
				else
				{
					let result = SkipComment(ref text);
					if (result != .Ok)
						return result;
				}
				SkipWhitespace(ref text);
			}
			else if (text.StartsWith("<?"))
			{
				if (!mParseSettings.IgnoreProcessingInstructions)
				{
					let result = ParseProcessingInstruction(ref text, this);
					if (result != .Ok)
						return result;
				}
				else
				{
					let result = SkipProcessingInstruction(ref text);
					if (result != .Ok)
						return result;
				}
				SkipWhitespace(ref text);
			}
			else if (text.StartsWith("<"))
			{
				// Another element - not allowed
				return .MultipleRoots;
			}
			else
			{
				// Non-whitespace content after root
				bool hasContent = false;
				for (let c in text)
				{
					if (!XmlLexer.IsWhitespace(c))
					{
						hasContent = true;
						break;
					}
				}
				if (hasContent)
					return .ContentAfterRoot;
				break;
			}
		}

		return .Ok;
	}

	private XmlResult ParseDeclaration(ref StringView text)
	{
		// <?xml version="1.0" encoding="utf-8" standalone="yes"?>
		if (!text.StartsWith("<?xml"))
			return .DeclarationInvalid;

		text = text.Substring(5);
		SkipWhitespace(ref text);

		let declaration = new XmlDeclaration();
		mDeclaration = declaration;
		AppendChild(declaration);

		// Parse version (required)
		if (!text.StartsWith("version"))
		{
			delete declaration;
			return .DeclarationVersion;
		}

		text = text.Substring(7);
		SkipWhitespace(ref text);

		if (text.IsEmpty || text[0] != '=')
		{
			delete declaration;
			return .DeclarationVersion;
		}

		text = text.Substring(1);
		SkipWhitespace(ref text);

		let versionStr = scope String();
		let versionResult = XmlLexer.ReadAttributeValue(text, var versionLen, versionStr);
		if (versionResult != .Ok)
		{
			delete declaration;
			return .DeclarationVersion;
		}

		text = text.Substring(versionLen);
		declaration.SetVersion(versionStr);
		SkipWhitespace(ref text);

		// Parse optional encoding
		if (text.StartsWith("encoding"))
		{
			text = text.Substring(8);
			SkipWhitespace(ref text);

			if (text.IsEmpty || text[0] != '=')
			{
				delete declaration;
				return .DeclarationInvalid;
			}

			text = text.Substring(1);
			SkipWhitespace(ref text);

			let encodingStr = scope String();
			let encodingResult = XmlLexer.ReadAttributeValue(text, var encodingLen, encodingStr);
			if (encodingResult != .Ok)
			{
				delete declaration;
				return .DeclarationInvalid;
			}

			text = text.Substring(encodingLen);
			declaration.SetEncoding(encodingStr);
			SkipWhitespace(ref text);
		}

		// Parse optional standalone
		if (text.StartsWith("standalone"))
		{
			text = text.Substring(10);
			SkipWhitespace(ref text);

			if (text.IsEmpty || text[0] != '=')
			{
				delete declaration;
				return .DeclarationInvalid;
			}

			text = text.Substring(1);
			SkipWhitespace(ref text);

			let standaloneStr = scope String();
			let standaloneResult = XmlLexer.ReadAttributeValue(text, var standaloneLen, standaloneStr);
			if (standaloneResult != .Ok)
			{
				delete declaration;
				return .DeclarationInvalid;
			}

			text = text.Substring(standaloneLen);
			declaration.SetStandalone(standaloneStr);
			SkipWhitespace(ref text);
		}

		// Expect ?>
		if (!text.StartsWith("?>"))
		{
			delete declaration;
			return .DeclarationInvalid;
		}

		text = text.Substring(2);
		return .Ok;
	}

	private XmlResult ParseElement(ref StringView text, XmlNode parent)
	{
		// <tagname attr="value">content</tagname>
		if (!text.StartsWith("<"))
			return .SyntaxError;

		text = text.Substring(1);

		// Read tag name
		let tagName = scope String();
		let nameResult = XmlLexer.ReadName(text, var nameLen, tagName);
		if (nameResult != .Ok)
			return .TagInvalid;

		text = text.Substring(nameLen);

		let element = new XmlElement(tagName);

		// Track root element
		if (parent == this && mRootElement == null)
			mRootElement = element;

		// Parse attributes
		let attrResult = ParseAttributes(ref text, element);
		if (attrResult != .Ok)
		{
			delete element;
			return attrResult;
		}

		SkipWhitespace(ref text);

		// Check for self-closing tag
		if (text.StartsWith("/>"))
		{
			text = text.Substring(2);
			parent.AppendChild(element);
			return .Ok;
		}

		// Expect >
		if (text.IsEmpty || text[0] != '>')
		{
			delete element;
			return .TagUnclosed;
		}

		text = text.Substring(1);
		parent.AppendChild(element);

		// Parse content
		let contentResult = ParseContent(ref text, element);
		if (contentResult != .Ok)
			return contentResult;

		// Expect closing tag
		if (!text.StartsWith("</"))
			return .TagUnclosed;

		text = text.Substring(2);

		// Read closing tag name
		let closingName = scope String();
		let closingResult = XmlLexer.ReadName(text, var closingLen, closingName);
		if (closingResult != .Ok)
			return .TagInvalid;

		text = text.Substring(closingLen);

		// Verify tag names match
		if (closingName != tagName)
			return .TagMismatch;

		SkipWhitespace(ref text);

		// Expect >
		if (text.IsEmpty || text[0] != '>')
			return .TagUnclosed;

		text = text.Substring(1);
		return .Ok;
	}

	private XmlResult ParseAttributes(ref StringView text, XmlElement element)
	{
		while (true)
		{
			SkipWhitespace(ref text);

			if (text.IsEmpty)
				return .UnexpectedEndOfFile;

			// Check for end of opening tag
			if (text[0] == '>' || text.StartsWith("/>"))
				return .Ok;

			// Read attribute name
			let attrName = scope String();
			let nameResult = XmlLexer.ReadName(text, var nameLen, attrName);
			if (nameResult != .Ok)
				return .AttributeInvalid;

			text = text.Substring(nameLen);
			SkipWhitespace(ref text);

			// Check for duplicate attribute
			if (element.HasAttribute(attrName))
				return .AttributeDuplicate;

			// Expect =
			if (text.IsEmpty || text[0] != '=')
				return .AttributeMissingEquals;

			text = text.Substring(1);
			SkipWhitespace(ref text);

			// Read attribute value
			let attrValue = scope String();
			let valueResult = XmlLexer.ReadAttributeValue(text, var valueLen, attrValue);
			if (valueResult != .Ok)
				return valueResult;

			text = text.Substring(valueLen);

			// Add attribute to element
			element.SetAttribute(attrName, attrValue);
		}
	}

	private XmlResult ParseContent(ref StringView text, XmlElement parent)
	{
		while (!text.IsEmpty)
		{
			if (text.StartsWith("</"))
			{
				// End of this element
				return .Ok;
			}

			if (text.StartsWith("<![CDATA["))
			{
				let result = ParseCData(ref text, parent);
				if (result != .Ok)
					return result;
			}
			else if (text.StartsWith("<!--"))
			{
				if (!mParseSettings.IgnoreComments)
				{
					let result = ParseComment(ref text, parent);
					if (result != .Ok)
						return result;
				}
				else
				{
					let result = SkipComment(ref text);
					if (result != .Ok)
						return result;
				}
			}
			else if (text.StartsWith("<?"))
			{
				if (!mParseSettings.IgnoreProcessingInstructions)
				{
					let result = ParseProcessingInstruction(ref text, parent);
					if (result != .Ok)
						return result;
				}
				else
				{
					let result = SkipProcessingInstruction(ref text);
					if (result != .Ok)
						return result;
				}
			}
			else if (text.StartsWith("<"))
			{
				// Child element
				let result = ParseElement(ref text, parent);
				if (result != .Ok)
					return result;
			}
			else
			{
				// Text content
				let result = ParseTextContent(ref text, parent);
				if (result != .Ok)
					return result;
			}
		}

		return .UnexpectedEndOfFile;
	}

	private XmlResult ParseTextContent(ref StringView text, XmlNode parent)
	{
		let content = scope String();
		let result = XmlLexer.ReadTextContent(text, var len, content);
		if (result != .Ok)
			return result;

		text = text.Substring(len);

		// Check if this is whitespace-only
		bool isWhitespace = true;
		for (let c in content.RawChars)
		{
			if (!XmlLexer.IsWhitespace(c))
			{
				isWhitespace = false;
				break;
			}
		}

		// Skip whitespace-only text if not preserving
		if (isWhitespace && !mParseSettings.PreserveWhitespace)
			return .Ok;

		// Don't create empty text nodes
		if (content.IsEmpty)
			return .Ok;

		let textNode = new XmlText(content);
		parent.AppendChild(textNode);
		return .Ok;
	}

	private XmlResult ParseCData(ref StringView text, XmlNode parent)
	{
		// <![CDATA[...]]>
		if (!text.StartsWith("<![CDATA["))
			return .CDataMalformed;

		text = text.Substring(9);

		let content = scope String();
		let result = XmlLexer.ReadCDataContent(text, var len, content);
		if (result != .Ok)
			return result;

		text = text.Substring(len);

		let cdata = new XmlCData(content);
		parent.AppendChild(cdata);
		return .Ok;
	}

	private XmlResult ParseComment(ref StringView text, XmlNode parent)
	{
		// <!--...-->
		if (!text.StartsWith("<!--"))
			return .CommentMalformed;

		text = text.Substring(4);

		let content = scope String();
		let result = XmlLexer.ReadCommentContent(text, var len, content);
		if (result != .Ok)
			return result;

		text = text.Substring(len);

		let comment = new XmlComment(content);
		parent.AppendChild(comment);
		return .Ok;
	}

	private XmlResult SkipComment(ref StringView text)
	{
		if (!text.StartsWith("<!--"))
			return .CommentMalformed;

		text = text.Substring(4);

		let content = scope String();
		let result = XmlLexer.ReadCommentContent(text, var len, content);
		if (result != .Ok)
			return result;

		text = text.Substring(len);
		return .Ok;
	}

	private XmlResult ParseProcessingInstruction(ref StringView text, XmlNode parent)
	{
		// <?target data?>
		if (!text.StartsWith("<?"))
			return .PIInvalid;

		text = text.Substring(2);

		let target = scope String();
		let data = scope String();
		let result = XmlLexer.ReadProcessingInstruction(text, var len, target, data);
		if (result != .Ok)
			return result;

		text = text.Substring(len);

		// Don't allow "xml" as PI target (that's the declaration)
		if (target.Equals("xml", .OrdinalIgnoreCase))
			return .DeclarationPosition;

		let pi = new XmlProcessingInstruction(target, data);
		parent.AppendChild(pi);
		return .Ok;
	}

	private XmlResult SkipProcessingInstruction(ref StringView text)
	{
		if (!text.StartsWith("<?"))
			return .PIInvalid;

		text = text.Substring(2);

		let target = scope String();
		let data = scope String();
		let result = XmlLexer.ReadProcessingInstruction(text, var len, target, data);
		if (result != .Ok)
			return result;

		text = text.Substring(len);
		return .Ok;
	}

	private void SkipWhitespace(ref StringView text)
	{
		let wsLen = XmlLexer.GetWhitespaceLength(text);
		if (wsLen > 0)
			text = text.Substring(wsLen);
	}

	// ---- Writing ----

	/// <summary>
	/// Writes the document to a string.
	/// </summary>
	public void WriteTo(String output)
	{
		WriteTo(output, .Default);
	}

	/// <summary>
	/// Writes the document to a string with settings.
	/// </summary>
	public void WriteTo(String output, XmlWriteSettings settings)
	{
		let writer = scope XmlWriter(output, settings);
		writer.WriteDocument(this);
	}

	// ---- Element Creation (Factory Methods) ----

	/// <summary>
	/// Creates a new element with the given tag name.
	/// </summary>
	public XmlElement CreateElement(StringView name)
	{
		return new XmlElement(name);
	}

	/// <summary>
	/// Creates a new element with namespace.
	/// </summary>
	public XmlElement CreateElement(StringView prefix, StringView localName, StringView namespaceUri)
	{
		return new XmlElement(prefix, localName, namespaceUri);
	}

	/// <summary>
	/// Creates a new attribute.
	/// </summary>
	public XmlAttribute CreateAttribute(StringView name)
	{
		return new XmlAttribute(name, "");
	}

	/// <summary>
	/// Creates a new attribute with namespace.
	/// </summary>
	public XmlAttribute CreateAttribute(StringView prefix, StringView localName, StringView namespaceUri)
	{
		return new XmlAttribute(prefix, localName, namespaceUri, "");
	}

	/// <summary>
	/// Creates a new text node.
	/// </summary>
	public XmlText CreateTextNode(StringView text)
	{
		return new XmlText(text);
	}

	/// <summary>
	/// Creates a new CDATA section.
	/// </summary>
	public XmlCData CreateCDataSection(StringView data)
	{
		return new XmlCData(data);
	}

	/// <summary>
	/// Creates a new comment.
	/// </summary>
	public XmlComment CreateComment(StringView text)
	{
		return new XmlComment(text);
	}

	/// <summary>
	/// Creates a new processing instruction.
	/// </summary>
	public XmlProcessingInstruction CreateProcessingInstruction(StringView target, StringView data)
	{
		return new XmlProcessingInstruction(target, data);
	}

	// ---- Query Methods ----

	/// <summary>
	/// Gets all elements with the given tag name (recursive).
	/// </summary>
	public void GetElementsByTagName(StringView name, List<XmlElement> results)
	{
		if (mRootElement != null)
		{
			if (name.IsEmpty || mRootElement.TagName == name)
				results.Add(mRootElement);
			mRootElement.GetDescendantElements(name, results);
		}
	}

	/// <summary>
	/// Gets all elements with the given namespace and local name (recursive).
	/// </summary>
	public void GetElementsByTagNameNS(StringView namespaceUri, StringView localName, List<XmlElement> results)
	{
		if (mRootElement != null)
		{
			GetElementsByTagNameNSRecursive(mRootElement, namespaceUri, localName, results);
		}
	}

	private void GetElementsByTagNameNSRecursive(XmlElement element, StringView namespaceUri, StringView localName, List<XmlElement> results)
	{
		if ((namespaceUri.IsEmpty || element.NamespaceUri == namespaceUri) &&
			(localName.IsEmpty || element.LocalName == localName))
		{
			results.Add(element);
		}

		var child = element.FirstChild;
		while (child != null)
		{
			if (let childElem = child as XmlElement)
				GetElementsByTagNameNSRecursive(childElem, namespaceUri, localName, results);
			child = child.NextSibling;
		}
	}

	/// <summary>
	/// Gets an element by its ID attribute.
	/// </summary>
	public XmlElement GetElementById(StringView id)
	{
		if (mRootElement == null)
			return null;
		return GetElementByIdRecursive(mRootElement, id);
	}

	private XmlElement GetElementByIdRecursive(XmlElement element, StringView id)
	{
		if (element.GetAttribute("id") == id)
			return element;

		var child = element.FirstChild;
		while (child != null)
		{
			if (let childElem = child as XmlElement)
			{
				let found = GetElementByIdRecursive(childElem, id);
				if (found != null)
					return found;
			}
			child = child.NextSibling;
		}

		return null;
	}

	// ---- XmlNode Overrides ----

	public override void GetInnerText(String output)
	{
		if (mRootElement != null)
			mRootElement.GetInnerText(output);
	}

	public override void GetOuterXml(String output)
	{
		let writer = scope XmlWriter(output);
		writer.WriteDocument(this);
	}
}
