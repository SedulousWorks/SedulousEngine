using System;

namespace Sedulous.Core
{
	/// A list read and resized without naming its element type: how many elements, what type
	/// they are, and where each one lives, so generic tooling (an agent's entity_inspect and
	/// component_set) walks a list field of a reflected component as it walks the component's
	/// own fields, an address plus a type.
	///
	/// Interface dispatch, not reflection: corlib's IList has no count and hands out copies, so
	/// List<T> is given this below.
	interface IReflectedList
	{
		/// Setting it shrinks the list, or grows it with ZEROED elements: a nil Ref or EntityRef,
		/// a nought, but a null object, so a caller grows only a list of plain data.
		int Count { get; set; }
		Type ElementType { get; }
		/// The element's address inside the list's storage; valid until the list changes.
		void* ElementAddress(int index);
	}
}

namespace System.Collections
{
	extension List<T> : Sedulous.Core.IReflectedList
	{
		public Type ElementType => typeof(T);

		public void* ElementAddress(int index) => &this[index];
	}
}
