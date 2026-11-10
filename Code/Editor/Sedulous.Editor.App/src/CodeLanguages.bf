using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

/// The code editors' languages by id, for the code pages. A language is a data file of
/// Data/Editor/Code, one for the editor and the GUI sandbox
/// alike (the user's choice, 2026-10-26), named by its id and read through the XML serialization the
/// first time a page asks for it (a shader's "hlsl", a sheet's "css"); so no list of languages
/// is written anywhere, and one added is a file. The editor's application owns one and hands it to
/// the pages with their services.
class CodeLanguages
{
	/// Where the languages are, under the data root: <id>.xml each.
	public const String cFolder = "Editor/Code/";

	private class Entry
	{
		public String Id = new .() ~ delete _;
		/// Null: not there, or did not read.
		public CodeLanguage Language ~ delete _;
	}

	private delegate bool(StringView path, String outText) mRead ~ delete _;
	private List<Entry> mEntries = new .() ~ DeleteContainerAndItems!(_);

	/// `read` (taken) gives a file's text by its path under the data root (false: it is not there).
	public this(delegate bool(StringView path, String outText) read)
	{
		mRead = read;
	}

	/// The language `id` names, read the first time it is asked for and kept (a miss too); null
	/// when it has no file or the file does not read (logged once). The list's: borrowed.
	public CodeLanguage Find(StringView id)
	{
		if (id.IsEmpty)
			return null;
		for (let entry in mEntries)
		{
			if (entry.Id == id)
				return entry.Language;
		}
		let entry = new Entry();
		entry.Id.Set(id);
		entry.Language = Read(id);
		mEntries.Add(entry);
		return entry.Language;
	}

	private CodeLanguage Read(StringView id)
	{
		let path = scope String()..AppendF("{}{}.xml", cFolder, id);
		let text = scope String();
		if ((mRead == null) || !mRead(path, text))
		{
			GlobalLog(.Warning, "Editor: no code language '{}' ({} is not there): its code shows uncoloured", id, path);
			return null;
		}
		let doc = scope XmlDocument();
		let language = new CodeLanguage();
		if (doc.Parse(text) == .Ok)
		{
			let reader = scope XmlSerializer(doc);
			language.Serialize(reader); // prepares it once read
			if (reader.IsOk && !language.Contexts.IsEmpty)
				return language;
		}
		delete language;
		GlobalLog(.Warning, "Editor: the code language {} does not read: its code shows uncoloured", path);
		return null;
	}
}
