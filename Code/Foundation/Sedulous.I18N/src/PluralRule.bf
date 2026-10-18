using System;
using System.Collections;

namespace Sedulous.I18N;

/// CLDR's plural categories, in its order (the order rules are tried in).
enum PluralCategory : uint8
{
	case Zero;
	case One;
	case Two;
	case Few;
	case Many;
	case Other;

	public const int Count = 6;

	private static readonly String[Count] sNames = .("zero", "one", "two", "few", "many", "other");

	/// The category's name as CLDR and the tables write it ("zero" ... "other").
	public StringView Name => sNames[(int)this];

	/// The category a name means; false for a name that is none.
	public static bool FromName(StringView name, out PluralCategory category)
	{
		for (int i < Count)
		{
			if (sNames[i] == name)
			{
				category = (PluralCategory)i;
				return true;
			}
		}
		category = .Other;
		return false;
	}
}

/// Why a rule did not parse: what, and where in its text.
class PluralRuleError
{
	public String Message = new .() ~ delete _;
	public int Position;
}

/// A language's plural rule, as data a string table carries: for each category it uses but
/// `other`, a condition in CLDR's rule syntax for integer counts ("one: n = 1; few: n % 10 =
/// 2..4 and n % 100 != 12..14"). Parsed once, when set (a rule that does not parse is refused
/// with its position), then evaluated per count: the conditions in CLDR's category order, the
/// first that holds chosen, else other.
///
/// The syntax: a condition is relations joined by `and` (binding tighter) and `or`; a relation
/// is an operand (`n`, or `i`, the same for integers) optionally `% <value>`, then `=` or `!=`,
/// then a list of values and ranges (`2..4, 22..24`). Fractions (CLDR's v, f, t) are deferred.
class PluralRule
{
	private struct Range
	{
		public uint64 Low;
		public uint64 High;
	}

	private struct Relation
	{
		/// Nought for none.
		public uint64 Modulo;
		public bool Equal;
		/// Whether this relation starts an `or` alternative; the ones after it, up to the next
		/// that does, are joined by `and`.
		public bool StartsAlternative;
		public int RangeStart;
		public int RangeCount;
	}

	/// One category's condition, flat: its relations in order, and the ranges they index.
	private class Condition
	{
		public List<Relation> Relations = new .() ~ delete _;
		public List<Range> Ranges = new .() ~ delete _;

		public bool Holds(uint64 n)
		{
			// Alternatives in turn; within one, every relation must hold.
			bool alternativeHolds = false;
			for (let relation in Relations)
			{
				if (relation.StartsAlternative)
				{
					if (alternativeHolds && (@relation.Index > 0))
						return true;
					alternativeHolds = true;
				}
				if (!alternativeHolds)
					continue;

				let value = (relation.Modulo != 0) ? (n % relation.Modulo) : n;
				bool inRanges = false;
				for (int r = relation.RangeStart; r < relation.RangeStart + relation.RangeCount; r++)
					inRanges = inRanges || ((value >= Ranges[r].Low) && (value <= Ranges[r].High));
				if (inRanges != relation.Equal)
					alternativeHolds = false;
			}
			return alternativeHolds;
		}
	}

	/// One per category but other; null where the rule gives none.
	private Condition[PluralCategory.Count - 1] mConditions;
	private String mSource = new .() ~ delete _;

	public ~this()
	{
		for (let condition in mConditions)
			delete condition;
	}

	/// The text it was parsed from.
	public StringView Source => mSource;

	/// Parses a whole rule ("one: n = 1; few: ..."); categories may come in any order, `other`
	/// takes no condition and may be left out, an empty rule means everything is other. False,
	/// with `error`, when it does not parse; the rule is then unchanged.
	public bool Parse(StringView source, PluralRuleError error = null)
	{
		Condition[PluralCategory.Count - 1] parsed = default;
		var parser = Parser(source, scope .());
		parser.SkipSpace();
		while (!parser.AtEnd && !parser.Failed)
		{
			let nameAt = parser.At;
			let name = parser.Word();
			PluralCategory category = .Other;
			if (name.IsEmpty || !PluralCategory.FromName(name, out category))
				parser.Fail("a category name (zero, one, two, few, many, other)", nameAt);
			else if ((category != .Other) && (parsed[(int)category] != null))
				parser.Fail("a category given once", nameAt);
			parser.Expect(':');
			if (parser.Failed)
				break;

			if (category == .Other)
			{
				// Other holds whatever the rest does not; a condition there is ignored.
				parser.SkipSpace();
				while (!parser.AtEnd && (parser.Peek != ';'))
					parser.At++;
			}
			else
			{
				let condition = new Condition();
				parsed[(int)category] = condition;
				parser.ParseCondition(condition);
			}

			parser.SkipSpace();
			if (!parser.AtEnd && !parser.Failed)
			{
				parser.Expect(';');
				parser.SkipSpace();
			}
		}

		if (parser.Failed)
		{
			if (error != null)
			{
				error.Message.Set(parser.Message);
				error.Position = parser.FailedAt;
			}
			for (let condition in parsed)
				delete condition;
			return false;
		}

		for (int i < mConditions.Count)
		{
			delete mConditions[i];
			mConditions[i] = parsed[i];
		}
		mSource.Set(source);
		return true;
	}

