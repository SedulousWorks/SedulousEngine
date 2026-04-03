using System;

namespace Sedulous.Xml;

/// <summary>
/// Settings for XML writing.
/// </summary>
struct XmlWriteSettings
{
	/// <summary>
	/// Whether to indent the output.
	/// </summary>
	public bool Indent = true;

	/// <summary>
	/// The string to use for indentation (default is tab).
	/// </summary>
	public StringView IndentString = "\t";

	/// <summary>
	/// The string to use for new lines.
	/// </summary>
	public StringView NewLine = "\n";

	/// <summary>
	/// Whether to omit the XML declaration.
	/// </summary>
	public bool OmitDeclaration = false;

	/// <summary>
	/// Whether to use compact mode (no whitespace between elements).
	/// </summary>
	public bool CompactMode = false;

	/// <summary>
	/// Creates default settings.
	/// </summary>
	public static XmlWriteSettings Default => .();
}

/// <summary>
/// XML serialization writer.
/// </summary>
class XmlWriter
{
	private String mOutput;
	private XmlWriteSettings mSettings;
	private int mIndentLevel = 0;
	private bool mOwnsOutput = false;

	/// <summary>
	/// Creates a new writer with internal string storage.
	/// </summary>
	public this()
	{
		mOutput = new String();
		mOwnsOutput = true;
		mSettings = .Default;
	}

	/// <summary>
	/// Creates a new writer that writes to the specified string.
	/// </summary>
	public this(String output)
	{
		mOutput = output;
		mOwnsOutput = false;
		mSettings = .Default;
	}

	/// <summary>
	/// Creates a new writer with the specified settings.
	/// </summary>
	public this(XmlWriteSettings settings)
	{
		mOutput = new String();
		mOwnsOutput = true;
		mSettings = settings;
	}

	/// <summary>
	/// Creates a new writer that writes to the specified string with settings.
	/// </summary>
	public this(String output, XmlWriteSettings settings)
	{
		mOutput = output;
		mOwnsOutput = false;
		mSettings = settings;
	}

	public ~this()
	{
		if (mOwnsOutput)
			delete mOutput;
	}

	/// <summary>
	/// Gets or sets the write settings.
	/// </summary>
	public XmlWriteSettings Settings
	{
		get => mSettings;
		set => mSettings = value;
	}

	/// <summary>
	/// Clears the output.
	/// </summary>
	public void Clear()
	{
		mOutput.Clear();
		mIndentLevel = 0;
	}

	/// <summary>
	/// Gets the output string.
	/// </summary>
	public StringView Output => mOutput;

	/// <summary>
	/// Copies the output to another string.
	/// </summary>
	public void CopyTo(String output)
	{
		output.Append(mOutput);
	}

	/// <summary>
	/// Writes an XML document.
	/// </summary>
	public void WriteDocument(XmlDocument document)
	{
		// Write declaration
		if (!mSettings.OmitDeclaration && document.Declaration != null)
		{
			WriteDeclaration(document.Declaration);
			WriteNewLine();
		}

		// Write children (comments, PIs, root element)
		var child = document.FirstChild;
		while (child != null)
		{
			if (child.NodeType != .Declaration)
				WriteNode(child);
			child = child.NextSibling;
		}
	}

	/// <summary>
	/// Writes any XML node.
	/// </summary>
	public void WriteNode(XmlNode node)
	{
		switch (node.NodeType)
		{
		case .Element:
			WriteElement(node as XmlElement);
		case .Text:
			WriteText(node as XmlText);
		case .CData:
			WriteCData(node as XmlCData);
		case .Comment:
			WriteComment(node as XmlComment);
		case .Declaration:
			WriteDeclaration(node as XmlDeclaration);
		case .ProcessingInstruction:
			WriteProcessingInstruction(node as XmlProcessingInstruction);
		default:
			// Attribute and Document are handled specially
		}
	}

	/// <summary>
	/// Writes an element.
	/// </summary>
	public void WriteElement(XmlElement element)
	{
		WriteIndent();
		mOutput.Append('<');
		mOutput.Append(element.TagName);

		// Write attributes
		for (let attr in element.Attributes)
		{
			mOutput.Append(' ');
			WriteAttribute(attr);
		}

		if (!element.HasChildren)
		{
			// Self-closing tag
			mOutput.Append("/>");
		}
		else
		{
			mOutput.Append('>');

			// Check if content is simple (single text node)
			let isSimpleContent = element.ChildCount == 1 &&
				(element.FirstChild.NodeType == .Text || element.FirstChild.NodeType == .CData);

			if (!isSimpleContent && !mSettings.CompactMode)
				WriteNewLine();

			mIndentLevel++;

			// Write children
			var child = element.FirstChild;
			while (child != null)
			{
				if (isSimpleContent || mSettings.CompactMode)
				{
					// Write inline without indentation
					switch (child.NodeType)
					{
					case .Text:
						let text = child as XmlText;
						EscapeText(text.Text, mOutput);
					case .CData:
						let cdata = child as XmlCData;
						mOutput.Append("<![CDATA[");
						mOutput.Append(cdata.Data);
						mOutput.Append("]]>");
					default:
						WriteNode(child);
					}
				}
				else
				{
					WriteNode(child);
					WriteNewLine();
				}
				child = child.NextSibling;
			}

			mIndentLevel--;

			if (!isSimpleContent && !mSettings.CompactMode)
				WriteIndent();

			// Closing tag
			mOutput.Append("</");
			mOutput.Append(element.TagName);
			mOutput.Append('>');
		}
	}

