using System;

namespace Sedulous.UI.Toolkit;

/// The tables for a Lua shaped language. Like the C shaped one, the toolkit ships none of them.
struct LuaLikeLexerSpec
{
	/// BORROWED on the way in; the lexer copies them.
	public Span<StringView> Keywords = default;
	public Span<StringView> Types = default;

	public this() {}
}
