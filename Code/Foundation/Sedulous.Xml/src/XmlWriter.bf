using System;

namespace Sedulous.Xml;

/// Formats a tree back into XML.
///
/// An element holding exactly one text or CDATA child is written inline, because breaking
/// <name>value</name> across three lines adds whitespace to its content that reading it
/// back would then have to decide what to do with.
class XmlWriter
{
	private String mOutput;
	private XmlWriteSettings mSettings = .Default;
	private int32 mIndentLevel;

	public this(String output)
	{
		mOutput = output;
	}

	public this(String output, XmlWriteSettings settings)
	{
		mOutput = output;
		mSettings = settings;
	}

	public XmlWriteSettings Settings
	{
		get => mSettings;
		set => mSettings = value;
	}

	public void Clear()
	{
		mOutput.Clear();
		mIndentLevel = 0;
	}

	public StringView Output => mOutput;

	public void WriteDocument(XmlDocument document)
	{
		if (!mSettings.OmitDeclaration && (document.Declaration != null))
		{
			WriteDeclaration(document.Declaration);
			WriteNewLine();
		}

		for (var child = document.FirstChild; child != null; child = child.NextSibling)
		{
			// The declaration was already written, and never twice.
			if (child.NodeType != .Declaration)
				WriteNode(child);
		}
	}

	public void WriteNode(XmlNode node)
	{
		switch (node.NodeType)
		{
		case .Element: WriteElement((XmlElement)node);
		case .Text: WriteText((XmlText)node);
		case .CData: WriteCData((XmlCData)node);
		case .Comment: WriteComment((XmlComment)node);
		case .Declaration: WriteDeclaration((XmlDeclaration)node);
		case .ProcessingInstruction: WriteProcessingInstruction((XmlProcessingInstruction)node);
		default: // Attribute and Document are written by their owners.
		}
	}

	public void WriteElement(XmlElement element)
	{
		WriteIndent();
		mOutput.Append('<');
		mOutput.Append(element.TagName);
		for (let attribute in element.Attributes)
		{
			mOutput.Append(' ');
			WriteAttribute(attribute);
		}

		if (!element.HasChildren)
		{
			mOutput.Append("/>");
			return;
		}
		mOutput.Append('>');

		// One text or CDATA child stays on the line with its tags.
		let simple = (element.ChildCount == 1)
			&& ((element.FirstChild.NodeType == .Text) || (element.FirstChild.NodeType == .CData));

		if (!simple && !mSettings.CompactMode)
			WriteNewLine();
		mIndentLevel++;

		for (var child = element.FirstChild; child != null; child = child.NextSibling)
		{
			if (simple || mSettings.CompactMode)
			{
				// Written without the indent a WriteNode would add.
				if (let text = child as XmlText)
					EscapeText(text.Text, mOutput);
				else if (let cdata = child as XmlCData)
				{
					mOutput.Append("<![CDATA[");
					mOutput.Append(cdata.Data);
					mOutput.Append("]]>");
				}
				else
					WriteNode(child);
			}
			else
			{
				WriteNode(child);
				WriteNewLine();
			}
		}

		mIndentLevel--;
		if (!simple && !mSettings.CompactMode)
			WriteIndent();
		mOutput.Append("</");
		mOutput.Append(element.TagName);
		mOutput.Append('>');
	}

	public void WriteAttribute(XmlAttribute attribute)
	{
		mOutput.Append(attribute.Name);
		mOutput.Append("=\"");
		EscapeAttributeValue(attribute.Value, mOutput);
		mOutput.Append('"');
	}

	public void WriteText(XmlText text)
	{
		if (!mSettings.CompactMode)
			WriteIndent();
		EscapeText(text.Text, mOutput);
	}

	public void WriteCData(XmlCData cdata)
	{
		if (!mSettings.CompactMode)
			WriteIndent();
		mOutput.Append("<![CDATA[");
		mOutput.Append(cdata.Data);
		mOutput.Append("]]>");
	}

	public void WriteComment(XmlComment comment)
	{
		if (!mSettings.CompactMode)
			WriteIndent();
		mOutput.Append("<!--");
		mOutput.Append(comment.Text);
		mOutput.Append("-->");
	}

	/// Never indented: a declaration is only ever the first thing in a document.
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

	public void WriteProcessingInstruction(XmlProcessingInstruction instruction)
	{
		if (!mSettings.CompactMode)
			WriteIndent();
		mOutput.Append("<?");
		mOutput.Append(instruction.Target);
		if (!instruction.Data.IsEmpty)
		{
			mOutput.Append(' ');
			mOutput.Append(instruction.Data);
		}
		mOutput.Append("?>");
	}

	private void WriteIndent()
	{
		if (mSettings.CompactMode || !mSettings.Indent)
			return;
		for (int32 i < mIndentLevel)
			mOutput.Append(mSettings.IndentString);
	}

	private void WriteNewLine()
	{
		if (!mSettings.CompactMode)
			mOutput.Append(mSettings.NewLine);
	}
}
