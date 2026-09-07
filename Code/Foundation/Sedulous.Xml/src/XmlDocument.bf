using System;
using System.Collections;

namespace Sedulous.Xml;

/// A parsed document, and the factory for the nodes in it.
///
/// Parsing is recursive descent over a view: each step consumes a prefix and hands the
/// rest on, so the position lives in one place and nothing has to be rewound.
class XmlDocument : XmlNode
{
	private XmlDeclaration mDeclaration;
	private XmlElement mRootElement;
	private int32 mErrorLine = 1;
	private int32 mErrorColumn = 1;
	private XmlParseSettings mParseSettings = .Default;

	public this() : base(.Document)
	{
	}

	/// Tracks the declaration and the root element as children arrive, so neither has to
	/// be searched for later.
	public override void AppendChild(XmlNode child)
	{
		base.AppendChild(child);

		if (let declaration = child as XmlDeclaration)
			mDeclaration = declaration;
		else if (mRootElement == null)
		{
			if (let element = child as XmlElement)
				mRootElement = element;
		}
	}

	public XmlDeclaration Declaration => mDeclaration;
	public XmlElement RootElement => mRootElement;

	// ---- parsing ----

	public XmlResult Parse(StringView text) => Parse(text, .Default);

	public XmlResult Parse(StringView text, XmlParseSettings settings)
	{
		ClearChildren();
		mDeclaration = null;
		mRootElement = null;
		mParseSettings = settings;
		mErrorLine = 1;
		mErrorColumn = 1;

		var remaining = text;
		let result = ParseDocument(ref remaining);
		if (result != .Ok)
		{
			// The parser threads the remaining view down by reference, so whatever is left
			// when it gives up starts AT the failure. Counting the consumed prefix once,
			// here, is the whole cost: nothing has to carry a line and column through every
			// scanning function for the case where nothing goes wrong.
			LocateOffset(text, text.Length - remaining.Length);
		}
		return result;
	}

	/// Where the last failed parse gave up: line and column, both counted from ONE, as
	/// every editor and compiler reports them.
	///
	/// Where it GAVE UP, which is just past the thing it rejected rather than at that
	/// thing's first character: a mismatched close tag is detected once its NAME has been
	/// read, so the position lands on the ">" after it. The LINE is exact, which is what an
	/// editor diagnostic marks; the column points at the end of what was wrong rather than
	/// its start. Pinning it to the start would mean carrying a position through every
	/// scanning function for the sake of the case where nothing goes wrong.
	///
	/// Both are 1 after a parse that succeeded, and after no parse at all.
	///
	/// Raptor declares these and never updates them, so they always answer 1 there and the
	/// editor pages that subtract one from the line always mark line zero. Tracked properly
	/// here rather than the stub being carried across.
	public int32 ErrorLine => mErrorLine;
	public int32 ErrorColumn => mErrorColumn;

	/// Turns a byte offset into a line and column by walking the text up to it.
	///
	/// CRLF counts once, and a lone CR counts as a line ending too, so a file written on
	/// any of the three conventions reports the line a person would count.
	///
	/// The column is in BYTES, not characters: a line with a multi byte character before
	/// the error reports a column past where it looks. Honest for the byte oriented scan
	/// this parser is, and what an editor seeking into the buffer wants.
	private void LocateOffset(StringView text, int offset)
	{
		int32 line = 1;
		int32 column = 1;
		// No clamp: `remaining` is always a suffix of `text`, so the offset cannot exceed
		// its length.
		for (int i = 0; i < offset; i++)
		{
			let c = text[i];
			if (c == '\r')
			{
				line++;
				column = 1;
				// A following newline belongs to this same ending.
				if (((i + 1) < offset) && (text[i + 1] == '\n'))
					i++;
			}
			else if (c == '\n')
			{
				line++;
				column = 1;
			}
			else
			{
				column++;
			}
		}

		mErrorLine = line;
		mErrorColumn = column;
	}

	// ---- writing ----

	public void WriteTo(String output) => WriteTo(output, .Default);

	public void WriteTo(String output, XmlWriteSettings settings)
	{
		let writer = scope XmlWriter(output, settings);
		writer.WriteDocument(this);
	}

	// ---- factory ----
	//
	// These only construct; nothing is attached until the caller appends it, and until
	// then the caller owns it.

