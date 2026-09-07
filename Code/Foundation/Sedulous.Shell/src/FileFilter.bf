using System;

namespace Sedulous.Shell;

/// A file type filter for an open or save dialog.
///
/// Pattern is a semicolon separated list of extensions WITHOUT dots, such as
/// "png;jpg;jpeg", and "*" matches everything. Both views are borrowed for the duration of
/// the Show call.
struct FileFilter
{
	public StringView Name;
	public StringView Pattern;

	public this() { Name = default; Pattern = default; }
	public this(StringView name, StringView pattern) { Name = name; Pattern = pattern; }
}
