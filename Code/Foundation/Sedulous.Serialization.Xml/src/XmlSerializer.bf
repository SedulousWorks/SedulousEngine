using System;
using System.Collections;
using Sedulous.Serialization;
using Sedulous.Xml;

namespace Sedulous.Serialization.Xml;

/// <summary>
/// XML-based serializer implementation.
/// Provides read/write support for serializing objects to/from XML format.
/// </summary>
class XmlSerializer : Serializer
{
	// Write mode state
	protected XmlDocument mWriteDocument ~ delete _;
	protected XmlElement mCurrentWriteElement;
	protected List<XmlElement> mWriteElementStack = new .() ~ delete _;

	// Read mode state
	protected XmlDocument mReadDocument;
	protected XmlElement mCurrentElement;
	protected List<XmlElement> mElementStack = new .() ~ delete _;
	protected List<int32> mUnnamedCursorStack = new .() ~ delete _;

	protected this()
	{
	}

	/// <summary>
	/// Creates a new XML serializer in write mode.
	/// </summary>
	public static XmlSerializer CreateWriter()
	{
		let serializer = new XmlSerializer();
		serializer.mMode = .Write;
		serializer.mWriteDocument = new XmlDocument();
		let root = new XmlElement("root");
		serializer.mWriteDocument.AppendChild(root);
		serializer.mCurrentWriteElement = root;
		return serializer;
	}

	/// <summary>
	/// Creates a new XML serializer in read mode.
	/// </summary>
	/// <param name="document">The parsed XML document to read from.</param>
	public static XmlSerializer CreateReader(XmlDocument document)
	{
		let serializer = new XmlSerializer();
		serializer.mMode = .Read;
		serializer.mReadDocument = document;
		serializer.mCurrentElement = document.RootElement;
		serializer.mUnnamedCursorStack.Add(0); // Initial scope cursor
		return serializer;
	}

	/// <summary>
	/// Gets the serialized XML output.
	/// </summary>
	public void GetOutput(String output)
	{
		if (mWriteDocument != null)
		{
			var settings = XmlWriteSettings.Default;
			settings.OmitDeclaration = true;
			mWriteDocument.WriteTo(output, settings);
		}
	}

	/// <summary>
	/// Gets the serialized XML output with custom settings.
	/// </summary>
	public void GetOutput(String output, XmlWriteSettings settings)
	{
		if (mWriteDocument != null)
			mWriteDocument.WriteTo(output, settings);
	}

	// ---- Helper Methods ----

	private XmlElement FindChildByName(StringView name)
	{
		if (mCurrentElement == null)
			return null;

		for (let child in mCurrentElement.Children)
		{
			if (let elem = child as XmlElement)
			{
				if (elem.GetAttribute("name") == name)
					return elem;
			}
		}
		return null;
	}

	private XmlElement FindNextUnnamedChild(StringView tagName)
	{
		if (mCurrentElement == null)
			return null;

		int32 skipCount = mUnnamedCursorStack.Count > 0 ? mUnnamedCursorStack.Back : 0;
		int32 found = 0;
		for (let child in mCurrentElement.Children)
		{
			if (let elem = child as XmlElement)
			{
				if (elem.TagName == tagName && !elem.HasAttribute("name"))
				{
					if (found == skipCount)
						return elem;
					found++;
				}
			}
		}
		return null;
	}

	private void CreatePrimitiveElement(StringView tagName, StringView name, StringView value)
	{
		let element = new XmlElement(tagName);
		if (!name.IsEmpty)
			element.SetAttribute("name", name);
		element.SetTextContent(value);
		mCurrentWriteElement.AppendChild(element);
	}

	private SerializationResult ReadPrimitiveElement(StringView name, String output)
	{
		let element = FindChildByName(name);
		if (element == null)
			return .FieldNotFound;

		element.GetTextContent(output);
		return .Ok;
	}

	// ---- Primitive Types ----

	public override SerializationResult Bool(StringView name, ref bool value)
	{
		if (IsWriting)
		{
			CreatePrimitiveElement("bool", name, value ? "true" : "false");
			return .Ok;
		}
		else
		{
			let text = scope String();
			let result = ReadPrimitiveElement(name, text);
			if (result != .Ok)
				return result;

			if (text == "true" || text == "1")
				value = true;
			else if (text == "false" || text == "0")
				value = false;
			else
				return .TypeMismatch;

			return .Ok;
		}
	}