	/// The category of count `n` (a negative count counts as its magnitude).
	public PluralCategory CategoryOf(int64 n)
	{
		let value = (n < 0) ? ((uint64)(-(n + 1)) + 1) : (uint64)n;
		for (int i < mConditions.Count)
		{
			if ((mConditions[i] != null) && mConditions[i].Holds(value))
				return (PluralCategory)i;
		}
		return .Other;
	}

	/// Whether the rule has a condition for the category (other always counts as used).
	public bool Uses(PluralCategory category) =>
		(category == .Other) || (mConditions[(int)category] != null);

	private struct Parser
	{
		public StringView Text;
		public int At;
		public bool Failed;
		public int FailedAt;
		/// BORROWED: what was expected, once it failed.
		public String Message;

		public this(StringView text, String message)
		{
			Text = text;
			At = 0;
			Failed = false;
			FailedAt = 0;
			Message = message;
		}

		public bool AtEnd => At >= Text.Length;
		public char8 Peek => AtEnd ? '\0' : Text[At];

		public void SkipSpace() mut
		{
			while (!AtEnd && ((Text[At] == ' ') || (Text[At] == '\t') || (Text[At] == '\n') || (Text[At] == '\r')))
				At++;
		}

		public void Fail(StringView expected, int position) mut
		{
			if (Failed)
				return;
			Failed = true;
			Message.Set("expected ");
			Message.Append(expected);
			FailedAt = position;
		}

		public void Expect(char8 c) mut
		{
			SkipSpace();
			if (Peek != c)
			{
				Fail(StringView(&c, 1), At);
				return;
			}
			At++;
		}

		public StringView Word() mut
		{
			SkipSpace();
			let start = At;
			while (!AtEnd && (((Text[At] >= 'a') && (Text[At] <= 'z')) || ((Text[At] >= 'A') && (Text[At] <= 'Z'))))
				At++;
			return Text.Substring(start, At - start);
		}

		public uint64 Number() mut
		{
			SkipSpace();
			if (AtEnd || (Text[At] < '0') || (Text[At] > '9'))
			{
				Fail("a number", At);
				return 0;
			}
			uint64 value = 0;
			while (!AtEnd && (Text[At] >= '0') && (Text[At] <= '9'))
				value = value * 10 + (uint64)((int)Text[At++] - (int)'0');
			return value;
		}

		public bool TryWord(StringView word) mut
		{
			SkipSpace();
			let save = At;
			if (Word() == word)
				return true;
			At = save;
			return false;
		}

		public void ParseRelation(Condition condition, bool startsAlternative) mut
		{
			var relation = Relation();
			relation.Equal = true;
			relation.StartsAlternative = startsAlternative;
			relation.RangeStart = condition.Ranges.Count;

			SkipSpace();
			let operandAt = At;
			let operand = Word();
			if ((operand != "n") && (operand != "i"))
			{
				Fail("the operand n or i", operandAt);
				return;
			}
			SkipSpace();
			if (Peek == '%')
			{
				At++;
				relation.Modulo = Number();
				if (!Failed && (relation.Modulo == 0))
					Fail("a modulo above zero", At);
			}
			SkipSpace();
			if ((Peek == '!') && (At + 1 < Text.Length) && (Text[At + 1] == '='))
			{
				relation.Equal = false;
				At += 2;
			}
			else if (Peek == '=')
				At++;
			else
			{
				Fail("= or !=", At);
				return;
			}

			while (true)
			{
				var range = Range();
				range.Low = range.High = Number();
				SkipSpace();
				if (!Failed && (Peek == '.') && (At + 1 < Text.Length) && (Text[At + 1] == '.'))
				{
					At += 2;
					range.High = Number();
					if (!Failed && (range.High < range.Low))
						Fail("a range from low to high", At);
				}
				if (Failed)
					return;
				condition.Ranges.Add(range);
				SkipSpace();
				if (Peek != ',')
					break;
				At++;
			}
			relation.RangeCount = condition.Ranges.Count - relation.RangeStart;
			condition.Relations.Add(relation);
		}

		public void ParseCondition(Condition condition) mut
		{
			while (true)
			{
				ParseRelation(condition, true);
				while (!Failed && TryWord("and"))
					ParseRelation(condition, false);
				if (Failed)
					return;
				if (!TryWord("or"))
					break;
			}
			SkipSpace();
			if (!Failed && !AtEnd && (Peek != ';'))
				Fail("and, or, ; or the end", At);
		}
	}
}
