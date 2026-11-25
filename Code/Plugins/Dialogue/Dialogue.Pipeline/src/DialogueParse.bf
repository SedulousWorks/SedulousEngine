using System;
using System.Collections;
using Sedulous.Core;

namespace Dialogue;

/// What an argument of a form takes.
enum DialogueArgumentKind : uint8
{
	/// Any words.
	case Text;
	/// One word.
	case Word;
	/// A number.
	case Number;
	/// One of the form's `Choices`.
	case OneOf;
	/// A level entity, by name (any words).
	case Entity;
	/// A cast id (one word).
	case Speaker;
	/// A flag (one word).
	case Flag;
	/// A dialogue asset of `AssetType`, by its name in the project's dialogue assets (one word).
	case Asset;
	/// One of the named list `ListName` (any words).
	case List;
}

/// One part of a form: a literal word or an argument, either in an optional group (a run of parts
/// with the same `Group`, 0 for none).
class DialogueFormPart
{
	public bool Literal = false;
	/// A literal's.
	public String Word = new .() ~ delete _;
	/// An argument's.
	public String Name = new .() ~ delete _;
	public DialogueArgumentKind Kind = .Text;
	/// OneOf.
	public List<String> Choices = new .() ~ DeleteContainerAndItems!(_);
	/// Asset.
	public String AssetType = new .() ~ delete _;
	/// List: the named list's name.
	public String ListName = new .() ~ delete _;
	public bool HasDefault = false;
	public String DefaultValue = new .() ~ delete _;
	public uint32 Group = 0;
}

/// How a command waits.
enum DialogueCommandWait : uint8
{
	/// Goes on at once, unless written `and wait` where the form allows it.
	case Never;
	/// `waits`: holds until the game says it is done.
	case Always;
	/// `leaves`: ends the conversation with its place saved, to be resumed.
	case Leaves;
}

/// A declared command's form, parsed.
class DialogueCommandForm
{
	/// As written.
	public String Text = new .() ~ delete _;
	/// Its leading literal words ("give coins").
	public String Name = new .() ~ delete _;
	public List<DialogueFormPart> Parts = new .() ~ DeleteContainerAndItems!(_);
	public DialogueCommandWait Wait = .Never;
	/// The optional group that is `[and wait]`; 0 when the form has none.
	public uint32 WaitGroup = 0;
	public uint32 GroupCount = 0;

	/// Back to an empty form, for a parse into one already used.
	public void Clear()
	{
		Text.Clear();
		Name.Clear();
		ClearAndDeleteItems!(Parts);
		Wait = .Never;
		WaitGroup = 0;
		GroupCount = 0;
	}
}

/// One problem the parser or the cook found, at its line of the source (1 for the first).
class DialogueProblem
{
	public uint32 Line = 0;
	public bool Warning = false;
	public String Message = new .() ~ delete _;

	public this(uint32 line, StringView message, bool warning = false)
	{
		Line = line;
		Message.Set(message);
		Warning = warning;
	}
}

/// A dialogue file, parsed.
class DialogueParse
{
	public List<DialogueConversation> Conversations = new .() ~ DeleteContainerAndItems!(_);
	public List<DialogueLineText> Lines = new .() ~ DeleteContainerAndItems!(_);
	/// By line.
	public List<DialogueProblem> Problems = new .() ~ DeleteContainerAndItems!(_);

	/// Sorts the problems by line, keeping the order of those on one line.
	public void SortProblems()
	{
		for (int i = 1; i < Problems.Count; i++)
		{
			for (int j = i; (j > 0) && (Problems[j - 1].Line > Problems[j].Line); j--)
				Swap!(Problems[j], Problems[j - 1]);
		}
	}

	/// No errors (warnings may remain).
	public bool Ok
	{
		get
		{
			for (let problem in Problems)
			{
				if (!problem.Warning)
					return false;
			}
			return true;
		}
	}
}

/// The dialogue format's parser and the command forms' notation.
static class DialogueFormat
{
	static String[?] cBuiltIn = .("conversation", "choice", "end", "if", "else", "set", "clear", "wait", "play",
		"sound", "fade", "sequence", "jump");

	/// The words a statement starts with that the format keeps for itself.
	public static bool IsBuiltInStatement(StringView word)
	{
		for (let builtIn in cBuiltIn)
		{
			if (builtIn == word)
				return true;
		}
		return false;
	}

	/// Parses a command's form into `outForm`. False, with `error` saying why, for a form that is not
	/// one: an unclosed bracket, a nested group, an unknown kind, a name that starts with a statement
	/// the format has already.
	public static bool ParseCommandForm(StringView text, DialogueCommandForm outForm, String error) =>
		ParseForm(text, outForm, error, false);