	public XmlElement CreateElement(StringView name) => new XmlElement(name);
	public XmlElement CreateElement(StringView prefix, StringView localName, StringView namespaceUri) => new XmlElement(prefix, localName, namespaceUri);
	public XmlAttribute CreateAttribute(StringView name) => new XmlAttribute(name, "");
	public XmlAttribute CreateAttribute(StringView prefix, StringView localName, StringView namespaceUri) => new XmlAttribute(prefix, localName, namespaceUri, "");
	public XmlText CreateTextNode(StringView text) => new XmlText(text);
	public XmlCData CreateCDataSection(StringView data) => new XmlCData(data);
	public XmlComment CreateComment(StringView text) => new XmlComment(text);
	public XmlProcessingInstruction CreateProcessingInstruction(StringView target, StringView data) => new XmlProcessingInstruction(target, data);

	// ---- queries ----

	/// The root and every descendant matching a tag name. An empty name matches all.
	public void GetElementsByTagName(StringView name, List<XmlElement> results)
	{
		if (mRootElement == null)
			return;

		if (name.IsEmpty || (mRootElement.TagName == name))
			results.Add(mRootElement);
		mRootElement.GetDescendantElements(name, results);
	}

	/// An empty namespace or local name matches anything in that position.
	public void GetElementsByTagNameNS(StringView namespaceUri, StringView localName, List<XmlElement> results)
	{
		if (mRootElement != null)
			ByTagNameNS(mRootElement, namespaceUri, localName, results);
	}

	/// The first element whose id attribute matches, in document order. Plain id, since
	/// honouring a schema's declared ID type would mean reading one.
	public XmlElement GetElementById(StringView id) => (mRootElement != null) ? ById(mRootElement, id) : null;

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

	// ---- the parser ----

	private static void Advance(ref StringView text, int count) => text = StringView(text, count);

	private static void SkipWhitespace(ref StringView text) => Advance(ref text, XmlLexer.GetWhitespaceLength(text));

	private static bool HasNonWhitespace(StringView text)
	{
		for (let c in text)
		{
			if (!XmlLexer.IsWhitespace(c))
				return true;
		}
		return false;
	}

	/// ASCII only, deliberately: this compares against the literal "xml", and a locale
	/// aware fold would be both slower and wrong for a name that is not ASCII.
	private static bool EqualsIgnoreCaseAscii(StringView a, StringView b)
	{
		if (a.Length != b.Length)
			return false;

		for (int i < a.Length)
		{
			var ca = a[i];
			var cb = b[i];
			if ((ca >= 'A') && (ca <= 'Z'))
				ca = (char8)(ca - 'A' + 'a');
			if ((cb >= 'A') && (cb <= 'Z'))
				cb = (char8)(cb - 'A' + 'a');
			if (ca != cb)
				return false;
		}
		return true;
	}

	private XmlResult ParseDocument(ref StringView text)
	{
		SkipWhitespace(ref text);
		if (text.IsEmpty)
			return .NoRootElement;

		if (text.StartsWith("<?xml"))
		{
			let result = ParseDeclaration(ref text);
			if (result != .Ok)
				return result;
			SkipWhitespace(ref text);
		}

		// Comments and instructions before the root.
		let before = ParseMisc(ref text);
		if (before != .Ok)
			return before;

		if (text.IsEmpty || !text.StartsWith("<"))
			return .NoRootElement;
		if (text.StartsWith("</"))
			return .TagUnexpectedClose;

		let rootResult = ParseElement(ref text, this);
		if (rootResult != .Ok)
			return rootResult;

		// And after it, where a second element would be a second root.
		SkipWhitespace(ref text);
		while (!text.IsEmpty)
		{
			if (text.StartsWith("<!--") || text.StartsWith("<?"))
			{
				let result = ParseMiscItem(ref text, this);
				if (result != .Ok)
					return result;
				SkipWhitespace(ref text);
			}
			else if (text.StartsWith("<"))
			{
				return .MultipleRoots;
			}
			else
			{
				return HasNonWhitespace(text) ? .ContentAfterRoot : .Ok;
			}
		}
		return .Ok;
	}

	/// Consumes comments and instructions until something else, which is not an error:
	/// the caller decides what that something else has to be.
	private XmlResult ParseMisc(ref StringView text)
	{
		while (!text.IsEmpty)
		{
			if (!text.StartsWith("<!--") && !text.StartsWith("<?"))
				break;

			let result = ParseMiscItem(ref text, this);
			if (result != .Ok)
				return result;
			SkipWhitespace(ref text);
		}
		return .Ok;
	}

	/// A comment or an instruction, attached to whichever node is in scope. Ignoring one
	/// still parses it, so a malformed comment is an error whether it is kept or not.
	private XmlResult ParseMiscItem(ref StringView text, XmlNode parent)
	{
		if (text.StartsWith("<!--"))
			return mParseSettings.IgnoreComments ? SkipComment(ref text) : ParseComment(ref text, parent);
		return mParseSettings.IgnoreProcessingInstructions ? SkipProcessingInstruction(ref text) : ParseProcessingInstruction(ref text, parent);
	}

