using System;
using System.Collections;
using AngelScript;
using Sedulous.Script;

namespace Sedulous.Script.AngelScript;

/// A script class instance: the AngelScript object, with its methods and properties
/// resolved once by name, so a dispatch per frame is a lookup, not a search.
class AngelScriptObject : ScriptObject
{
	public AS.ScriptObject* Object;
	public AS.TypeInfo* Type;

	/// One property: where it is in the object and what it is.
	public struct Property
	{
		public uint32 Index;
		public int32 TypeId;
	}

	public Dictionary<String, Property> Properties = new .() ~ DeleteDictionaryAndKeys!(_);

	/// A method found for a call, by its name and argument count, with the label its call
	/// reports under: a compiled class's methods never change, so each is found once.
	public class FoundMethod
	{
		public String Name = new .() ~ delete _;
		public String What = new .() ~ delete _;
		public int Arity;
		public AS.Function* Function;
	}

	public List<FoundMethod> Found = new .() ~ DeleteContainerAndItems!(_);

	public ~this()
	{
		if (Object != null)
			AS.asc_object_release(Object);
	}
}
