namespace Sedulous.Editor.Core;

using System;
using System.Reflection;

/// Generic command for changing a field value on any object via reflection.
/// Used by ReflectionInspector to wire PropertyEditor changes to undo.
class PropertyChangeCommand : IEditorCommand
{
	private Object mTarget;
	private FieldInfo mField;
	private Variant mOldValue;
	private Variant mNewValue;
	private String mDescription = new .() ~ delete _;

	public this(Object target, FieldInfo field, Variant oldValue, Variant newValue)
	{
		mTarget = target;
		mField = field;
		mOldValue = oldValue;
		mNewValue = newValue;
		mDescription.AppendF("Change {}", field.Name);
	}

	public StringView Description => mDescription;

	public void Execute()
	{
		mField.SetValue(mTarget, mNewValue);
	}

	public void Undo()
	{
		mField.SetValue(mTarget, mOldValue);
	}

	public bool CanMergeWith(IEditorCommand other)
	{
		if (let otherProp = other as PropertyChangeCommand)
			return otherProp.mTarget === mTarget && otherProp.mField.Name == mField.Name;
		return false;
	}

	public void MergeWith(IEditorCommand other)
	{
		if (let otherProp = other as PropertyChangeCommand)
			mNewValue = otherProp.mNewValue;
	}

	public void Dispose()
	{
		mOldValue.Dispose();
		mNewValue.Dispose();
	}
}
