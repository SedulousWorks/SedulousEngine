using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// A serializable type with the after-read hook: it counts how often it was called and sees
/// the fields already read.
[Serializable(1, true)] // afterRead
class AfterReadSample
{
	public int32 Value;
	[NotSerialized]
	public int32 ReadCount;
	[NotSerialized]
	public int32 ValueSeen;

	public void AfterRead()
	{
		ReadCount++;
		ValueSeen = Value;
	}
}