	/// <summary>
	/// Writes an attribute.
	/// </summary>
	public void WriteAttribute(XmlAttribute attribute)
	{
		mOutput.Append(attribute.Name);
		mOutput.Append("=\"");
		EscapeAttributeValue(attribute.Value, mOutput);
		mOutput.Append('"');
	}

	/// <summary>
	/// Writes a text node.
	/// </summary>
	public void WriteText(XmlText text)
	{
		if (!mSettings.CompactMode)
			WriteIndent();
		EscapeText(text.Text, mOutput);
	}

	/// <summary>
	/// Writes a CDATA section.
	/// </summary>
	public void WriteCData(XmlCData cdata)
	{
		if (!mSettings.CompactMode)
			WriteIndent();
		mOutput.Append("<![CDATA[");
		mOutput.Append(cdata.Data);
		mOutput.Append("]]>");
	}

	/// <summary>
	/// Writes a comment.
	/// </summary>
	public void WriteComment(XmlComment comment)
	{
		if (!mSettings.CompactMode)
			WriteIndent();
		mOutput.Append("<!--");
		mOutput.Append(comment.Text);
		mOutput.Append("-->");
	}

	/// <summary>
	/// Writes an XML declaration.
	/// </summary>
	public void WriteDeclaration(XmlDeclaration declaration)
	{
		mOutput.Append("<?xml version=\"");
		mOutput.Append(declaration.Version);
		mOutput.Append("\"");

		if (!declaration.Encoding.IsEmpty)
		{
			mOutput.Append(" encoding=\"");
			mOutput.Append(declaration.Encoding);
			mOutput.Append("\"");
		}

		if (!declaration.Standalone.IsEmpty)
		{
			mOutput.Append(" standalone=\"");
			mOutput.Append(declaration.Standalone);
			mOutput.Append("\"");
		}

		mOutput.Append("?>");
	}

	/// <summary>
	/// Writes a processing instruction.
	/// </summary>
	public void WriteProcessingInstruction(XmlProcessingInstruction pi)
	{
		if (!mSettings.CompactMode)
			WriteIndent();
		mOutput.Append("<?");
		mOutput.Append(pi.Target);
		if (!pi.Data.IsEmpty)
		{
			mOutput.Append(' ');
			mOutput.Append(pi.Data);
		}
		mOutput.Append("?>");
	}

	private void WriteIndent()
	{
		if (mSettings.CompactMode || !mSettings.Indent)
			return;

		for (var i = 0; i < mIndentLevel; i++)
			mOutput.Append(mSettings.IndentString);
	}

	private void WriteNewLine()
	{
		if (!mSettings.CompactMode)
			mOutput.Append(mSettings.NewLine);
	}

	/// <summary>
	/// Escapes text content for XML output.
	/// </summary>
	public static void EscapeText(StringView text, String output)
	{
		for (let c in text)
		{
			switch (c)
			{
			case '&':
				output.Append("&amp;");
			case '<':
				output.Append("&lt;");
			case '>':
				output.Append("&gt;");
			default:
				output.Append(c);
			}
		}
	}

	/// <summary>
	/// Escapes attribute value for XML output.
	/// </summary>
	public static void EscapeAttributeValue(StringView value, String output)
	{
		for (let c in value)
		{
			switch (c)
			{
			case '&':
				output.Append("&amp;");
			case '<':
				output.Append("&lt;");
			case '>':
				output.Append("&gt;");
			case '"':
				output.Append("&quot;");
			case '\'':
				output.Append("&apos;");
			case '\r':
				output.Append("&#xD;");
			case '\n':
				output.Append("&#xA;");
			case '\t':
				output.Append("&#x9;");
			default:
				output.Append(c);
			}
		}
	}
}

/// <summary>
/// Extension methods for convenient serialization.
/// </summary>
static class XmlWriterExtensions
{
	/// <summary>
	/// Converts a document to XML string.
	/// </summary>
	public static void ToXml(this XmlDocument doc, String output, bool compact = false)
	{
		var settings = XmlWriteSettings.Default;
		settings.CompactMode = compact;
		let writer = scope XmlWriter(output, settings);
		writer.WriteDocument(doc);
	}

	/// <summary>
	/// Converts an element to XML string.
	/// </summary>
	public static void ToXml(this XmlElement element, String output, bool compact = false)
	{
		var settings = XmlWriteSettings.Default;
		settings.CompactMode = compact;
		let writer = scope XmlWriter(output, settings);
		writer.WriteElement(element);
	}
}
