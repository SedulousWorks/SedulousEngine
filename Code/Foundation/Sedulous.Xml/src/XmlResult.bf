using System;

namespace Sedulous.Xml;

/// The outcome of a parse or a lex.
///
/// Ok is success and every other value names one specific failure, coded as a FourCC so a
/// value seen in a log or a debugger reads as itself. Nothing here throws: every XML
/// operation answers with one of these.
enum XmlResult : uint32
{
	case Ok = 0;

	case SyntaxError = 0x53594E54; // 'SYNT'
	case UnexpectedEndOfFile = 0x554E4546; // 'UNEF'
	case TagMismatch = 0x54414D53; // 'TAMS'
	case TagInvalid = 0x54414956; // 'TAIV'
	case TagUnclosed = 0x5441554E; // 'TAUN'
	case TagUnexpectedClose = 0x54415543; // 'TAUC'
	case NameEmpty = 0x4E4D454D; // 'NMEM'
	case NameIllegalChar = 0x4E4D4943; // 'NMIC'
	case NameReservedPrefix = 0x4E4D5250; // 'NMRP'
	case AttributeDuplicate = 0x41544450; // 'ATDP'
	case AttributeInvalid = 0x41544956; // 'ATIV'
	case AttributeValueInvalid = 0x41565649; // 'AVVI'
	case AttributeMissingEquals = 0x41544D45; // 'ATME'
	case AttributeMissingQuote = 0x41544D51; // 'ATMQ'
	case EntityUnknown = 0x454E554B; // 'ENUK'
	case EntityMalformed = 0x454E4D46; // 'ENMF'
	case CharRefInvalid = 0x43524956; // 'CRIV'
	case CharRefOutOfRange = 0x43524F52; // 'CROR'
	case CDataMalformed = 0x43444D46; // 'CDMF'
	case CDataUnclosed = 0x4344554E; // 'CDUN'
	case CommentMalformed = 0x434D4D46; // 'CMMF'
	case CommentUnclosed = 0x434D554E; // 'CMUN'
	case CommentIllegalSequence = 0x434D4953; // 'CMIS'
	case PIInvalid = 0x50494956; // 'PIIV'
	case PIUnclosed = 0x5049554E; // 'PIUN'
	case DeclarationInvalid = 0x4443494E; // 'DCIN'
	case DeclarationPosition = 0x44435053; // 'DCPS'
	case DeclarationVersion = 0x44435652; // 'DCVR'
	case NamespaceUndeclared = 0x4E53554E; // 'NSUN'
	case NamespaceInvalid = 0x4E534956; // 'NSIV'
	case PrefixReserved = 0x50465253; // 'PFRS'
	case NamespaceDefaultUndeclare = 0x4E534455; // 'NSDU'
	case MultipleRoots = 0x4D554C54; // 'MULT'
	case ContentBeforeRoot = 0x43425254; // 'CBRT'
	case ContentAfterRoot = 0x43415254; // 'CART'
	case NoRootElement = 0x4E4F5254; // 'NORT'
	case EncodingUnsupported = 0x454E5553; // 'ENUS'
	case EncodingInvalidUtf8 = 0x454E5538; // 'ENU8'

	public bool IsOk => this == .Ok;
	public bool IsError => this != .Ok;

	/// A human readable description, for a message a person has to act on.
	public StringView Describe
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
