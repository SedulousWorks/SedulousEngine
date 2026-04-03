using System;

namespace Sedulous.Xml;

/// <summary>
/// Represents the result of XML parsing operations.
/// Success is indicated by Ok, all other values represent specific errors.
/// </summary>
enum XmlResult : uint32
{
	/// <summary>
	/// The operation completed successfully.
	/// </summary>
	Ok = 0,

	// ---- General Syntax Errors ----

	/// <summary>
	/// The syntax is invalid.
	/// </summary>
	SyntaxError = 0x53594E54, // 'SYNT'

	/// <summary>
	/// Unexpected end of file.
	/// </summary>
	UnexpectedEndOfFile = 0x554E4546, // 'UNEF'

	// ---- Tag Errors ----

	/// <summary>
	/// Opening and closing tags do not match.
	/// </summary>
	TagMismatch = 0x54414D53, // 'TAMS'

	/// <summary>
	/// Tag name is invalid.
	/// </summary>
	TagInvalid = 0x54414956, // 'TAIV'

	/// <summary>
	/// Tag is not closed.
	/// </summary>
	TagUnclosed = 0x5441554E, // 'TAUN'

	/// <summary>
	/// Unexpected closing tag.
	/// </summary>
	TagUnexpectedClose = 0x54415543, // 'TAUC'

	// ---- Name Errors ----

	/// <summary>
	/// No name found where one was expected.
	/// </summary>
	NameEmpty = 0x4E4D454D, // 'NMEM'

	/// <summary>
	/// Name contains an illegal character.
	/// </summary>
	NameIllegalChar = 0x4E4D4943, // 'NMIC'

	/// <summary>
	/// Name starts with reserved prefix.
	/// </summary>
	NameReservedPrefix = 0x4E4D5250, // 'NMRP'

	// ---- Attribute Errors ----

	/// <summary>
	/// Duplicate attribute in an element.
	/// </summary>
	AttributeDuplicate = 0x41544450, // 'ATDP'

	/// <summary>
	/// Attribute name is invalid.
	/// </summary>
	AttributeInvalid = 0x41544956, // 'ATIV'

	/// <summary>
	/// Attribute value is invalid.
	/// </summary>
	AttributeValueInvalid = 0x41565649, // 'AVVI'

	/// <summary>
	/// Missing equals sign in attribute.
	/// </summary>
	AttributeMissingEquals = 0x41544D45, // 'ATME'

	/// <summary>
	/// Missing quote in attribute value.
	/// </summary>
	AttributeMissingQuote = 0x41544D51, // 'ATMQ'

	// ---- Entity Errors ----

	/// <summary>
	/// Unknown entity reference.
	/// </summary>
	EntityUnknown = 0x454E554B, // 'ENUK'

	/// <summary>
	/// Entity reference is malformed.
	/// </summary>
	EntityMalformed = 0x454E4D46, // 'ENMF'

	/// <summary>
	/// Character reference is invalid.
	/// </summary>
	CharRefInvalid = 0x43524956, // 'CRIV'

	/// <summary>
	/// Character reference value is out of range.
	/// </summary>
	CharRefOutOfRange = 0x43524F52, // 'CROR'

	// ---- Content Errors ----

	/// <summary>
	/// CDATA section is malformed.
	/// </summary>
	CDataMalformed = 0x43444D46, // 'CDMF'

	/// <summary>
	/// CDATA section is not closed.
	/// </summary>
	CDataUnclosed = 0x4344554E, // 'CDUN'

	/// <summary>
	/// Comment is malformed.
	/// </summary>
	CommentMalformed = 0x434D4D46, // 'CMMF'

	/// <summary>
	/// Comment is not closed.
	/// </summary>
	CommentUnclosed = 0x434D554E, // 'CMUN'

	/// <summary>
	/// Comment contains illegal sequence (--).
	/// </summary>
	CommentIllegalSequence = 0x434D4953, // 'CMIS'

	/// <summary>
	/// Processing instruction is malformed.
	/// </summary>
	PIInvalid = 0x50494956, // 'PIIV'

	/// <summary>
	/// Processing instruction is not closed.
	/// </summary>
	PIUnclosed = 0x5049554E, // 'PIUN'

	// ---- Declaration Errors ----

	/// <summary>
	/// XML declaration is invalid.
	/// </summary>
	DeclarationInvalid = 0x4443494E, // 'DCIN'

	/// <summary>
	/// XML declaration in wrong position.
	/// </summary>
	DeclarationPosition = 0x44435053, // 'DCPS'

	/// <summary>
	/// Version attribute is missing or invalid.
	/// </summary>
	DeclarationVersion = 0x44435652, // 'DCVR'