	/// Parses a dialogue file's text into `outParse`, matching what is not a built-in statement
	/// against `commands`. Its problems are sorted by line, keeping the order of those on one line.
	public static void ParseDialogue(StringView text, Span<DialogueCommandForm> commands, DialogueParse outParse)
	{
		let parser = scope Parser(text, commands, outParse);
		parser.Run();
		outParse.SortProblems();
	}

	// ---- characters and words ----------------------------------------------------------------

	static bool IsWordChar(char8 c) =>
		((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) || ((c >= '0') && (c <= '9')) || (c == '_');

	static bool IsWord(StringView text)
	{
		if (text.IsEmpty)
			return false;
		for (let c in text)
		{
			if (!IsWordChar(c))
				return false;
		}
		return true;
	}

	static bool IsSpace(char8 c) => (c == ' ') || (c == '\t') || (c == '\r');

	static StringView Trim(StringView text)
	{
		int start = 0;
		int end = text.Length;
		while ((start < end) && (IsSpace(text[start]) || (text[start] == '\n')))
			start++;
		while ((end > start) && (IsSpace(text[end - 1]) || (text[end - 1] == '\n')))
			end--;
		return text.Substring(start, end - start);
	}

	/// A base-10 number: none unless the whole trimmed text is one.
	static bool ParseNumber(StringView text, out float number)
	{
		number = 0.0f;
		let trimmed = Trim(text);
		if (trimmed.IsEmpty)
			return false;
		if (double.Parse(trimmed) case .Ok(let value))
		{
			number = (float)value;
			return true;
		}
		return false;
	}

	// ---- the forms' notation -------------------------------------------------------------------

	/// A form's tokens: `[`, `]`, an argument `<...>` whole, and words. Views into `text`.
	static void FormTokens(StringView text, List<StringView> tokens)
	{
		int i = 0;
		while (i < text.Length)
		{
			let c = text[i];
			if (IsSpace(c))
			{
				i++;
			}
			else if ((c == '[') || (c == ']'))
			{
				tokens.Add(text.Substring(i, 1));
				i++;
			}
			else if (c == '<')
			{
				let close = text.IndexOf('>', i);
				let end = (close < 0) ? text.Length : close + 1;
				tokens.Add(text.Substring(i, end - i));
				i = end;
			}
			else
			{
				var end = i;
				while ((end < text.Length) && !IsSpace(text[end]) && (text[end] != '[') && (text[end] != ']') && (text[end] != '<'))
					end++;
				tokens.Add(text.Substring(i, end - i));
				i = end;
			}
		}
	}

	/// Between the parentheses of `asset(...)` or `list(...)`; empty when `text` is not `prefix(...)`.
	static StringView Parenthesized(StringView text, StringView prefix)
	{
		if (!text.StartsWith(prefix) || !text.EndsWith(")") || (text.Length < prefix.Length + 2))
			return "";
		return text.Substring(prefix.Length + 1, text.Length - prefix.Length - 2);
	}

	static bool ParseArgument(StringView token, DialogueFormPart part, String error)
	{
		if (!token.EndsWith(">"))
		{
			error.Set(scope $"`{token}` is not closed by `>`");
			return false;
		}
		let inner = token.Substring(1, token.Length - 2);
		let colon = inner.IndexOf(':');
		if (colon < 0)
		{
			error.Set(scope $"`{token}`: an argument is `<name:kind>`");
			return false;
		}
		let name = inner.Substring(0, colon);
		if (!IsWord(name))
		{
			error.Set(scope $"`{token}`: an argument's name is one word");
			return false;
		}
		part.Literal = false;
		part.Name.Set(name);
		var kind = inner.Substring(colon + 1);
		let equals = kind.IndexOf('=');
		if (equals >= 0)
		{
			part.HasDefault = true;
			part.DefaultValue.Set(kind.Substring(equals + 1));
			kind = kind.Substring(0, equals);
		}
		let assetType = Parenthesized(kind, "asset");
		let listName = Parenthesized(kind, "list");
		if (kind == "text")
			part.Kind = .Text;
		else if (kind == "word")
			part.Kind = .Word;
		else if (kind == "number")
			part.Kind = .Number;
		else if (kind == "entity")
			part.Kind = .Entity;
		else if (kind == "speaker")
			part.Kind = .Speaker;
		else if (kind == "flag")
			part.Kind = .Flag;
		else if (!assetType.IsEmpty)
		{
			part.Kind = .Asset;
			part.AssetType.Set(assetType);
		}
		else if (!listName.IsEmpty)
		{
			part.Kind = .List;
			part.ListName.Set(listName);
		}
		else if (kind.Contains('|'))
		{
			part.Kind = .OneOf;
			int start = 0;
			while (start <= kind.Length)
			{
				var bar = kind.IndexOf('|', start);
				if (bar < 0)
					bar = kind.Length;
				let choice = kind.Substring(start, bar - start);
				if (!IsWord(choice))
				{
					error.Set(scope $"`{token}`: each choice is one word");
					return false;
				}
				part.Choices.Add(new .(choice));
				start = bar + 1;
			}
		}
		else
		{
			error.Set(scope $"`{token}`: no kind `{kind}` (text, word, number, a|b, entity, speaker, flag, asset(Type), list(name))");
			return false;
		}
		if (part.HasDefault && (part.Kind == .Number) && !ParseNumber(part.DefaultValue, var unused))
		{
			error.Set(scope $"`{token}`: the default is not a number");
			return false;
		}
		return true;
	}

	/// A form, built in or declared; a declared one may not take a built-in statement's name.
	static bool ParseForm(StringView text, DialogueCommandForm outForm, String error, bool builtIn)
	{
		outForm.Clear();
		outForm.Text.Set(Trim(text));
		let tokens = scope List<StringView>();
		FormTokens(text, tokens);
		if (tokens.IsEmpty)
		{
			error.Set("a form is empty");
			return false;
		}
		if ((tokens.Count > 1) && ((tokens.Back == "waits") || (tokens.Back == "leaves")))
		{
			outForm.Wait = (tokens.Back == "waits") ? .Always : .Leaves;
			tokens.PopBack();
		}
		uint32 group = 0;
		for (let token in tokens)
		{
			if (token == "[")
			{
				if (group != 0)
				{
					error.Set("an optional part holds no other");
					return false;
				}
				group = ++outForm.GroupCount;
			}
			else if (token == "]")
			{
				if (group == 0)
				{
					error.Set("a `]` closes nothing");
					return false;
				}
				if (outForm.Parts.IsEmpty || (outForm.Parts.Back.Group != group))
				{
					error.Set("an optional part is empty");
					return false;
				}
				group = 0;
			}
			else if (token.StartsWith("<"))
			{
				let part = new DialogueFormPart();
				if (!ParseArgument(token, part, error))
				{
					delete part;
					return false;
				}
				part.Group = group;
				if (part.HasDefault && (group == 0))
				{
					error.Set(scope $"`{token}`: only an optional part's argument has a default");
					delete part;
					return false;
				}
				for (let other in outForm.Parts)
				{
					if (!other.Literal && (other.Name == part.Name))
					{
						error.Set(scope $"two arguments are named `{part.Name}`");
						delete part;
						return false;
					}
				}
				outForm.Parts.Add(part);
			}
			else
			{
				let part = new DialogueFormPart();
				part.Literal = true;
				part.Word.Set(token);
				part.Group = group;
				outForm.Parts.Add(part);
			}
		}
		if (group != 0)
		{
			error.Set("a `[` is not closed");
			return false;
		}
		for (let part in outForm.Parts)
		{
			if (!part.Literal || (part.Group != 0))
				break;
			if (!outForm.Name.IsEmpty)
				outForm.Name.Append(' ');
			outForm.Name.Append(part.Word);
		}
		if (outForm.Name.IsEmpty)
		{
			error.Set("a form starts with its name, a word");
			return false;
		}
		StringView first = outForm.Parts[0].Word;
		if (!builtIn && (IsBuiltInStatement(first) || first.StartsWith("@") || first.StartsWith(">") || first.StartsWith("#")))
		{
			error.Set(scope $"`{first}` starts a statement of the format's own");
			return false;
		}
		for (uint32 g = 1; g <= outForm.GroupCount; g++)
		{
			DialogueFormPart firstInGroup = null;
			DialogueFormPart secondInGroup = null;
			int inGroup = 0;
			for (let part in outForm.Parts)
			{
				if (part.Group != g)
					continue;
				if (inGroup == 0)
					firstInGroup = part;
				else if (inGroup == 1)
					secondInGroup = part;
				inGroup++;
			}
			if ((inGroup == 2) && firstInGroup.Literal && secondInGroup.Literal && (firstInGroup.Word == "and") && (secondInGroup.Word == "wait"))
				outForm.WaitGroup = g;
		}
		if ((outForm.WaitGroup != 0) && (outForm.Wait != .Never))
		{
			error.Set("a command that always waits or leaves takes no `[and wait]`");
			return false;
		}
		return true;
	}

	// ---- matching a statement to a form --------------------------------------------------------

	/// A statement's word, a view into its line; a "quoted name" is one word, without its quotes.
	struct Word
	{
		public StringView Text;
		public bool Quoted;

		public this(StringView text, bool quoted)
		{
			Text = text;
			Quoted = quoted;
		}
	}

	/// A statement's words. False for an unclosed quote.
	static bool StatementWords(StringView text, List<Word> outWords)
	{
		int i = 0;
		while (i < text.Length)
		{
			if (IsSpace(text[i]))
			{
				i++;
				continue;
			}
			if (text[i] == '"')
			{
				let close = text.IndexOf('"', i + 1);
				if (close < 0)
					return false;
				outWords.Add(.(text.Substring(i + 1, close - i - 1), true));
				i = close + 1;
				continue;
			}
			var end = i;
			while ((end < text.Length) && !IsSpace(text[end]))
				end++;
			outWords.Add(.(text.Substring(i, end - i), false));
			i = end;
		}
		return true;
	}

	static bool SingleWord(DialogueArgumentKind kind) =>
		(kind == .Word) || (kind == .Number) || (kind == .OneOf) || (kind == .Speaker) || (kind == .Flag) || (kind == .Asset);

	/// What a match has taken: per argument part, in order, its text, number and whether it was
	/// written; per optional group (index = group), whether it was taken.
	class MatchState
	{
		public List<String> Texts = new .() ~ DeleteContainerAndItems!(_);
		public List<float> Numbers = new .() ~ delete _;
		public List<bool> Present = new .() ~ delete _;
		public List<bool> Taken = new .() ~ delete _;
	}

	/// Matches a statement's words against a form: an argument takes the fewest words that let the
	/// rest match, so it runs to the next literal word; an optional part is taken when it can be.
	/// Every step that fails leaves the state as it found it, so a failed branch undoes only what it
	/// wrote.
	class FormMatcher
	{
		DialogueCommandForm mForm;
		List<Word> mWords;
		/// Per part: its argument's index, -1 for a literal.
		List<int32> mSlot = new .() ~ delete _;
		int32 mArgumentCount = 0;

		public this(DialogueCommandForm form, List<Word> words)
		{
			mForm = form;
			mWords = words;
			for (let part in form.Parts)
				mSlot.Add(part.Literal ? -1 : mArgumentCount++);
		}

		public bool Run(MatchState state)
		{
			ClearAndDeleteItems!(state.Texts);
			state.Numbers.Clear();
			state.Present.Clear();
			state.Taken.Clear();
			for (int32 i < mArgumentCount)
			{
				state.Texts.Add(new .());
				state.Numbers.Add(0.0f);
				state.Present.Add(false);
			}
			for (uint32 g = 0; g <= mForm.GroupCount; g++)
				state.Taken.Add(false);
			return MatchFrom(1, 1, state); // the first word, the name's first, matched already
		}

		bool MatchFrom(int part, int at, MatchState state)
		{
			let parts = mForm.Parts;
			if (part == parts.Count)
				return at == mWords.Count;
			let here = parts[part];
			if ((here.Group != 0) && (parts[part - 1].Group != here.Group))
			{
				state.Taken[here.Group] = true;
				if (MatchPart(part, at, state))
					return true;
				state.Taken[here.Group] = false;
				var after = part;
				while ((after < parts.Count) && (parts[after].Group == here.Group))
					after++;
				return MatchFrom(after, at, state);
			}
			return MatchPart(part, at, state);
		}

		bool MatchPart(int part, int at, MatchState state)
		{
			let here = mForm.Parts[part];
			if (at >= mWords.Count)
				return false;
			if (here.Literal)
				return !mWords[at].Quoted && (mWords[at].Text == here.Word) && MatchFrom(part + 1, at + 1, state);
			int most = 1;
			if (!SingleWord(here.Kind) && !mWords[at].Quoted)
			{
				while ((at + most < mWords.Count) && !mWords[at + most].Quoted)
					most++;
			}
			let slot = mSlot[part];
			let text = scope String();
			for (int count = 1; count <= most; count++)
			{
				text.Clear();
				for (int w = at; w < at + count; w++)
				{
					if (w > at)
						text.Append(' ');
					text.Append(mWords[w].Text);
				}
				float number = 0.0f;
				if (!Accepts(here, text, ref number))
					continue;
				state.Texts[slot].Set(text);
				state.Numbers[slot] = number;
				state.Present[slot] = true;
				if (MatchFrom(part + 1, at + count, state))
					return true;
				state.Texts[slot].Clear();
				state.Numbers[slot] = 0.0f;
				state.Present[slot] = false;
			}
			return false;
		}

		static bool Accepts(DialogueFormPart part, StringView text, ref float number)
		{
			switch (part.Kind)
			{
			case .Number:
				return ParseNumber(text, out number);
			case .OneOf:
				for (let choice in part.Choices)
				{
					if (choice == text)
						return true;
				}
				return false;
			case .Speaker, .Flag, .Asset:
				return IsWord(text);
			default:
				return true;
			}
		}
	}

	/// A matched statement's arguments into `outArguments`: the defaults of what was left out, and
	/// one present-or-not argument per optional part of literal words alone (`[running]`), named by
	/// its words.
	static void Arguments(DialogueCommandForm form, MatchState state, List<DialogueArgument> outArguments)
	{
		int slot = 0;
		for (let part in form.Parts)
		{
			if (part.Literal)
				continue;
			let argument = new DialogueArgument();
			argument.Name.Set(part.Name);
			argument.Text.Set(state.Texts[slot]);
			argument.Number = state.Numbers[slot];
			argument.Present = state.Present[slot];
			slot++;
			if (!argument.Present && part.HasDefault)
			{
				argument.Text.Set(part.DefaultValue);
				ParseNumber(part.DefaultValue, out argument.Number);
			}
			outArguments.Add(argument);
		}
		for (uint32 g = 1; g <= form.GroupCount; g++)
		{
			if (g == form.WaitGroup)
				continue;
			bool literalsOnly = true;
			let name = scope String();
			for (let part in form.Parts)
			{
				if (part.Group != g)
					continue;
				literalsOnly = literalsOnly && part.Literal;
				if (!name.IsEmpty)
					name.Append(' ');
				name.Append(part.Word);
			}
			if (literalsOnly)
			{
				let presence = new DialogueArgument();
				presence.Name.Set(name);
				presence.Present = state.Taken[g];
				outArguments.Add(presence);
			}
		}
	}

	static DialogueArgument FindArgument(List<DialogueArgument> arguments, StringView name)
	{
		for (let argument in arguments)
		{
			if (argument.Name == name)
				return argument;
		}
		return null;
	}

	/// `#RRGGBB` or `#RRGGBBAA`.
	static bool ParseColor(StringView text, out Float4 color)
	{
		color = .(0.0f, 0.0f, 0.0f, 1.0f);
		if (!text.StartsWith("#") || ((text.Length != 7) && (text.Length != 9)))
			return false;
		float[4] channels = .(0.0f, 0.0f, 0.0f, 1.0f);
		for (int c < (text.Length - 1) / 2)
		{
			uint32 value = 0;
			for (int d < 2)
			{
				let h = text[1 + c * 2 + d];
				uint32 digit = 0;
				if ((h >= '0') && (h <= '9'))
					digit = (uint32)(h - '0');
				else if ((h >= 'a') && (h <= 'f'))
					digit = (uint32)(h - 'a') + 10;
				else if ((h >= 'A') && (h <= 'F'))
					digit = (uint32)(h - 'A') + 10;
				else
					return false;
				value = value * 16 + digit;
			}
			channels[c] = (float)value / 255.0f;
		}
		color = .(channels[0], channels[1], channels[2], channels[3]);
		return true;
	}

	/// The built-in statements that take arguments, as forms. Built on first use.
	static List<DialogueCommandForm> sBuiltIns ~ DeleteContainerAndItems!(_);

	static DialogueCommandForm BuiltInForm(StringView word)
	{
		if (sBuiltIns == null)
		{
			sBuiltIns = new .();
			String[?] texts = .("wait <seconds:number>", "set <flag:flag>", "clear <flag:flag>",
				"play <speaker:speaker> <clip:text> [and wait]", "sound <sound:asset(Sound)> [at <speaker:speaker>]",
				"fade <direction:in|out> [for <seconds:number>] [<color:word>]",
				"sequence <sequence:asset(Sequence)> [and wait]", "jump <conversation:word>");
			let error = scope String();
			for (let text in texts)
			{
				let form = new DialogueCommandForm();
				ParseForm(text, form, error, true);
				sBuiltIns.Add(form);
			}
		}
		for (let form in sBuiltIns)
		{
			if (form.Name == word)
				return form;
		}
		return null;
	}

	// ---- the structure -------------------------------------------------------------------------

	struct SourceLine
	{
		public uint32 Number;
		/// Trimmed.
		public StringView Text;

		public this(uint32 number, StringView text)
		{
			Number = number;
			Text = text;
		}
	}

	static StringView FirstWord(StringView text)
	{
		int end = 0;
		while ((end < text.Length) && !IsSpace(text[end]))
			end++;
		return text.Substring(0, end);
	}

	/// A line's or an answer's text and its explicit `#line:<id>`, when it ends with one.
	static void SplitLineId(StringView text, out StringView body, out StringView id)
	{
		body = text;
		id = "";
		const String cTag = "#line:";
		int at = -1;
		int from = 0;
		while (true)
		{
			let found = text.IndexOf(cTag, from);
			if (found < 0)
				break;
			at = found;
			from = found + 1;
		}
		if (at < 0)
			return;
		let candidate = text.Substring(at + cTag.Length);
		if (candidate.IsEmpty)
			return;
		for (let c in candidate)
		{
			if (!IsWordChar(c) && (c != '.'))
				return; // not an id at the very end: text
		}
		id = candidate;
		body = Trim(text.Substring(0, at));
	}

	class Parser
	{
		Span<DialogueCommandForm> mCommands;
		DialogueParse mOut; // the caller's
		List<SourceLine> mLines = new .() ~ delete _;
		int mAt = 0;
		DialogueConversation mConversation; // the one being read; owned by the caller until added
		/// The lines and answers of the conversation so far.
		uint32 mOrdinal = 0;

		public this(StringView text, Span<DialogueCommandForm> commands, DialogueParse outParse)
		{
			mCommands = commands;
			mOut = outParse;
			uint32 number = 0;
			int start = 0;
			while (start <= text.Length)
			{
				var end = text.IndexOf('\n', start);
				if (end < 0)
					end = text.Length;
				number++;
				let line = Trim(text.Substring(start, end - start));
				if (!line.IsEmpty && !line.StartsWith("#"))
					mLines.Add(.(number, line));
				start = end + 1;
			}
		}

		public void Run()
		{
			bool strayTold = false;
			while (mAt < mLines.Count)
			{
				let line = mLines[mAt];
				if (FirstWord(line.Text) != "conversation")
				{
					if (!strayTold)
					{
						Problem(line.Number, "a statement before any `conversation <id>`");
						strayTold = true;
					}
					mAt++;
					continue;
				}
				strayTold = false;
				Conversation(line);
			}
		}

		void Problem(uint32 line, StringView message, bool warning = false)
		{
			mOut.Problems.Add(new .(line, message, warning));
		}

		void Conversation(SourceLine header)
		{
			mAt++;
			let words = scope List<Word>();
			StatementWords(header.Text, words);
			let conversation = new DialogueConversation();
			if (((words.Count != 2) && (words.Count != 4)) || !IsWord(words[1].Text)
				|| ((words.Count == 4) && ((words[2].Text != "in") || !IsWord(words[3].Text))))
			{
				Problem(header.Number, "a conversation is `conversation <id> [in <level>]`, the level a dialogue asset's name");
			}
			else
			{
				conversation.Id.Set(words[1].Text);
				if (words.Count == 4)
					conversation.Level.Set(words[3].Text);
				for (let other in mOut.Conversations)
				{
					if (other.Id == conversation.Id)
						Problem(header.Number, scope $"a second conversation `{conversation.Id}`");
				}
			}
			mConversation = conversation;
			mOrdinal = 0;
			Block(conversation.Steps, false, false, false);
			let end = new DialogueStep(.End);
			end.SourceLine = header.Number;
			conversation.Steps.Add(end);
			mConversation = null;
			mOut.Conversations.Add(conversation);
		}

		/// Statements into `steps` until a word the caller waits for (`>`, `else`, `end`), the next
		/// conversation or the end. Returns the word it stopped at, empty for neither.
		StringView Block(List<DialogueStep> steps, bool stopAtAnswer, bool stopAtElse, bool stopAtEnd)
		{
			while (mAt < mLines.Count)
			{
				let line = mLines[mAt];
				let first = FirstWord(line.Text);
				if (first == "conversation")
					return "";
				if (line.Text.StartsWith(">"))
				{
					if (stopAtAnswer)
						return ">";
					Problem(line.Number, "an answer `>` outside a choice");
					mAt++;
					continue;
				}
				if ((first == "else") || (first == "end"))
				{
					if (line.Text != first)
						Problem(line.Number, scope $"`{first}` takes nothing after it");
					if (((first == "else") && stopAtElse) || ((first == "end") && stopAtEnd))
						return (first == "else") ? "else" : "end";
					Problem(line.Number, (first == "else") ? "an `else` outside an `if`" : "an `end` with nothing open");
					mAt++;
					continue;
				}
				Statement(line, steps);
			}
			return "";
		}

		void Statement(SourceLine line, List<DialogueStep> steps)
		{
			if (line.Text.StartsWith("@"))
			{
				LineStatement(line, steps);
				mAt++;
				return;
			}
			let first = FirstWord(line.Text);
			if (first == "choice")
			{
				Choice(line, steps);
				return;
			}
			if (first == "if")
			{
				If(line, steps);
				return;
			}
			mAt++;
			let words = scope List<Word>();
			if (!StatementWords(line.Text, words))
			{
				Problem(line.Number, "a quote `\"` is not closed");
				return;
			}
			if (let form = BuiltInForm(first))
			{
				BuiltIn(line, form, words, steps);
				return;
			}
			if ((first == "choice") || IsBuiltInStatement(first))
			{
				Problem(line.Number, scope $"`{first}` takes nothing after it");
				return;
			}
			Command(line, words, steps);
		}

		void NextLineId(StringView explicitId, uint32 line, String outId)
		{
			mOrdinal++;
			if (explicitId.IsEmpty)
			{
				outId.Append(mConversation.Id);
				outId.Append('.');
				mOrdinal.ToString(outId);
			}
			else
				outId.Append(explicitId);
			for (let other in mOut.Lines)
			{
				if (other.Id == outId)
				{
					Problem(line, scope $"a second line `#line:{outId}`");
					break;
				}
			}
		}

		void LineStatement(SourceLine line, List<DialogueStep> steps)
		{
			let rest = Trim(line.Text.Substring(1));
			let colon = rest.IndexOf(':');
			if (colon < 0)
			{
				Problem(line.Number, "a line is `@ <speaker> [mood]: <text>`");
				return;
			}
			let head = scope List<Word>();
			StatementWords(rest.Substring(0, colon), head);
			StringView body, id;
			SplitLineId(Trim(rest.Substring(colon + 1)), out body, out id);
			if (head.IsEmpty || (head.Count > 2) || !IsWord(head[0].Text) || ((head.Count == 2) && !IsWord(head[1].Text)))
			{
				Problem(line.Number, "a line is `@ <speaker> [mood]: <text>`: a speaker and a mood are words");
				return;
			}
			if (body.IsEmpty)
			{
				Problem(line.Number, "a line says nothing");
				return;
			}
			let step = new DialogueStep(.Line);
			step.Speaker.Set(head[0].Text);
			if (head.Count == 2)
				step.Mood.Set(head[1].Text);
			NextLineId(id, line.Number, step.LineId);
			step.SourceLine = line.Number;
			mOut.Lines.Add(new .(step.LineId, body));
			steps.Add(step);
		}

		/// Appends `body`'s steps to `steps`, their jumps moved to where they now start; `body` is
		/// left empty (its steps are `steps`' now).
		static void Append(List<DialogueStep> steps, List<DialogueStep> body)
		{
			let offset = (int32)steps.Count;
			for (let step in body)
			{
				if (step.Next >= 0)
					step.Next += offset;
				steps.Add(step);
			}
			body.Clear();
		}

		void Choice(SourceLine line, List<DialogueStep> steps)
		{
			if (line.Text != "choice")
				Problem(line.Number, "`choice` takes nothing after it");
			mAt++;
			// Each answer's step, and its statements apart until they are laid out after the table.
			let answers = scope List<DialogueStep>();
			let bodies = scope List<List<DialogueStep>>();
			defer
			{
				ClearAndDeleteItems!(answers);
				for (let body in bodies)
					DeleteContainerAndItems!(body);
			}
			StringView stopped = "";
			while ((mAt < mLines.Count) && mLines[mAt].Text.StartsWith(">"))
			{
				let answerLine = mLines[mAt];
				StringView body, id;
				SplitLineId(Trim(answerLine.Text.Substring(1)), out body, out id);
				let answer = new DialogueStep(.Answer);
				answer.SourceLine = answerLine.Number;
				if (body.IsEmpty)
					Problem(answerLine.Number, "an answer says nothing");
				NextLineId(id, answerLine.Number, answer.LineId);
				mOut.Lines.Add(new .(answer.LineId, body));
				mAt++;
				let statements = new List<DialogueStep>();
				answers.Add(answer);
				bodies.Add(statements);
				stopped = Block(statements, true, false, true);
				if (stopped != ">")
					break;
			}
			if (answers.IsEmpty)
			{
				Problem(line.Number, "a choice needs `> <answer>` lines");
				let skipped = scope List<DialogueStep>(); // read on to its `end`, kept out of the conversation
				defer { ClearAndDeleteItems!(skipped); }
				stopped = Block(skipped, false, false, true);
			}
			if (stopped == "end")
				mAt++;
			else
				Problem(line.Number, "the choice opened here is not closed by `end`");
			let choice = new DialogueStep(.Choice);
			choice.Count = (uint32)answers.Count;
			choice.SourceLine = line.Number;
			steps.Add(choice);
			let firstAnswer = steps.Count;
			steps.AddRange(answers);
			answers.Clear();
			let skips = scope List<int>();
			for (int a < bodies.Count)
			{
				steps[firstAnswer + a].Next = (int32)steps.Count;
				Append(steps, bodies[a]);
				let skip = new DialogueStep(.Skip);
				skip.SourceLine = line.Number;
				skips.Add(steps.Count);
				steps.Add(skip);
			}
			for (let skip in skips)
				steps[skip].Next = (int32)steps.Count;
		}

		void If(SourceLine line, List<DialogueStep> steps)
		{
			mAt++;
			let words = scope List<Word>();
			StatementWords(line.Text, words);
			let test = new DialogueStep(.If);
			test.SourceLine = line.Number;
			let negate = (words.Count == 3) && (words[1].Text == "not");
			if (((words.Count != 2) && !negate) || !IsWord(words.Back.Text))
				Problem(line.Number, "an if is `if [not] <flag>`");
			test.Negate = negate;
			test.Flag.Set(words.Back.Text);
			let at = steps.Count;
			steps.Add(test);
			var stopped = Block(steps, false, true, true);
			if (stopped == "else")
			{
				mAt++;
				let skip = new DialogueStep(.Skip);
				skip.SourceLine = line.Number;
				let skipAt = steps.Count;
				steps.Add(skip);
				steps[at].Next = (int32)steps.Count;
				stopped = Block(steps, false, false, true);
				steps[skipAt].Next = (int32)steps.Count;
			}
			else
			{
				steps[at].Next = (int32)steps.Count;
			}
			if (stopped == "end")
				mAt++;
			else
				Problem(line.Number, "the `if` opened here is not closed by `end`");
		}

		void BuiltIn(SourceLine line, DialogueCommandForm form, List<Word> words, List<DialogueStep> steps)
		{
			let state = scope MatchState();
			let matcher = scope FormMatcher(form, words);
			if (!matcher.Run(state))
			{
				Problem(line.Number, scope $"`{form.Name}` is `{form.Text}`");
				return;
			}
			let arguments = scope List<DialogueArgument>();
			defer { ClearAndDeleteItems!(arguments); }
			Arguments(form, state, arguments);
			StringView Text(StringView name)
			{
				let found = FindArgument(arguments, name);
				return (found != null) ? (StringView)found.Text : "";
			}
			float Number(StringView name)
			{
				let found = FindArgument(arguments, name);
				return (found != null) ? found.Number : 0.0f;
			}
			let waits = (form.WaitGroup != 0) && state.Taken[form.WaitGroup];
			let step = new DialogueStep();
			step.SourceLine = line.Number;
			StringView name = form.Name;
			if (name == "wait")
			{
				step.Kind = .Wait;
				step.Seconds = Number("seconds");
			}
			else if ((name == "set") || (name == "clear"))
			{
				step.Kind = (name == "set") ? .Set : .Clear;
				step.Flag.Set(Text("flag"));
			}
			else if (name == "play")
			{
				step.Kind = .Play;
				step.Speaker.Set(Text("speaker"));
				step.Name.Set(Text("clip"));
				step.Waits = waits;
			}
			else if (name == "sound")
			{
				step.Kind = .Sound;
				step.Name.Set(Text("sound"));
				step.Speaker.Set(Text("speaker"));
			}
			else if (name == "fade")
			{
				step.Kind = .Fade;
				step.FadeIn = Text("direction") == "in";
				let seconds = FindArgument(arguments, "seconds");
				step.Seconds = ((seconds != null) && seconds.Present) ? seconds.Number : -1.0f;
				let color = FindArgument(arguments, "color");
				if ((color != null) && color.Present)
				{
					if (!ParseColor(color.Text, out step.Color))
					{
						Problem(line.Number, scope $"`{color.Text}`: a colour is `#RRGGBB` or `#RRGGBBAA`");
						delete step;
						return;
					}
					step.HasColor = true;
				}
			}
			else if (name == "sequence")
			{
				step.Kind = .Sequence;
				step.Name.Set(Text("sequence"));
				step.Waits = waits;
			}
			else if (name == "jump")
			{
				step.Kind = .Jump;
				step.Name.Set(Text("conversation"));
				if (!IsWord(step.Name))
				{
					Problem(line.Number, "`jump` names a conversation by its id, a word");
					delete step;
					return;
				}
			}
			steps.Add(step);
		}

		void Command(SourceLine line, List<Word> words, List<DialogueStep> steps)
		{
			let first = words[0].Text;
			DialogueCommandForm nearest = null;
			let state = scope MatchState();
			for (let form in mCommands)
			{
				if (form.Parts.IsEmpty || (form.Parts[0].Word != first) || words[0].Quoted)
					continue;
				if (nearest == null)
					nearest = form;
				let matcher = scope FormMatcher(form, words);
				if (!matcher.Run(state))
					continue;
				let step = new DialogueStep(.Command);
				step.SourceLine = line.Number;
				step.Name.Set(form.Name);
				Arguments(form, state, step.Arguments);
				step.Waits = (form.Wait == .Always) || ((form.WaitGroup != 0) && state.Taken[form.WaitGroup]);
				step.Leaves = form.Wait == .Leaves;
				steps.Add(step);
				return;
			}
			if (nearest != null)
				Problem(line.Number, scope $"no declared command reads this: the nearest is `{nearest.Text}` (a name holding one of its words is written in quotes)");
			else
				Problem(line.Number, scope $"`{first}` is no statement and no declared command");
		}
	}
}
