namespace Sedulous.Xml;

/// What kind of node this is.
enum XmlNodeType : uint8
{
	Document,
	Element,
	Attribute,
	Text,
	CData,
	Comment,
	Declaration,
	ProcessingInstruction
}