	// ---- Namespace Errors ----

	/// <summary>
	/// Namespace prefix is undeclared.
	/// </summary>
	NamespaceUndeclared = 0x4E53554E, // 'NSUN'

	/// <summary>
	/// Namespace declaration is invalid.
	/// </summary>
	NamespaceInvalid = 0x4E534956, // 'NSIV'

	/// <summary>
	/// Prefix is reserved (xml, xmlns).
	/// </summary>
	PrefixReserved = 0x50465253, // 'PFRS'

	/// <summary>
	/// Default namespace cannot be undeclared in XML 1.0.
	/// </summary>
	NamespaceDefaultUndeclare = 0x4E534455, // 'NSDU'

	// ---- Structure Errors ----

	/// <summary>
	/// Document has multiple root elements.
	/// </summary>
	MultipleRoots = 0x4D554C54, // 'MULT'

	/// <summary>
	/// Content before the root element.
	/// </summary>
	ContentBeforeRoot = 0x43425254, // 'CBRT'

	/// <summary>
	/// Content after the root element.
	/// </summary>
	ContentAfterRoot = 0x43415254, // 'CART'

	/// <summary>
	/// Document has no root element.
	/// </summary>
	NoRootElement = 0x4E4F5254, // 'NORT'

	// ---- Encoding Errors ----

	/// <summary>
	/// Encoding is not supported.
	/// </summary>
	EncodingUnsupported = 0x454E5553, // 'ENUS'

	/// <summary>
	/// Invalid UTF-8 sequence.
	/// </summary>
	EncodingInvalidUtf8 = 0x454E5538, // 'ENU8'
}

extension XmlResult
{
	/// <summary>
	/// Returns true if the result indicates success.
	/// </summary>
	public bool IsOk => this == .Ok;

	/// <summary>
	/// Returns true if the result indicates an error.
	/// </summary>
	public bool IsError => this != .Ok;

	/// <summary>
	/// Gets a human-readable description of the result.
	/// </summary>
	public StringView Description
	{
		get
		{
			switch (this)
			{
			case .Ok: return "Operation completed successfully";
			case .SyntaxError: return "Syntax error";
			case .UnexpectedEndOfFile: return "Unexpected end of file";
			case .TagMismatch: return "Opening and closing tags do not match";
			case .TagInvalid: return "Tag name is invalid";
			case .TagUnclosed: return "Tag is not closed";
			case .TagUnexpectedClose: return "Unexpected closing tag";
			case .NameEmpty: return "No name found where one was expected";
			case .NameIllegalChar: return "Name contains an illegal character";
			case .NameReservedPrefix: return "Name starts with reserved prefix";
			case .AttributeDuplicate: return "Duplicate attribute in element";
			case .AttributeInvalid: return "Attribute name is invalid";
			case .AttributeValueInvalid: return "Attribute value is invalid";
			case .AttributeMissingEquals: return "Missing equals sign in attribute";
			case .AttributeMissingQuote: return "Missing quote in attribute value";
			case .EntityUnknown: return "Unknown entity reference";
			case .EntityMalformed: return "Entity reference is malformed";
			case .CharRefInvalid: return "Character reference is invalid";
			case .CharRefOutOfRange: return "Character reference value is out of range";
			case .CDataMalformed: return "CDATA section is malformed";
			case .CDataUnclosed: return "CDATA section is not closed";
			case .CommentMalformed: return "Comment is malformed";
			case .CommentUnclosed: return "Comment is not closed";
			case .CommentIllegalSequence: return "Comment contains illegal sequence (--)";
			case .PIInvalid: return "Processing instruction is invalid";
			case .PIUnclosed: return "Processing instruction is not closed";
			case .DeclarationInvalid: return "XML declaration is invalid";
			case .DeclarationPosition: return "XML declaration in wrong position";
			case .DeclarationVersion: return "Version attribute is missing or invalid";
			case .NamespaceUndeclared: return "Namespace prefix is undeclared";
			case .NamespaceInvalid: return "Namespace declaration is invalid";
			case .PrefixReserved: return "Prefix is reserved (xml, xmlns)";
			case .NamespaceDefaultUndeclare: return "Cannot undeclare default namespace";
			case .MultipleRoots: return "Document has multiple root elements";
			case .ContentBeforeRoot: return "Content before root element";
			case .ContentAfterRoot: return "Content after root element";
			case .NoRootElement: return "Document has no root element";
			case .EncodingUnsupported: return "Encoding is not supported";
			case .EncodingInvalidUtf8: return "Invalid UTF-8 sequence";
			}
		}
	}
}