	public override SerializationResult Int8(StringView name, ref int8 value)
	{
		if (IsWriting)
		{
			let str = scope String();
			value.ToString(str);
			CreatePrimitiveElement("int8", name, str);
			return .Ok;
		}
		else
		{
			let text = scope String();
			let result = ReadPrimitiveElement(name, text);
			if (result != .Ok)
				return result;

			if (int8.Parse(text) case .Ok(let parsed))
			{
				value = parsed;
				return .Ok;
			}
			return .TypeMismatch;
		}
	}

	public override SerializationResult Int16(StringView name, ref int16 value)
	{
		if (IsWriting)
		{
			let str = scope String();
			value.ToString(str);
			CreatePrimitiveElement("int16", name, str);
			return .Ok;
		}
		else
		{
			let text = scope String();
			let result = ReadPrimitiveElement(name, text);
			if (result != .Ok)
				return result;

			if (int16.Parse(text) case .Ok(let parsed))
			{
				value = parsed;
				return .Ok;
			}
			return .TypeMismatch;
		}
	}

	public override SerializationResult Int32(StringView name, ref int32 value)
	{
		if (IsWriting)
		{
			let str = scope String();
			value.ToString(str);
			CreatePrimitiveElement("int32", name, str);
			return .Ok;
		}
		else
		{
			let text = scope String();
			let result = ReadPrimitiveElement(name, text);
			if (result != .Ok)
				return result;

			if (int32.Parse(text) case .Ok(let parsed))
			{
				value = parsed;
				return .Ok;
			}
			return .TypeMismatch;
		}
	}

	public override SerializationResult Int64(StringView name, ref int64 value)
	{
		if (IsWriting)
		{
			let str = scope String();
			value.ToString(str);
			CreatePrimitiveElement("int64", name, str);
			return .Ok;
		}
		else
		{
			let text = scope String();
			let result = ReadPrimitiveElement(name, text);
			if (result != .Ok)
				return result;

			if (int64.Parse(text) case .Ok(let parsed))
			{
				value = parsed;
				return .Ok;
			}
			return .TypeMismatch;
		}
	}

	public override SerializationResult UInt8(StringView name, ref uint8 value)
	{
		if (IsWriting)
		{
			let str = scope String();
			value.ToString(str);
			CreatePrimitiveElement("uint8", name, str);
			return .Ok;
		}
		else
		{
			let text = scope String();
			let result = ReadPrimitiveElement(name, text);
			if (result != .Ok)
				return result;

			if (uint8.Parse(text) case .Ok(let parsed))
			{
				value = parsed;
				return .Ok;
			}
			return .TypeMismatch;
		}
	}

	public override SerializationResult UInt16(StringView name, ref uint16 value)
	{
		if (IsWriting)
		{
			let str = scope String();
			value.ToString(str);
			CreatePrimitiveElement("uint16", name, str);
			return .Ok;
		}
		else
		{
			let text = scope String();
			let result = ReadPrimitiveElement(name, text);
			if (result != .Ok)
				return result;

			if (uint16.Parse(text) case .Ok(let parsed))
			{
				value = parsed;
				return .Ok;
			}
			return .TypeMismatch;
		}
	}

	public override SerializationResult UInt32(StringView name, ref uint32 value)
	{
		if (IsWriting)
		{
			let str = scope String();
			value.ToString(str);
			CreatePrimitiveElement("uint32", name, str);
			return .Ok;
		}
		else
		{
			let text = scope String();
			let result = ReadPrimitiveElement(name, text);
			if (result != .Ok)
				return result;

			if (uint32.Parse(text) case .Ok(let parsed))
			{
				value = parsed;
				return .Ok;
			}
			return .TypeMismatch;
		}
	}

	public override SerializationResult UInt64(StringView name, ref uint64 value)
	{
		if (IsWriting)
		{
			let str = scope String();
			value.ToString(str);
			CreatePrimitiveElement("uint64", name, str);
			return .Ok;
		}
		else
		{
			let text = scope String();
			let result = ReadPrimitiveElement(name, text);
			if (result != .Ok)
				return result;

			if (uint64.Parse(text) case .Ok(let parsed))
			{
				value = parsed;
				return .Ok;
			}
			return .TypeMismatch;
		}
	}

