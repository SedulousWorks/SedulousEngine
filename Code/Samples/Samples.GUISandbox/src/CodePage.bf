using System;
using System.Collections;
using Sedulous.Script;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;
using Sedulous.GUI;

namespace Samples.GUISandbox;

/// The Code page (C8 of Raptor's gui-lab-evolution-3.md): GUI.Code's editor as a host uses it. A
/// script in the sandbox's own AngelScript, checked by the engine's compiler a moment after each
/// edit without running it (ScriptRuntime.Check), its errors the editor's diagnostics; a click in
/// the gutter sets a breakpoint; completion and hover from the surface the script backend bound
/// (DescribeBoundApi) and the language's words; and a shader beside it. The languages are the
/// editor's too (Data/Editor/Code), read through the XML serialization.
///
/// Outlives the page's editors (the host deletes it after the GUI), so it never reaches into them
/// as it goes: its change listener is the script document's, and goes with it.
class CodePage : ICodeLanguageService
{
	/// How long the script rests after an edit before it is checked, in seconds.
	public const float cCheckDelay = 0.3f;

	/// The section a check compiles the script as: its messages are told from the backend's own.
	private const String cChunk = "code.as";

	/// Borrowed: the host's runtime, which outlives the page (null: no backend).
	private ScriptRuntime mScripts = null;
	private List<ScriptApiType> mApi = new .() ~ DeleteContainerAndItems!(_);
	/// The editors borrow them: they go before the page does.
	private CodeLanguage mScriptLanguage = new .() ~ delete _;
	private CodeLanguage mShaderLanguage = new .() ~ delete _;
	/// Borrowed, both: the page's tree holds them.
	private CodeEditor mScript = null;
	private Sedulous.GUI.Label mStatus = null;
	private float mCheckIn = 0.0f;
	private uint32 mChecks = 0;
	private List<uint32> mBreakpoints = new .() ~ delete _;

	/// One error a check reported in the script.
	private struct Found
	{
		public int32 Line = 0;
		public int32 Column = 0;
		public StringView Message = default; // into the runtime's problem, deleted once read

		public this() { }
	}

	public this(ScriptRuntime scripts)
	{
		mScripts = scripts;
		if (mScripts != null)
			mScripts.DescribeBoundApi(mApi);
	}

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

	/// The script's editor, with its language's definition and text, and the label that says how
	/// its last check went (null: none). Checked at once, so the page opens with its diagnostics.
	public void AttachScript(CodeEditor editor, StringView languageXml, StringView source, Sedulous.GUI.Label status)
	{
		mScript = editor;
		mStatus = status;
		if (ReadLanguage(languageXml, mScriptLanguage))
			editor.SetLanguage(mScriptLanguage);
		editor.SetText(source);
		editor.LanguageService = this;
		editor.SetOnGutterClick(new (line) => { ToggleBreakpoint(line); });
		editor.Document.AddChangeListener(new (change) => { mCheckIn = cCheckDelay; });
		Check();
	}

	/// The shader's editor: highlighting, folding and its regions; no service.
	public void AttachShader(CodeEditor editor, StringView languageXml, StringView source)
	{
		if (ReadLanguage(languageXml, mShaderLanguage))
			editor.SetLanguage(mShaderLanguage);
		editor.SetText(source);
	}

	/// Counts down to the check an edit asked for.
	public void Update(float deltaTime)
	{
		if (mCheckIn <= 0.0f)
			return;
		mCheckIn -= deltaTime;
		if (mCheckIn <= 0.0f)
			Check();
	}

