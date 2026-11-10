using System;
using System.Collections;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;
using Sedulous.GUI;

namespace Samples.GUISandbox;

/// The Code page: GUI.Code's editor as a host uses it. A script's text in its language's
/// highlighting, a click in the gutter setting a breakpoint, completion from the language's words
/// and the document's own; and a shader beside it. The languages are the editor's too
/// (Data/Editor/Code), read through the XML serialization.
///
/// Outlives the page's editors (the host deletes it after the GUI), so it never reaches into them
/// as it goes.
class CodePage : ICodeLanguageService
{
	/// The editors borrow them: they go before the page does.
	private CodeLanguage mScriptLanguage = new .() ~ delete _;
	private CodeLanguage mShaderLanguage = new .() ~ delete _;
	/// Borrowed: the page's tree holds it.
	private CodeEditor mScript = null;
	private List<uint32> mBreakpoints = new .() ~ delete _;

	/// Reads a language definition (the XML of one of Data/Editor/Code's files) into
	/// `outLanguage`, prepared.
	public bool ReadLanguage(StringView text, CodeLanguage outLanguage)
	{
		let doc = scope XmlDocument();
		if (doc.Parse(text) != .Ok)
			return false;
		let reader = scope XmlSerializer(doc);
		outLanguage.Serialize(reader); // prepares it once read
		return reader.IsOk && !outLanguage.Contexts.IsEmpty;
	}

	/// The script's editor, with its language's definition and text.
	public void AttachScript(CodeEditor editor, StringView languageXml, StringView source)
	{
		mScript = editor;
		if (ReadLanguage(languageXml, mScriptLanguage))
			editor.SetLanguage(mScriptLanguage);
		editor.SetText(source);
		editor.LanguageService = this;
		editor.SetOnGutterClick(new (line) => { ToggleBreakpoint(line); });
	}

	/// The shader's editor: highlighting, folding and its regions; no service.
	public void AttachShader(CodeEditor editor, StringView languageXml, StringView source)
	{
		if (ReadLanguage(languageXml, mShaderLanguage))
			editor.SetLanguage(mShaderLanguage);
		editor.SetText(source);
	}

	/// Sets a breakpoint on `line`, or takes away the one there.
	public void ToggleBreakpoint(uint32 line)
	{
		if (mScript == null)
			return;
		for (int i < mBreakpoints.Count)
		{
			if (mScript.MarkerLine(mBreakpoints[i]) == line)
			{
				mScript.RemoveMarker(mBreakpoints[i]);
				mBreakpoints.RemoveAt(i);
				return;
			}
		}
		mBreakpoints.Add(mScript.AddMarker(line, "breakpoint"));
	}

	// === ICodeLanguageService ===

	/// None: completion opens on Ctrl+Space alone.
	public StringView CompletionTriggers => default;

	public void Complete(CodeDocument document, CodeCompletionRequest request, List<CodeCompletionItem> @out)
	{
		let line = document.LineText(request.WordStart.Line);
		let start = request.WordStart.Column;
		if ((start > 0) && (line[start - 1] == '.'))
			return; // a member of something the page cannot name
		AddLanguageWords(@out);
		AddDocumentWords(document, request, @out);
	}

	/// Nothing: the page knows no declarations.
	public bool Hover(CodeDocument document, CodePosition at, String @out) => false;

	// === Its parts ===

	private static bool IsWordByte(char8 c)
	{
		return ((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) || ((c >= '0') && (c <= '9')) || (c == '_') || ((uint8)c >= 0x80);
	}

	private static CodeCompletionItem Item(StringView label, CodeCompletionKind kind, StringView detail = default)
	{
		let item = new CodeCompletionItem();
		item.Label.Set(label);
		item.Kind = kind;
		item.Detail.Set(detail);
		return item;
	}

	private void AddLanguageWords(List<CodeCompletionItem> @out)
	{
		for (let words in mScriptLanguage.Words)
		{
			CodeCompletionKind kind = .Keyword;
			if (words.Token == .Type)
				kind = .Type;
			else if (words.Token == .Constant)
				kind = .Constant;
			StringView list = words.List;
			int begin = 0;
			for (int i = 0; i <= list.Length; i++)
			{
				if ((i == list.Length) || (list[i] == ' '))
				{
					if (i > begin)
						@out.Add(Item(list.Substring(begin, i - begin), kind));
					begin = i + 1;
				}
			}
		}
	}

	/// The script's own names (its functions, variables), as an editor offers the words of the file:
	/// each once, not the word being typed, not what the list holds already.
	private static void AddDocumentWords(CodeDocument document, CodeCompletionRequest request, List<CodeCompletionItem> @out)
	{
		for (uint32 l = 0; l < document.LineCount; l++)
		{
			let text = document.LineText(l);
			int at = 0;
			while (at < text.Length)
			{
				if (!IsWordByte(text[at]))
				{
					++at;
					continue;
				}
				int end = at;
				while ((end < text.Length) && IsWordByte(text[end]))
					++end;
				let typing = (l == request.WordStart.Line) && (at == request.WordStart.Column);
				if ((end - at >= 3) && !typing && !((text[at] >= '0') && (text[at] <= '9')))
				{
					let word = text.Substring(at, end - at);
					bool seen = false;
					for (let item in @out)
						seen = seen || (item.Label == word);
					if (!seen)
						@out.Add(Item(word, .Text));
				}
				at = end;
			}
		}
	}
}
