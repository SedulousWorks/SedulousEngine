using System;

namespace Sedulous.Shell.Web;

/// html5.h's EmscriptenFocusEvent. Only its arrival matters here, not which node, but the
/// struct still has to be the right size because the browser writes the whole of it.
[CRepr]
struct EmscriptenFocusEvent
{
	public char8[128] NodeName;
	public char8[128] Id;
}
