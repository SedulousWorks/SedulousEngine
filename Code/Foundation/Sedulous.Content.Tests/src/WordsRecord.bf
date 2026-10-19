using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Content.Tests;

/// Many small fields: a record whose binary envelope is read field by field.
[Serializable]
class WordsRecord
{
	public List<String> Words = new .() ~ DeleteContainerAndItems!(_);
}