	/// Reads one "name = value" of the declaration. The keyword has already been matched.
	private XmlResult ReadDeclarationValue(ref StringView text, int keywordLength, String output, XmlResult onError)
	{
		Advance(ref text, keywordLength);
		SkipWhitespace(ref text);
		if (text.IsEmpty || (text[0] != '='))
			return onError;

		Advance(ref text, 1);
		SkipWhitespace(ref text);
		if (XmlLexer.ReadAttributeValue(text, let length, output) != .Ok)
			return onError;

		Advance(ref text, length);
		SkipWhitespace(ref text);
		return .Ok;
	}

	private XmlResult ParseDeclaration(ref StringView text)
	{
		if (!text.StartsWith("<?xml"))
			return .DeclarationInvalid;
		Advance(ref text, 5);
		SkipWhitespace(ref text);

		let declaration = new XmlDeclaration();
		let value = scope String();

		// Version is required, and first.
		if (!text.StartsWith("version"))
		{
			delete declaration;
			return .DeclarationVersion;
		}
		if (ReadDeclarationValue(ref text, 7, value, .DeclarationVersion) != .Ok)
		{
			delete declaration;
			return .DeclarationVersion;
		}
		declaration.SetVersion(value);

		if (text.StartsWith("encoding"))
		{
			if (ReadDeclarationValue(ref text, 8, value, .DeclarationInvalid) != .Ok)
			{
				delete declaration;
				return .DeclarationInvalid;
			}
			declaration.SetEncoding(value);
		}

		if (text.StartsWith("standalone"))
		{
			if (ReadDeclarationValue(ref text, 10, value, .DeclarationInvalid) != .Ok)
			{
				delete declaration;
				return .DeclarationInvalid;
			}
			declaration.SetStandalone(value);
		}

		if (!text.StartsWith("?>"))
		{
			delete declaration;
			return .DeclarationInvalid;
		}
		Advance(ref text, 2);

		// Attached only on success, so a failed parse leaves no half-built declaration.
		AppendChild(declaration);
		return .Ok;
	}

	private XmlResult ParseElement(ref StringView text, XmlNode parent)
	{
		if (!text.StartsWith("<"))
			return .SyntaxError;
		Advance(ref text, 1);

		let tagName = scope String();
		if (XmlLexer.ReadName(text, let nameLength, tagName) != .Ok)
			return .TagInvalid;
		Advance(ref text, nameLength);

		let element = new XmlElement(tagName);

		let attributeResult = ParseAttributes(ref text, element);
		if (attributeResult != .Ok)
		{
			delete element;
			return attributeResult;
		}

		SkipWhitespace(ref text);

		if (text.StartsWith("/>"))
		{
			Advance(ref text, 2);
			parent.AppendChild(element);
			return .Ok;
		}

		if (text.IsEmpty || (text[0] != '>'))
		{
			delete element;
			return .TagUnclosed;
		}
		Advance(ref text, 1);

		// Attached BEFORE the content is parsed, so a failure below still leaves the
		// partial subtree owned by the tree and not leaked.
		parent.AppendChild(element);

		let contentResult = ParseContent(ref text, element);
		if (contentResult != .Ok)
			return contentResult;

		if (!text.StartsWith("</"))
			return .TagUnclosed;
		Advance(ref text, 2);

		let closingName = scope String();
		if (XmlLexer.ReadName(text, let closingLength, closingName) != .Ok)
			return .TagInvalid;
		Advance(ref text, closingLength);

		if (closingName != tagName)
			return .TagMismatch;

		SkipWhitespace(ref text);
		if (text.IsEmpty || (text[0] != '>'))
			return .TagUnclosed;
		Advance(ref text, 1);
		return .Ok;
	}

	private XmlResult ParseAttributes(ref StringView text, XmlElement element)
	{
		for (;;)
		{
			SkipWhitespace(ref text);
			if (text.IsEmpty)
				return .UnexpectedEndOfFile;

			// The end of the open tag, either form.
			if ((text[0] == '>') || text.StartsWith("/>"))
				return .Ok;

			let name = scope:: String();
			if (XmlLexer.ReadName(text, let nameLength, name) != .Ok)
				return .AttributeInvalid;
			Advance(ref text, nameLength);
			SkipWhitespace(ref text);

			if (element.HasAttribute(name))
				return .AttributeDuplicate;

			if (text.IsEmpty || (text[0] != '='))
				return .AttributeMissingEquals;
			Advance(ref text, 1);
			SkipWhitespace(ref text);

			let value = scope:: String();
			let valueResult = XmlLexer.ReadAttributeValue(text, let valueLength, value);
			if (valueResult != .Ok)
				return valueResult;
			Advance(ref text, valueLength);

			element.SetAttribute(name, value);
		}
	}

