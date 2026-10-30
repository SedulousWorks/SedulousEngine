using System;
using System.Collections;
using Sedulous.Script;
using Sedulous.GUI;

namespace Sedulous.Editor.Script;

/// A script page's completion and hover for its code editor (Raptor's editor-gui spec, 5.4, layer 6,
/// part 3), over the page's API surface (what the runtime binds for its language) and its language's
/// words. After `x.` or `x::` it offers the members of what x is (a type or namespace by name, or the
/// type a variable named x is declared with in the script); elsewhere the language's words, the bound
/// types and namespaces (an editor-only one marked) and the script's own names. Hover says what a
/// name is, or, while a Game run is paused in this script, its value (the page's probe). Adapted from
/// the GUISandbox's Code page, which proved it; that copy stays the sandbox's.
class ScriptLanguageService : ICodeLanguageService
{
	/// Borrowed: the page's, outliving this.
	private ScriptApiSurface mSurface;
	/// Borrowed (the page's languages keep it); null: no words.
	private CodeLanguage mLanguage;
	private delegate void(StringView name, String outText) mProbe ~ delete _;

	/// Over `surface` and the words of `language` (may be null).
	public this(ScriptApiSurface surface, CodeLanguage language)
	{
		mSurface = surface;
		mLanguage = language;
	}

	/// While a run is paused in the page's script, the value of a name appended (nothing: none); the
	/// page's. OWNERSHIP of `probe` transfers.
	public void SetValueProbe(delegate void(StringView name, String outText) probe)
	{
		delete mProbe;
		mProbe = probe;
	}

	public StringView CompletionTriggers => ".:";

	public void Complete(CodeDocument document, CodeCompletionRequest request, List<CodeCompletionItem> @out)
	{
		let line = document.LineText(request.WordStart.Line);
		let start = Math.Min(request.WordStart.Column, (uint32)line.Length);
		// After `x.`, `x:` or `x::`, the members of what x is: a type's (or a namespace's) statics
		// after its name, a value's own after a variable's; else the words a script may begin with.
		let qualifier = QualifierBefore(line, start);
		if (!qualifier.IsEmpty)
		{
			bool statics = false;
			if (let type = Resolve(document, qualifier, ref statics))
				AddMembers(type, statics, @out);
			return;
		}
		if ((start > 0) && (line[start - 1] == '.'))
			return; // a member of something we cannot name
		AddLanguageWords(@out);
		for (let type in mSurface.Types)
		{
			let editorOnly = mSurface.IsEditorOnly(type);
			StringView detail = type.IsNamespace ? (editorOnly ? "namespace [editor]" : "namespace") : (editorOnly ? "type [editor]" : "type");
			@out.Add(Item(type.ScriptName, type.IsNamespace ? CodeCompletionKind.Module : CodeCompletionKind.Type, detail));
		}
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
		// Paused in this script: what the name holds.
		if (mProbe != null)
		{
			let before = @out.Length;
			mProbe(word, @out);
			if (@out.Length > before)
				return true;
		}
		let qualifier = QualifierBefore(line, begin);
		if (!qualifier.IsEmpty)
		{
			bool statics = false;
			let type = Resolve(document, qualifier, ref statics);
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
		if (let type = mSurface.FindType(word))
		{
			@out.AppendF("{} {} ({} members){}", type.IsNamespace ? "namespace" : "type", type.ScriptName, type.Members.Count,
				mSurface.IsEditorOnly(type) ? ", the editor's alone: not in a built game" : "");
			return true;
		}
		return false;
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

	/// The name before `x.`, `x:` or `x::` ending at `start`; empty when none.
	private static StringView QualifierBefore(StringView line, uint32 start)
	{
		uint32 end = Math.Min(start, (uint32)line.Length);
		if ((end >= 2) && (line[end - 1] == ':') && (line[end - 2] == ':'))
			end -= 2;
		else if ((end >= 1) && ((line[end - 1] == '.') || (line[end - 1] == ':')))
			end -= 1;
		else
			return default;
		uint32 begin = end;
		while ((begin > 0) && IsWordByte(line[begin - 1]))
			--begin;
		return line.Substring(begin, end - begin);
	}

	/// A type or namespace by its name (`statics`), or the type a variable of that name is declared
	/// with in the script (`Node@ card`, `Float3 at`), the last declaration found.
	private ScriptApiType Resolve(CodeDocument document, StringView name, ref bool statics)
	{
		statics = false;
		if (let type = mSurface.FindType(name))
		{
			statics = true;
			return type;
		}
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
				if (let type = mSurface.FindType(text.Substring(q, p - q)))
					found = type;
			}
		}
		return found;
	}

	private static void AddMembers(ScriptApiType type, bool statics, List<CodeCompletionItem> @out)
	{
		for (let member in type.Members)
		{
			// Sedulous's API listing has no operator kind (Raptor's skips them here): none to skip.
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
		if (mLanguage == null)
			return;
		for (let words in mLanguage.Words)
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
