using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Xml;

namespace Sedulous.Xml.Serialization;

/// An XML backend for the format-agnostic serializer contract: the first text one.
///
/// Layout: every field is a child element whose TAG names the kind, so "i32", "f32",
/// "object", "array", "string", "blob". A keyed field carries a name attribute; an array's
/// elements are positional and carry none. Scalars and strings hold their value as element
/// text, and an array carries its count as an attribute.
///
/// It lives outside both Core, which cannot depend on Xml, and the Xml module, which stays
/// serialization agnostic.
class XmlSerializer : Serializer
{
	/// Where a read is up to inside one element: the element itself, and the next child
	/// not yet consumed.
	private struct ReadScope
	{
		public XmlElement Element;
		public XmlNode Cursor;
	}

	/// Owned in write mode. In read mode the caller owns the document and this stays null.
	private XmlDocument mOwnedDocument ~ delete _;
	private XmlDocument mDocument;

	private XmlElement mWriteCurrent;
	private List<XmlElement> mWriteStack = new .() ~ delete _;
	private List<ReadScope> mReadStack = new .() ~ delete _;

	/// The key named for the NEXT value, if there was one.
	///
	/// A copy rather than a borrowed pointer: it costs one allocation the first time and
	/// reuses the buffer after, and it cannot dangle if a caller keys with a string that
	/// goes out of scope before the value is written.
	private String mPendingKey = new .() ~ delete _;
	private bool mHasPendingKey;

	/// Write mode: builds a fresh document rooted at a single element.
	public this() : base(.Write)
	{
		mOwnedDocument = new XmlDocument();
		mDocument = mOwnedDocument;

		let root = mDocument.CreateElement("root");
		mDocument.AppendChild(root);
		mWriteCurrent = root;
	}

	/// Read mode over a document the CALLER owns and must keep alive.
	public this(XmlDocument source) : base(.Read)
	{
		mDocument = source;
		PushRead(source.RootElement);
	}

	/// The written document, without a declaration: this is a payload rather than a file.
	public void GetOutput(String output)
	{
		var settings = XmlWriteSettings.Default;
		settings.OmitDeclaration = true;
		GetOutput(output, settings);
	}

	public void GetOutput(String output, XmlWriteSettings settings)
	{
		mDocument.WriteTo(output, settings);
	}

	/// Typed tags and name attributes make the structure readable from the data, so a
	/// store on this backend needs no format-version field of its own.
	public override bool IsSelfDescribing => true;

	public override void Key(StringView name)
	{
		mPendingKey.Set(name);
		mHasPendingKey = true;
	}

	public override void BeginObject()
	{
		if (IsWriting)
		{
			let element = MakeElement("object");
			mWriteStack.Add(mWriteCurrent);
			mWriteCurrent = element;
			return;
		}

		let element = Locate();
		if (element == null)
		{
			Fail(.NotFound);
			return;
		}
		PushRead(element);
	}

	public override void EndObject()
	{
		if (IsWriting)
		{
			if (mWriteStack.IsEmpty)
			{
				Fail(.Internal);
				return;
			}
			mWriteCurrent = mWriteStack.PopBack();
			return;
		}

		// The outermost scope is the document root and is not ours to leave.
		if (mReadStack.Count <= 1)
		{
			Fail(.Internal);
			return;
		}
		mReadStack.PopBack();
	}

	public override void BeginArray(ref uint32 count)
	{
		if (IsWriting)
		{
			let element = MakeElement("array");
			element.SetAttribute("count", count.ToString(.. scope String()));
			mWriteStack.Add(mWriteCurrent);
			mWriteCurrent = element;
			return;
		}

		let element = Locate();
		if (element == null)
		{
			count = 0;
			Fail(.NotFound);
			return;
		}

		if (uint32.Parse(Trimmed(element.GetAttribute("count"), .. scope String())) case .Ok(let parsed))
			count = parsed;
		else
		{
			count = 0;
			Fail(.Internal);
		}
		PushRead(element);
	}

	public override void EndArray() => EndObject();

	public override void Scalar(void* value, ScalarKind kind)
	{
		if (IsWriting)
		{
			let element = MakeElement(ScalarTag(kind));
			element.SetTextContent(WriteScalar(value, kind, .. scope String()));
			return;
		}

		let element = Locate();
		if (element == null)
		{
			Fail(.NotFound);
			return;
		}

		if (!ReadScalar(value, kind, element.GetTextContent(.. scope String())))
			Fail(.Internal);
	}

	public override void Text(String value)
	{
		if (IsWriting)
		{
			MakeElement("string").SetTextContent(value);
			return;
		}

		let element = Locate();
		if (element == null)
		{
			Fail(.NotFound);
			return;
		}

		value.Clear();
		element.GetTextContent(value);
	}

