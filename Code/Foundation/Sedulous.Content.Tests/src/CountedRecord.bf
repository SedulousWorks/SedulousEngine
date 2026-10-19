using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Content.Tests;

/// Counts the reads of its body, so a test can tell a refused payload was never walked.
[Serializable(0, true)] // afterRead
class CountedRecord
{
	public int32 Value;

	public static int Reads;

	public void AfterRead()
	{
		Reads++;
	}
}
