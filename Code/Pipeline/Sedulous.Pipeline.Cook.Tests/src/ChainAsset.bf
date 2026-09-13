using System;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Pipeline.Cook.Tests;

/// An asset that READS one instance and REFERENCES another, which is the whole point: the two
/// kinds of dependency behave differently and a case needs both in one place to see it.
[Serializable]
class ChainAsset : Asset
{
	public Guid ReadDep = .Empty;
	public Guid RefDep = .Empty;
}