	private XmlResult ParseContent(ref StringView text, XmlElement parent)
	{
		while (!text.IsEmpty)
		{
			// The caller consumes the closing tag, so this stops rather than eating it.
			if (text.StartsWith("</"))
				return .Ok;

			XmlResult result;
			if (text.StartsWith("<![CDATA["))
				result = ParseCData(ref text, parent);
			else if (text.StartsWith("<!--") || text.StartsWith("<?"))
				result = ParseMiscItem(ref text, parent);
			else if (text.StartsWith("<"))
				result = ParseElement(ref text, parent);
			else
				result = ParseTextContent(ref text, parent);

			if (result != .Ok)
				return result;
		}
		// Content ran out before the closing tag did.
		return .UnexpectedEndOfFile;
	}

	private XmlResult ParseTextContent(ref StringView text, XmlNode parent)
	{
		let content = scope String();
		let result = XmlLexer.ReadTextContent(text, let length, content);
		if (result != .Ok)
			return result;
		Advance(ref text, length);

		if (content.IsEmpty)
			return .Ok;

		if (!mParseSettings.PreserveWhitespace && !HasNonWhitespace(content))
			return .Ok;

		parent.AppendChild(new XmlText(content));
		return .Ok;
	}

	private XmlResult ParseCData(ref StringView text, XmlNode parent)
	{
		if (!text.StartsWith("<![CDATA["))
			return .CDataMalformed;
		Advance(ref text, 9);

		let content = scope String();
		let result = XmlLexer.ReadCDataContent(text, let length, content);
		if (result != .Ok)
			return result;
		Advance(ref text, length);

		parent.AppendChild(new XmlCData(content));
		return .Ok;
	}

	private XmlResult ParseComment(ref StringView text, XmlNode parent)
	{
		let content = scope String();
		let result = ReadComment(ref text, content);
		if (result != .Ok)
			return result;

		parent.AppendChild(new XmlComment(content));
		return .Ok;
	}

	/// Parsed and discarded rather than skipped by scanning, so an ignored comment is
	/// still checked for the "--" a comment may not contain.
	private XmlResult SkipComment(ref StringView text) => ReadComment(ref text, scope String());

	private XmlResult ReadComment(ref StringView text, String content)
	{
		if (!text.StartsWith("<!--"))
			return .CommentMalformed;
		Advance(ref text, 4);

		let result = XmlLexer.ReadCommentContent(text, let length, content);
		if (result != .Ok)
			return result;
		Advance(ref text, length);
		return .Ok;
	}

	private XmlResult ParseProcessingInstruction(ref StringView text, XmlNode parent)
	{
		let target = scope String();
		let data = scope String();
		let result = ReadProcessingInstruction(ref text, target, data);
		if (result != .Ok)
			return result;

		// "<?xml" anywhere but the very front is a misplaced declaration, not an
		// instruction that happens to be called xml.
		if (EqualsIgnoreCaseAscii(target, "xml"))
			return .DeclarationPosition;

		parent.AppendChild(new XmlProcessingInstruction(target, data));
		return .Ok;
	}

	private XmlResult SkipProcessingInstruction(ref StringView text) => ReadProcessingInstruction(ref text, scope String(), scope String());

	private XmlResult ReadProcessingInstruction(ref StringView text, String target, String data)
	{
		if (!text.StartsWith("<?"))
			return .PIInvalid;
		Advance(ref text, 2);

		let result = XmlLexer.ReadProcessingInstruction(text, let length, target, data);
		if (result != .Ok)
			return result;
		Advance(ref text, length);
		return .Ok;
	}

	private static void ByTagNameNS(XmlElement element, StringView namespaceUri, StringView localName, List<XmlElement> results)
	{
		if ((namespaceUri.IsEmpty || (element.NamespaceUri == namespaceUri))
			&& (localName.IsEmpty || (element.LocalName == localName)))
			results.Add(element);

		for (var child = element.FirstChild; child != null; child = child.NextSibling)
		{
			if (let childElement = child as XmlElement)
				ByTagNameNS(childElement, namespaceUri, localName, results);
		}
	}

	private static XmlElement ById(XmlElement element, StringView id)
	{
		if (element.GetAttribute("id") == id)
			return element;

		for (var child = element.FirstChild; child != null; child = child.NextSibling)
		{
			if (let childElement = child as XmlElement)
			{
				if (let found = ById(childElement, id))
					return found;
			}
		}
		return null;
	}
}