	/// Hex rather than base64: a blob in a text document is usually being read by a person
	/// trying to work out what went wrong, and hex is the one they can decode by eye.
	public override void Blob(void* data, int size)
	{
		if (IsWriting)
		{
			MakeElement("blob").SetTextContent(EncodeHex((uint8*)data, size, .. scope String()));
			return;
		}

		let element = Locate();
		if (element == null)
		{
			Fail(.NotFound);
			return;
		}

		if (!DecodeHex(element.GetTextContent(.. scope String()), (uint8*)data, size))
			Fail(.Internal);
	}

	/// Unknown-section passthrough.
	///
	/// XML delimits itself, so the framed region brackets are the inherited no-ops and
	/// this works on element boundaries instead: reading captures the current scope's
	/// remaining element children as text, and writing parses that text back and adopts
	/// the elements. A payload whose type this build cannot instantiate survives a load
	/// and save unchanged.
	public override bool RawRemainder(List<uint8> blob)
	{
		if (IsWriting)
			return ReinjectRemainder(blob);
		return CaptureRemainder(blob);
	}

	private bool ReinjectRemainder(List<uint8> blob)
	{
		if (blob.IsEmpty)
			return true;

		// Wrapped in a synthetic root, because a fragment is not a document and the
		// parser rejects several top level elements.
		let wrapped = scope String();
		wrapped.Append("<__frame__>");
		wrapped.Append(StringView((char8*)blob.Ptr, blob.Count));
		wrapped.Append("</__frame__>");

		let scratch = scope XmlDocument();
		if (scratch.Parse(wrapped) != .Ok)
		{
			Fail(.Internal);
			return false;
		}

		// Reparented rather than copied: RemoveChild detaches without deleting and
		// AppendChild adopts, so ownership moves and the scratch document is left with
		// only what it still holds.
		let root = scratch.RootElement;
		var child = (root != null) ? root.FirstChild : null;
		while (child != null)
		{
			let next = child.NextSibling;
			if (child.NodeType == .Element)
			{
				root.RemoveChild(child);
				mWriteCurrent.AppendChild(child);
			}
			child = next;
		}
		return true;
	}

	private bool CaptureRemainder(List<uint8> blob)
	{
		if (mReadStack.IsEmpty)
			return false;

		let captured = scope String();
		var cursor = mReadStack.Back.Cursor;
		while (cursor != null)
		{
			if (cursor.NodeType == .Element)
				cursor.GetOuterXml(captured);
			cursor = cursor.NextSibling;
		}

		// Fully consumed: whatever was captured must not also be read as fields.
		mReadStack[mReadStack.Count - 1].Cursor = null;

		blob.Clear();
		if (!captured.IsEmpty)
		{
			let raw = blob.GrowUninitialized(captured.Length);
			Internal.MemCpy(raw, captured.Ptr, captured.Length);
		}
		return true;
	}

	// ---- write helpers ----

	private XmlElement MakeElement(StringView tag)
	{
		let element = mDocument.CreateElement(tag);
		if (mHasPendingKey)
		{
			element.SetAttribute("name", mPendingKey);
			mHasPendingKey = false;
		}
		mWriteCurrent.AppendChild(element);
		return element;
	}

	// ---- read helpers ----

	private void PushRead(XmlElement element)
	{
		mReadStack.Add(ReadScope()
			{
				Element = element,
				Cursor = (element != null) ? element.FirstChild : null
			});
	}

	/// Finds the element the next read takes its value from: by name when a key is
	/// pending, otherwise the next unconsumed element child.
	private XmlElement Locate()
	{
		if (mReadStack.IsEmpty)
		{
			mHasPendingKey = false;
			return null;
		}

		var scope_ = ref mReadStack[mReadStack.Count - 1];
		if (scope_.Element == null)
		{
			mHasPendingKey = false;
			return null;
		}

		if (mHasPendingKey)
		{
			mHasPendingKey = false;

			// Searched FORWARD from the cursor and consumed on a hit. Writes emit fields
			// in order so reads are in order too, and starting from the first child every
			// time would make an array of keyed objects read every element as a copy of
			// the first one. A miss leaves the cursor alone: the caller fails loudly and
			// the scope stays readable.
			for (var node = scope_.Cursor; node != null; node = node.NextSibling)
			{
				if (let element = node as XmlElement)
				{
					if (element.GetAttribute("name") == mPendingKey)
					{
						scope_.Cursor = node.NextSibling;
						return element;
					}
				}
			}
			return null;
		}

		// Positional: the next element child, whatever it is called.
		while ((scope_.Cursor != null) && (scope_.Cursor.NodeType != .Element))
			scope_.Cursor = scope_.Cursor.NextSibling;

		if (scope_.Cursor == null)
			return null;

		let element = (XmlElement)scope_.Cursor;
		scope_.Cursor = scope_.Cursor.NextSibling;
		return element;
	}

