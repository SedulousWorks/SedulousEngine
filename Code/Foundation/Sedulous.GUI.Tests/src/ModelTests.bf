using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The model layer's addresses: a model index's validity and equality.
class ModelTests
{
	[Test]
	public static void ModelIndexValidityAndEquality()
	{
		Test.Assert(!ModelIndex().IsValid); // default row -1
		Test.Assert(MakeModelIndex(0, 0).IsValid);
		Test.Assert(MakeModelIndex(3, 1) == MakeModelIndex(3, 1));
		Test.Assert(!(MakeModelIndex(3, 1) == MakeModelIndex(3, 2)));
	}
}