	public override SerializationResult Float(StringView name, ref float value)
	{
		if (IsWriting)
		{
			let str = scope String();
			value.ToString(str);
			CreatePrimitiveElement("float", name, str);
			return .Ok;
		}
		else
		{
			let text = scope String();
			let result = ReadPrimitiveElement(name, text);
			if (result != .Ok)
				return result;

			if (float.Parse(text) case .Ok(let parsed))
			{
				value = parsed;
				return .Ok;
			}
			return .TypeMismatch;
		}
	}

	public override SerializationResult Double(StringView name, ref double value)
	{
		if (IsWriting)
		{
			let str = scope String();
			value.ToString(str);
			CreatePrimitiveElement("double", name, str);
			return .Ok;
		}
		else
		{
			let text = scope String();
			let result = ReadPrimitiveElement(name, text);
			if (result != .Ok)
				return result;

			if (double.Parse(text) case .Ok(let parsed))
			{
				value = parsed;
				return .Ok;
			}
			return .TypeMismatch;
		}
	}

	public override SerializationResult String(StringView name, String value)
	{
		if (IsWriting)
		{
			CreatePrimitiveElement("string", name, value);
			return .Ok;
		}
		else
		{
			let element = FindChildByName(name);
			if (element == null)
				return .FieldNotFound;

			value.Clear();
			element.GetTextContent(value);
			return .Ok;
		}
	}

	// ---- Fixed Arrays ----

	public override SerializationResult FixedFloatArray(StringView name, float* data, int32 count)
	{
		if (IsWriting)
		{
			let element = new XmlElement("float-array");
			if (!name.IsEmpty)
				element.SetAttribute("name", name);

			let countStr = scope String();
			count.ToString(countStr);
			element.SetAttribute("count", countStr);

			let content = scope String();
			for (int32 i = 0; i < count; i++)
			{
				if (i > 0)
					content.Append(' ');
				data[i].ToString(content);
			}
			element.SetTextContent(content);
			mCurrentWriteElement.AppendChild(element);
			return .Ok;
		}
		else
		{
			let element = FindChildByName(name);
			if (element == null)
				return .FieldNotFound;

			let countAttr = element.GetAttribute("count");
			if (countAttr.IsEmpty)
				return .InvalidData;

			if (int32.Parse(countAttr) case .Ok(let parsedCount))
			{
				if (parsedCount != count)
					return .ArraySizeMismatch;
			}
			else
			{
				return .InvalidData;
			}

			let content = scope String();
			element.GetTextContent(content);

			int32 index = 0;
			for (let part in content.Split(' '))
			{
				if (index >= count)
					break;

				let partStr = scope String(part);
				partStr.Trim();
				if (partStr.IsEmpty)
					continue;

				if (float.Parse(partStr) case .Ok(let parsed))
				{
					data[index++] = parsed;
				}
				else
				{
					return .TypeMismatch;
				}
			}

			if (index != count)
				return .ArraySizeMismatch;

			return .Ok;
		}
	}

	public override SerializationResult FixedInt32Array(StringView name, int32* data, int32 count)
	{
		if (IsWriting)
		{
			let element = new XmlElement("int32-array");
			if (!name.IsEmpty)
				element.SetAttribute("name", name);

			let countStr = scope String();
			count.ToString(countStr);
			element.SetAttribute("count", countStr);

			let content = scope String();
			for (int32 i = 0; i < count; i++)
			{
				if (i > 0)
					content.Append(' ');
				data[i].ToString(content);
			}
			element.SetTextContent(content);
			mCurrentWriteElement.AppendChild(element);
			return .Ok;
		}
		else
		{
			let element = FindChildByName(name);
			if (element == null)
				return .FieldNotFound;

			let countAttr = element.GetAttribute("count");
			if (countAttr.IsEmpty)
				return .InvalidData;

			if (int32.Parse(countAttr) case .Ok(let parsedCount))
			{
				if (parsedCount != count)
					return .ArraySizeMismatch;
			}
			else
			{
				return .InvalidData;
			}

			let content = scope String();
			element.GetTextContent(content);

			int32 index = 0;
			for (let part in content.Split(' '))
			{
				if (index >= count)
					break;

				let partStr = scope String(part);
				partStr.Trim();
				if (partStr.IsEmpty)
					continue;

				if (int32.Parse(partStr) case .Ok(let parsed))
				{
					data[index++] = parsed;
				}
				else
				{
					return .TypeMismatch;
				}
			}

			if (index != count)
				return .ArraySizeMismatch;

			return .Ok;
		}
	}

