using Sedulous.Core.Serialization;

namespace Sedulous.Resource.Tests;

/// A record read as it was authored, which no cook builds: only the sources hold it.
[Serializable]
class AuthoredRecord
{
	public int32 Value;
}
