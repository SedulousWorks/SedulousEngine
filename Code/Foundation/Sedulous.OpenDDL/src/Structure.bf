using System;
using System.Collections;

namespace Sedulous.OpenDDL;

/// <summary>
/// Base class for all structures in an OpenDDL file.
/// Structures are organized in a tree hierarchy and can be either primitive
/// (containing raw data) or derived (containing substructures).
/// </summary>
class Structure
{
	private StructureType mStructureType;
	private StructureType mBaseStructureType;
	private String mStructureName = new .() ~ delete _;
	private bool mGlobalNameFlag = true;
	private String mTextLocation ~ delete _; // For error reporting

	// Tree structure
	private Structure mParent;
	private Structure mFirstChild;
	private Structure mLastChild;
	private Structure mPrevSibling;
	private Structure mNextSibling;

	// Name map for local names within this structure's children
	private Dictionary<StringView, Structure> mLocalNameMap = new .() ~ delete _;

	/// <summary>
	/// Creates a new structure with the specified type.
	/// </summary>
	public this(StructureType type)
	{
		mStructureType = type;
		mBaseStructureType = 0;
	}

	public ~this()
	{
		// Delete all children
		var child = mFirstChild;
		while (child != null)
		{
			let next = child.mNextSibling;
			delete child;
			child = next;
		}
	}

	/// <summary>
	/// Gets the structure type identifier.
	/// </summary>
	public StructureType StructureType => mStructureType;

	/// <summary>
	/// Gets or sets the base structure type.
	/// For primitive structures, this is set to StructureTypes.Primitive.
	/// </summary>
	public StructureType BaseStructureType
	{
		get => mBaseStructureType;
		protected set => mBaseStructureType = value;
	}

	/// <summary>
	/// Gets the structure name (without the $ or % prefix).
	/// Returns an empty string if the structure has no name.
	/// </summary>
	public StringView StructureName => mStructureName;

	/// <summary>
	/// Returns true if the structure has a name.
	/// </summary>
	public bool HasName => !mStructureName.IsEmpty;

	/// <summary>
	/// Returns true if the structure's name is global ($).
	/// Returns false if the name is local (%).
	/// </summary>
	public bool IsGlobalName => mGlobalNameFlag;

	/// <summary>
	/// Sets the structure name.
	/// </summary>
	/// <param name="name">The name (without $ or % prefix).</param>
	/// <param name="global">True for global name ($), false for local (%).</param>
	public void SetName(StringView name, bool global)
	{
		mStructureName.Set(name);
		mGlobalNameFlag = global;
	}

	/// <summary>
	/// Clears the structure name.
	/// </summary>
	public void ClearName()
	{
		mStructureName.Clear();
	}

	/// <summary>
	/// Updates the parent's local name map after the name has been set.
	/// Call this when SetName is called after the structure is already a child.
	/// </summary>
	public void UpdateParentLocalNameMap()
	{
		if (mParent != null && HasName && !IsGlobalName)
		{
			mParent.mLocalNameMap[mStructureName] = this;
		}
	}

	// ---- Tree Navigation ----

	/// <summary>
	/// Gets the parent structure.
	/// </summary>
	public Structure Parent => mParent;

	/// <summary>
	/// Gets the first child structure.
	/// </summary>
	public Structure FirstChild => mFirstChild;

	/// <summary>
	/// Gets the last child structure.
	/// </summary>
	public Structure LastChild => mLastChild;

	/// <summary>
	/// Gets the previous sibling structure.
	/// </summary>
	public Structure PrevSibling => mPrevSibling;

	/// <summary>
	/// Gets the next sibling structure.
	/// </summary>
	public Structure NextSibling => mNextSibling;

	/// <summary>
	/// Returns true if this structure has any children.
	/// </summary>
	public bool HasChildren => mFirstChild != null;

	/// <summary>
	/// Returns the number of direct children.
	/// </summary>
	public int ChildCount
	{
		get
		{
			var count = 0;
			var child = mFirstChild;
			while (child != null)
			{
				count++;
				child = child.mNextSibling;
			}
			return count;
		}
	}

	/// <summary>
	/// Enumerates all direct children.
	/// </summary>
	public ChildEnumerator Children => .(mFirstChild);

	public struct ChildEnumerator : IEnumerator<Structure>
	{
		private Structure mCurrent;
		private Structure mNext;

		public this(Structure first)
		{
			mCurrent = null;
			mNext = first;
		}

		public Result<Structure> GetNext() mut
		{
			if (mNext == null)
				return .Err;

			mCurrent = mNext;
			mNext = mCurrent.mNextSibling;
			return .Ok(mCurrent);
		}
	}

	// ---- Tree Manipulation ----

	/// <summary>
	/// Appends a child structure to the end of this structure's children.
	/// </summary>
	public void AppendChild(Structure child)
	{
		Runtime.Assert(child.mParent == null, "Structure already has a parent");

		child.mParent = this;
		child.mPrevSibling = mLastChild;
		child.mNextSibling = null;

		if (mLastChild != null)
			mLastChild.mNextSibling = child;
		else
			mFirstChild = child;

		mLastChild = child;

		// Add to local name map if it has a local name
		if (child.HasName && !child.IsGlobalName)
		{
			mLocalNameMap[child.mStructureName] = child;
		}
	}

	/// <summary>
	/// Prepends a child structure to the beginning of this structure's children.
	/// </summary>
	public void PrependChild(Structure child)
	{
		Runtime.Assert(child.mParent == null, "Structure already has a parent");

		child.mParent = this;
		child.mPrevSibling = null;
		child.mNextSibling = mFirstChild;

		if (mFirstChild != null)
			mFirstChild.mPrevSibling = child;
		else
			mLastChild = child;

		mFirstChild = child;

		// Add to local name map if it has a local name
		if (child.HasName && !child.IsGlobalName)
		{
			mLocalNameMap[child.mStructureName] = child;
		}
	}