	// ---- Dynamic Arrays ----

	public override SerializationResult ArrayInt32(StringView name, List<int32> values)
	{
		if (IsWriting)
		{
			let element = new XmlElement("int32-array");
			if (!name.IsEmpty)
				element.SetAttribute("name", name);

			let countStr = scope String();
			((int32)values.Count).ToString(countStr);
			element.SetAttribute("count", countStr);

			let content = scope String();
			for (int i = 0; i < values.Count; i++)
			{
				if (i > 0)
					content.Append(' ');
				values[i].ToString(content);
			}
			element.SetTextContent(content);
			mCurrentWriteElement.AppendChild(element);
			return .Ok;
		}
		else
		{
			let element = FindChildByName(name);
			if (element == null)
				return .FieldNotFound;

			let content = scope String();
			element.GetTextContent(content);

			values.Clear();
			for (let part in content.Split(' '))
			{
				let partStr = scope String(part);
				partStr.Trim();
				if (partStr.IsEmpty)
					continue;

				if (int32.Parse(partStr) case .Ok(let parsed))
				{
					values.Add(parsed);
				}
				else
				{
					return .TypeMismatch;
				}
			}

			return .Ok;
		}
	}

	public override SerializationResult ArrayFloat(StringView name, List<float> values)
	{
		if (IsWriting)
		{
			let element = new XmlElement("float-array");
			if (!name.IsEmpty)
				element.SetAttribute("name", name);

			let countStr = scope String();
			((int32)values.Count).ToString(countStr);
			element.SetAttribute("count", countStr);

			let content = scope String();
			for (int i = 0; i < values.Count; i++)
			{
				if (i > 0)
					content.Append(' ');
				values[i].ToString(content);
			}
			element.SetTextContent(content);
			mCurrentWriteElement.AppendChild(element);
			return .Ok;
		}
		else
		{
			let element = FindChildByName(name);
			if (element == null)
				return .FieldNotFound;

			let content = scope String();
			element.GetTextContent(content);

			values.Clear();
			for (let part in content.Split(' '))
			{
				let partStr = scope String(part);
				partStr.Trim();
				if (partStr.IsEmpty)
					continue;

				if (float.Parse(partStr) case .Ok(let parsed))
				{
					values.Add(parsed);
				}
				else
				{
					return .TypeMismatch;
				}
			}

			return .Ok;
		}
	}

	public override SerializationResult ArrayString(StringView name, List<String> values)
	{
		if (IsWriting)
		{
			let element = new XmlElement("string-array");
			if (!name.IsEmpty)
				element.SetAttribute("name", name);

			let countStr = scope String();
			((int32)values.Count).ToString(countStr);
			element.SetAttribute("count", countStr);

			for (let str in values)
			{
				let itemElement = new XmlElement("item");
				itemElement.SetTextContent(str);
				element.AppendChild(itemElement);
			}

			mCurrentWriteElement.AppendChild(element);
			return .Ok;
		}
		else
		{
			let element = FindChildByName(name);
			if (element == null)
				return .FieldNotFound;

			values.Clear();
			for (let child in element.Children)
			{
				if (let itemElem = child as XmlElement)
				{
					if (itemElem.TagName == "item")
					{
						let str = new String();
						itemElem.GetTextContent(str);
						values.Add(str);
					}
				}
			}

			return .Ok;
		}
	}

	// ---- Nested Objects ----