	// ---- scalars ----

	/// The tag names the kind, which is what makes the document readable without a schema.
	private static StringView ScalarTag(ScalarKind kind)
	{
		switch (kind)
		{
		case .Bool: return "bool";
		case .Int8: return "i8";
		case .UInt8: return "u8";
		case .Int16: return "i16";
		case .UInt16: return "u16";
		case .Int32: return "i32";
		case .UInt32: return "u32";
		case .Int64: return "i64";
		case .UInt64: return "u64";
		case .Float32: return "f32";
		case .Float64: return "f64";
		}
	}

	private static void WriteScalar(void* value, ScalarKind kind, String output)
	{
		switch (kind)
		{
		case .Bool: output.Append(*(bool*)value ? "true" : "false");
		case .Int8: (*(int8*)value).ToString(output);
		case .UInt8: (*(uint8*)value).ToString(output);
		case .Int16: (*(int16*)value).ToString(output);
		case .UInt16: (*(uint16*)value).ToString(output);
		case .Int32: (*(int32*)value).ToString(output);
		case .UInt32: (*(uint32*)value).ToString(output);
		case .Int64: (*(int64*)value).ToString(output);
		case .UInt64: (*(uint64*)value).ToString(output);
		// The default, which is the SHORTEST string that round-trips. Not a fixed digit
		// count: G9 would write 0.1 as 0.100000001, and this format is meant to be read
		// and edited by a person.
		//
		// It relies on the toolchain: Beef's Parse was lossy until August 2026, so an
		// older one reads back a near miss. The round-trip tests catch that, and a failure
		// there means the toolchain rather than this code.
		case .Float32: (*(float*)value).ToString(output);
		case .Float64: (*(double*)value).ToString(output);
		}
	}

	private static bool ReadScalar(void* value, ScalarKind kind, StringView rawText)
	{
		// Trimmed, because this format is meant to be edited by hand and a value someone
		// indented should still read. Anything past the number is still an error.
		let text = Trimmed(rawText, .. scope String());

		switch (kind)
		{
		case .Bool:
			if ((text == "true") || (text == "1"))
			{
				*(bool*)value = true;
				return true;
			}
			if ((text == "false") || (text == "0"))
			{
				*(bool*)value = false;
				return true;
			}
			return false;

		case .Int8, .Int16, .Int32, .Int64:
			if (int64.Parse(text) case .Ok(let parsed))
			{
				switch (kind)
				{
				case .Int8: *(int8*)value = (int8)parsed;
				case .Int16: *(int16*)value = (int16)parsed;
				case .Int32: *(int32*)value = (int32)parsed;
				default: *(int64*)value = parsed;
				}
				return true;
			}
			return false;

		case .UInt8, .UInt16, .UInt32, .UInt64:
			if (uint64.Parse(text) case .Ok(let parsed))
			{
				switch (kind)
				{
				case .UInt8: *(uint8*)value = (uint8)parsed;
				case .UInt16: *(uint16*)value = (uint16)parsed;
				case .UInt32: *(uint32*)value = (uint32)parsed;
				default: *(uint64*)value = parsed;
				}
				return true;
			}
			return false;

		case .Float32:
			if (float.Parse(text) case .Ok(let parsed))
			{
				*(float*)value = parsed;
				return true;
			}
			return false;

		case .Float64:
			if (double.Parse(text) case .Ok(let parsed))
			{
				*(double*)value = parsed;
				return true;
			}
			return false;
		}
	}

	private static void Trimmed(StringView text, String output)
	{
		output.Clear();
		output.Append(text);
		output.Trim();
	}

	// ---- hex ----

	private static void EncodeHex(uint8* data, int size, String output)
	{
		const String cDigits = "0123456789abcdef";
		for (int i < size)
		{
			output.Append(cDigits[data[i] >> 4]);
			output.Append(cDigits[data[i] & 0xF]);
		}
	}

	private static bool DecodeHex(StringView hex, uint8* data, int size)
	{
		// The length has to match exactly: a short blob would leave the tail of the
		// destination holding whatever was there before.
		if (hex.Length != size * 2)
			return false;

		for (int i < size)
		{
			let high = XmlLexer.HexDigitValue(hex[i * 2]);
			let low = XmlLexer.HexDigitValue(hex[i * 2 + 1]);
			if ((high < 0) || (low < 0))
				return false;
			data[i] = (uint8)((high << 4) | low);
		}
		return true;
	}
}
