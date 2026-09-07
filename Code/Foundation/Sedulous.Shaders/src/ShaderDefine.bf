using System;

namespace Sedulous.Shaders;

/// One preprocessor definition handed to the compile.
///
/// Views, not owned strings: a define lives only as long as the compile it configures, and
/// the flag table's names are static literals.
struct ShaderDefine
{
	public StringView Name;
	public StringView Value;

	public this() { Name = default; Value = default; }

	public this(StringView name, StringView value)
	{
		Name = name;
		Value = value;
	}
}
