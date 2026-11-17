using System;

namespace Sedulous.Shell.Web;

/// html5.h's EmscriptenVisibilityChangeEvent: whether the page is hidden now.
[CRepr]
struct EmscriptenVisibilityChangeEvent
{
	public bool Hidden;
	public int32 VisibilityState;
}
