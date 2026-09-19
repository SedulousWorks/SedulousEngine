using System;

namespace Sedulous.Script;

/// One source file of a module: its name, which errors and breakpoints key on, and its
/// text. Borrowed for the compile.
struct ScriptSection
{
	public StringView Name;
	public StringView Source;

	public this(StringView name, StringView source)
	{
		Name = name;
		Source = source;
	}
}