	/// Compiles the script as it stands, nothing of it run, and shows what the compiler said.
	public void Check()
	{
		mCheckIn = 0.0f;
		if (mScript == null)
			return;
		let diagnostics = scope List<CodeDiagnostic>();
		defer diagnostics.ClearAndDeleteItems();
		let said = scope String();
		// The runtime reports through its Problems, as text: the check's are those it adds, taken
		// back out once read, so the host's list does not grow with every keystroke.
		let first = (mScripts != null) ? mScripts.Problems.Count : 0;
		if (mScripts == null)
			said.Append("No script backend in this build: nothing checks the script");
		else
		{
			let source = scope String();
			mScript.GetText(source);
			let ok = mScripts.Check(cChunk, source);
			let errors = scope List<Found>();
			for (int i = first; i < mScripts.Problems.Count; i++)
			{
				if (ParseProblem(mScripts.Problems[i], let found))
					errors.Add(found);
			}
			for (let e in errors)
				diagnostics.Add(new CodeDiagnostic(RangeOf(e.Line, e.Column), .Error, e.Message));
			if (ok && errors.IsEmpty)
				said.Append("Compiles: no errors");
			else if (errors.Count == 1)
				said.AppendF("1 error: line {}: {}", errors[0].Line, errors[0].Message);
			else
				said.AppendF("{} errors, the first on line {}: {}", errors.Count, errors.IsEmpty ? 0 : errors[0].Line,
					errors.IsEmpty ? default(StringView) : errors[0].Message);
		}
		mScript.SetDiagnostics(diagnostics);
		if (mStatus != null)
			mStatus.Text = said;
		mChecks++;
		// The messages were viewed above (the diagnostics and the status copied them): they go only now.
		if ((mScripts != null) && (mScripts.Problems.Count > first))
		{
			for (int i = first; i < mScripts.Problems.Count; i++)
				delete mScripts.Problems[i];
			mScripts.Problems.RemoveRange(first, mScripts.Problems.Count - first);
		}
	}

	/// How many times the script has been checked, for a test.
	public uint32 CheckCount => mChecks;

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

	public StringView CompletionTriggers => ".:";

	public void Complete(CodeDocument document, CodeCompletionRequest request, List<CodeCompletionItem> @out)
	{
		let line = document.LineText(request.WordStart.Line);
		let start = request.WordStart.Column;
		// After `x.` or `x::`, the members of what x is; else the words a script may begin with.
		bool statics = false;
		let qualifier = QualifierBefore(line, start, ref statics);
		if (!qualifier.IsEmpty)
		{
			if (let type = Resolve(document, qualifier))
				AddMembers(type, statics, @out);
			return;
		}
		if ((start > 0) && (line[start - 1] == '.'))
			return; // a member of something we cannot name
		AddLanguageWords(@out);
		for (let type in mApi)
			@out.Add(Item(type.ScriptName, type.IsNamespace ? CodeCompletionKind.Module : CodeCompletionKind.Type, type.IsNamespace ? "namespace" : "type"));
		AddDocumentWords(document, request, @out);
	}

	public bool Hover(CodeDocument document, CodePosition at, String @out)
	{
		if (at.Line >= document.LineCount)
			return false;
		let line = document.LineText(at.Line);
		uint32 begin = Math.Min(at.Column, (uint32)line.Length);
		uint32 end = begin;
		while ((begin > 0) && IsWordByte(line[begin - 1]))
			--begin;
		while ((end < line.Length) && IsWordByte(line[end]))
			++end;
		if (begin == end)
			return false;
		let word = line.Substring(begin, end - begin);
		bool statics = false;
		let qualifier = QualifierBefore(line, begin, ref statics);
		if (!qualifier.IsEmpty)
		{
			let type = Resolve(document, qualifier);
			if (type == null)
				return false;
			int shown = 0;
			for (let member in type.Members)
			{
				if ((member.Name != word) || (shown >= 3))
					continue;
				if (shown++ > 0)
					@out.Append('\n');
				@out.AppendF("{}.{}", type.ScriptName, member.Signature.IsEmpty ? member.Name : member.Signature);
			}
			return shown > 0;
		}
		if (let type = FindType(word))
		{
			@out.AppendF("{} {} ({} members)", type.IsNamespace ? "namespace" : "type", type.ScriptName, type.Members.Count);
			return true;
		}
		return false;
	}

	// === Its parts ===

	/// One of the runtime's problems, `section(row,col): kind: message`, when it is an error in the
	/// script (the backend's own sections are not the page's).
	private static bool ParseProblem(StringView text, out Found found)
	{
		found = .();
		let open = text.IndexOf('(');
		if ((open < 0) || (text.Substring(0, open) != cChunk))
			return false;
		let close = text.IndexOf("): ", open);
		if (close < 0)
			return false;
		let place = text.Substring(open + 1, close - open - 1);
		let comma = place.IndexOf(',');
		if (comma < 0)
			return false;
		let rest = text.Substring(close + 3);
		let colon = rest.IndexOf(": ");
		if ((colon < 0) || (rest.Substring(0, colon) != "error"))
			return false;
		if (int32.Parse(place.Substring(0, comma)) case .Ok(let line))
			found.Line = line;
		if (int32.Parse(place.Substring(comma + 1)) case .Ok(let column))
			found.Column = column;
		found.Message = rest.Substring(colon + 2);
		return true;
	}

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

