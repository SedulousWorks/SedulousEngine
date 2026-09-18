using Sedulous.Core;
namespace Sedulous.Core.IO;

/// What a seek offset is measured from.
[Scriptable(.AllPublic)]
enum SeekOrigin
{
	Begin,
	Current,
	End
}
