using System;

namespace Sedulous.Shell.Web;

/// html5.h's EmscriptenPointerlockChangeEvent: whether an element holds the pointer lock now,
/// and which. Only the flag is read, but the struct has to be the right size because the
/// browser writes the whole of it.
[CRepr]
struct EmscriptenPointerlockChangeEvent
{
	public bool IsActive;
	public char8[128] NodeName;
	public char8[128] Id;
}