	/// What the compiler's (1-based) line and column point at: the word there, or one character;
	/// the line's text when no column is given.
	private CodeRange RangeOf(int32 line, int32 column)
	{
		let doc = mScript.Document;
		let l = (line > 0) ? Math.Min((uint32)(line - 1), doc.LineCount - 1) : 0;
		let text = doc.LineText(l);
		if (column <= 0)
		{
			uint32 first = 0;
			while ((first < text.Length) && ((text[first] == ' ') || (text[first] == '\t')))
				++first;
			return .(.(l, first), .(l, (uint32)text.Length));
		}
		let c = Math.Min((uint32)(column - 1), (uint32)text.Length);
		uint32 end = c;
		while ((end < text.Length) && IsWordByte(text[end]))
			++end;
		if ((end == c) && (end < text.Length))
			++end;
		return .(.(l, c), .(l, end));
	}

	/// The name before `x.` or `x::` ending at `start` (`statics` for `::`); empty when none.
	private static StringView QualifierBefore(StringView line, uint32 start, ref bool statics)
	{
		uint32 end = Math.Min(start, (uint32)line.Length);
		statics = false;
		if ((end >= 2) && (line[end - 1] == ':') && (line[end - 2] == ':'))
		{
			statics = true;
			end -= 2;
		}
		else if ((end >= 1) && (line[end - 1] == '.'))
			end -= 1;
		else
			return default;
		uint32 begin = end;
		while ((begin > 0) && IsWordByte(line[begin - 1]))
			--begin;
		return line.Substring(begin, end - begin);
	}

	private ScriptApiType FindType(StringView name)
	{
		for (let type in mApi)
		{
			if (type.ScriptName == name)
				return type;
		}
		return null;
	}

	/// A type or namespace by its name, or the type a variable of that name is declared with in the
	/// script (`Node@ card`, `Float3 at`), the last declaration found.
	private ScriptApiType Resolve(CodeDocument document, StringView name)
	{
		if (let type = FindType(name))
			return type;
		ScriptApiType found = null;
		for (uint32 l = 0; l < document.LineCount; l++)
		{
			let text = document.LineText(l);
			for (int at = 0; at + name.Length <= text.Length; at++)
			{
				if ((text.Substring(at, name.Length) != name) || ((at > 0) && IsWordByte(text[at - 1])) ||
					((at + name.Length < text.Length) && IsWordByte(text[at + name.Length])))
					continue;
				// Back over spaces, a handle or reference mark, and spaces, to the type's name.
				int p = at;
				while ((p > 0) && (text[p - 1] == ' '))
					--p;
				while ((p > 0) && ((text[p - 1] == '@') || (text[p - 1] == '&')))
					--p;
				while ((p > 0) && (text[p - 1] == ' '))
					--p;
				int q = p;
				while ((q > 0) && IsWordByte(text[q - 1]))
					--q;
				if ((q == p) || (p == at))
					continue;
				if (let type = FindType(text.Substring(q, p - q)))
					found = type;
			}
		}
		return found;
	}

	private static void AddMembers(ScriptApiType type, bool statics, List<CodeCompletionItem> @out)
	{
		for (let member in type.Members)
		{
			// Sedulous's API listing has no operator kind (Raptor's skipped them here): none to skip.
			if (!type.IsNamespace && (member.IsStatic != statics))
				continue;
			bool seen = false; // an overload shows once, with its first signature
			for (let item in @out)
				seen = seen || (item.Label == member.Name);
			if (seen)
				continue;
			CodeCompletionKind kind = .Method;
			if (member.Kind == .Property)
				kind = .Property;
			else if (member.Kind == .Constant)
				kind = .Constant;
			else if (type.IsNamespace || member.IsStatic)
				kind = .Function;
			@out.Add(Item(member.Name, kind, member.Signature));
		}
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