	public override SerializationResult BeginObject(StringView name, StringView typeName = default)
	{
		if (IsWriting)
		{
			let element = new XmlElement("object");
			if (!name.IsEmpty)
				element.SetAttribute("name", name);
			if (!typeName.IsEmpty)
				element.SetAttribute("type", typeName);

			mCurrentWriteElement.AppendChild(element);
			mWriteElementStack.Add(mCurrentWriteElement);
			mCurrentWriteElement = element;
			return .Ok;
		}
		else
		{
			XmlElement element;
			if (name.IsEmpty)
			{
				// Find next unnamed object and advance cursor
				element = FindNextUnnamedChild("object");
				if (mUnnamedCursorStack.Count > 0)
					mUnnamedCursorStack.Back++;
			}
			else
			{
				element = FindChildByName(name);
			}

			if (element == null)
				return .FieldNotFound;

			mElementStack.Add(mCurrentElement);
			mCurrentElement = element;
			mUnnamedCursorStack.Add(0); // Push new cursor for child scope
			return .Ok;
		}
	}

	public override SerializationResult EndObject()
	{
		if (IsWriting)
		{
			if (mWriteElementStack.Count == 0)
				return .InvalidData;

			mCurrentWriteElement = mWriteElementStack.PopBack();
			return .Ok;
		}
		else
		{
			if (mElementStack.Count == 0)
				return .InvalidData;

			mCurrentElement = mElementStack.PopBack();
			if (mUnnamedCursorStack.Count > 0)
				mUnnamedCursorStack.PopBack(); // Pop child scope cursor
			return .Ok;
		}
	}

	// ---- Collections ----

	public override SerializationResult BeginArray(StringView name, ref int32 count)
	{
		if (IsWriting)
		{
			let element = new XmlElement("array");
			if (!name.IsEmpty)
				element.SetAttribute("name", name);

			let countStr = scope String();
			count.ToString(countStr);
			element.SetAttribute("count", countStr);

			mCurrentWriteElement.AppendChild(element);
			mWriteElementStack.Add(mCurrentWriteElement);
			mCurrentWriteElement = element;
			return .Ok;
		}
		else
		{
			let element = FindChildByName(name);
			if (element == null)
				return .FieldNotFound;

			let countAttr = element.GetAttribute("count");
			if (countAttr.IsEmpty)
				return .InvalidData;

			if (int32.Parse(countAttr) case .Ok(let parsedCount))
			{
				count = parsedCount;
			}
			else
			{
				return .InvalidData;
			}

			mElementStack.Add(mCurrentElement);
			mCurrentElement = element;
			mUnnamedCursorStack.Add(0); // Push cursor for array scope
			return .Ok;
		}
	}

	public override SerializationResult EndArray()
	{
		return EndObject();
	}

	// ---- Utility ----

	public override bool HasField(StringView name)
	{
		if (IsWriting)
			return false;

		return FindChildByName(name) != null;
	}

	public override void GetFieldNames(List<String> outNames)
	{
		if (IsWriting || mCurrentElement == null)
			return;
		for (let child in mCurrentElement.Children)
		{
			if (let elem = child as XmlElement)
			{
				let name = elem.GetAttribute("name");
				if (name.Length > 0)
					outNames.Add(new String(name));
			}
		}
	}

	public override bool CaptureScope(String output, StringView excludeField = default)
	{
		if (!IsReading || mCurrentElement == null)
			return false;

		for (let child in mCurrentElement.Children)
		{
			if (let elem = child as XmlElement)
			{
				if (!excludeField.IsEmpty && elem.GetAttribute("name") == excludeField)
					continue;
				elem.GetOuterXml(output);
			}
		}
		return true;
	}

	public override bool RestoreScope(StringView data)
	{
		if (!IsWriting || data.IsEmpty)
			return false;

		// Wrap in a root element for parsing
		let wrappedXml = scope String();
		wrappedXml.Append("<root>");
		wrappedXml.Append(data);
		wrappedXml.Append("</root>");

		let doc = scope XmlDocument();
		if (doc.Parse(wrappedXml) != .Ok)
			return false;

		let root = doc.RootElement;
		if (root == null)
			return false;

		// Collect children first (iterating while modifying is unsafe)
		let children = scope List<XmlNode>();
		var child = root.FirstChild;
		while (child != null)
		{
			children.Add(child);
			child = child.NextSibling;
		}

		// Reparent parsed nodes into the current write scope
		for (let node in children)
		{
			node.RemoveFromParent();
			mCurrentWriteElement.AppendChild(node);
		}

		return true;
	}
}