	/// <summary>
	/// Removes this structure from its parent's children list.
	/// </summary>
	public void RemoveFromParent()
	{
		if (mParent == null)
			return;

		// Remove from local name map
		if (HasName && !IsGlobalName)
		{
			mParent.mLocalNameMap.Remove(mStructureName);
		}

		if (mPrevSibling != null)
			mPrevSibling.mNextSibling = mNextSibling;
		else
			mParent.mFirstChild = mNextSibling;

		if (mNextSibling != null)
			mNextSibling.mPrevSibling = mPrevSibling;
		else
			mParent.mLastChild = mPrevSibling;

		mParent = null;
		mPrevSibling = null;
		mNextSibling = null;
	}

	/// <summary>
	/// Removes all children from this structure.
	/// </summary>
	public void ClearChildren()
	{
		var child = mFirstChild;
		while (child != null)
		{
			let next = child.mNextSibling;
			child.mParent = null;
			child.mPrevSibling = null;
			child.mNextSibling = null;
			delete child;
			child = next;
		}

		mFirstChild = null;
		mLastChild = null;
		mLocalNameMap.Clear();
	}

	// ---- Structure Finding ----

	/// <summary>
	/// Gets the first child with the specified structure type.
	/// </summary>
	public Structure GetFirstSubstructure(StructureType type)
	{
		var child = mFirstChild;
		while (child != null)
		{
			if (child.mStructureType == type)
				return child;
			child = child.mNextSibling;
		}
		return null;
	}

	/// <summary>
	/// Gets the last child with the specified structure type.
	/// </summary>
	public Structure GetLastSubstructure(StructureType type)
	{
		var child = mLastChild;
		while (child != null)
		{
			if (child.mStructureType == type)
				return child;
			child = child.mPrevSibling;
		}
		return null;
	}

	/// <summary>
	/// Finds a child structure by local name.
	/// </summary>
	public Structure FindLocalChild(StringView name)
	{
		if (mLocalNameMap.TryGetValue(name, let child))
			return child;
		return null;
	}

	/// <summary>
	/// Finds a structure using a local reference starting from this structure's children.
	/// </summary>
	/// <param name="reference">The reference to follow.</param>
	/// <param name="index">The starting index in the reference's name array.</param>
	/// <returns>The found structure, or null if not found.</returns>
	public Structure FindStructure(StructureRef reference, int index = 0)
	{
		if (reference.IsNull)
			return null;

		// If index is 0 and this is a global reference, we shouldn't be here
		if (index == 0 && reference.IsGlobal)
			return null;

		if (index >= reference.Count)
			return null;

		let name = reference[index];
		let child = FindLocalChild(name);

		if (child == null)
			return null;

		if (index + 1 >= reference.Count)
			return child;

		return child.FindStructure(reference, index + 1);
	}

	// ---- Virtual Methods for Derived Types ----

	/// <summary>
	/// Validates a property for this structure.
	/// Override in derived classes to handle custom properties.
	/// </summary>
	/// <param name="dataDescription">The data description being parsed.</param>
	/// <param name="identifier">The property identifier.</param>
	/// <param name="type">Receives the expected data type for the property.</param>
	/// <returns>True if the property is valid, false otherwise.</returns>
	public virtual bool ValidateProperty(DataDescription dataDescription, StringView identifier, out DataType type)
	{
		type = default;
		return false;
	}

	/// <summary>
	/// Validates a substructure for this structure.
	/// Override in derived classes to restrict allowed child types.
	/// </summary>
	/// <param name="dataDescription">The data description being parsed.</param>
	/// <param name="structure">The substructure to validate.</param>
	/// <returns>True if the substructure is valid, false otherwise.</returns>
	public virtual bool ValidateSubstructure(DataDescription dataDescription, Structure structure)
	{
		return true;
	}

	/// <summary>
	/// Translates a state identifier to a state value for primitive subarrays.
	/// Override in derived classes that use state identifiers.
	/// </summary>
	/// <param name="identifier">The state identifier.</param>
	/// <param name="state">Receives the state value.</param>
	/// <returns>True if the identifier is recognized, false otherwise.</returns>
	public virtual bool GetStateValue(StringView identifier, out uint32 state)
	{
		state = 0;
		return false;
	}

	/// <summary>
	/// Processes the data in this structure after parsing.
	/// Override in derived classes to perform custom data processing.
	/// </summary>
	/// <param name="dataDescription">The data description.</param>
	/// <returns>Ok on success, or an error code.</returns>
	public virtual DataResult ProcessData(DataDescription dataDescription)
	{
		// Default implementation: process all children
		var child = mFirstChild;
		while (child != null)
		{
			let next = child.mNextSibling;
			let result = child.ProcessData(dataDescription);
			if (result != .Ok)
				return result;
			child = next;
		}
		return .Ok;
	}

	/// <summary>
	/// Sets the text location for error reporting.
	/// </summary>
	internal void SetTextLocation(StringView location)
	{
		delete mTextLocation;
		mTextLocation = new String(location);
	}

	/// <summary>
	/// Gets the text location for error reporting.
	/// </summary>
	public StringView TextLocation => mTextLocation ?? "";
}

/// <summary>
/// The root structure that contains all top-level structures in an OpenDDL file.
/// </summary>
class RootStructure : Structure
{
	public this() : base(StructureTypes.Root)
	{
	}

	public override bool ValidateSubstructure(DataDescription dataDescription, Structure structure)
	{
		return dataDescription.ValidateTopLevelStructure(structure);
	}
}
