using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.GUI;
using Sedulous.Engine.Animation;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

// The inspector's bone name: a string with the BoneName
// attribute (an IK chain's bones, an aim's) picked from the bones of the animator at or above the
// entity shown, so a chain is chosen, not typed. "(none)" first, then the bones in the skeleton's
// order; a name the skeleton does not have stays listed and says so (the component turns itself off
// for it while the scene runs). With no animator, or its skeleton not loaded, the plain text field.
// A pick is one write through the grid, so one undo step.

class BoneNameEditor : PropertyEditor
{
	/// The hint the field source gives a BoneName row (RegisterHintAttribute).
	public const String cHint = "boneName";
	public const String cNoneText = "(none)";

	/// Borrowed: the registrar's, outliving the editor.
	private SceneEditContext mEdit;
	private Sedulous.GUI.ComboBox mCombo ~ _.ReleaseRef();
	private TextField mField ~ _.ReleaseRef();
	/// The combo's items' names, "" for none.
	private List<String> mNames = new .() ~ DeleteContainerAndItems!(_);
	private bool mListing = false;
	/// Showing a value, not the user picking one.
	private bool mBinding = false;

	/// `edit` outlives the editor (the registrar's).
	public this(SceneEditContext edit)
	{
		mEdit = edit;
		AddClass("bone-name");
		mCombo = new Sedulous.GUI.ComboBox();
		mCombo.Placeholder = MixedValueText();
		mCombo.SetOnSelectionChanged(new (index) =>
			{
				if (mBinding || (index < 0) || (index >= mNames.Count))
					return;
				ApplyEdit(PropertyWrite(Sedulous.GUI.Variant(mNames[index])));
			});
		mField = new TextField();
		mField.SetOnTextChanged(new (text) => { ApplyEdit(PropertyWrite(Sedulous.GUI.Variant(text))); });
		AddChild(mCombo);
		AddChild(mField);
	}

	/// The editor for every BoneName row `registry` shows, over `edit`'s scene; and the field source
	/// told to hint those rows (once per process: a second call hints nothing more).
	public static void Register(PropertyEditorRegistry registry, SceneEditContext edit)
	{
		if (!sHinted)
		{
			sHinted = true;
			FieldPropertySource.RegisterHintAttribute<BoneNameAttribute>(cHint);
		}
		registry.RegisterHint(cHint, new [=edit] () => new BoneNameEditor(edit));
	}

	private static bool sHinted = false;

	public override bool IsTyping => mField.IsFocused;
	public Sedulous.GUI.ComboBox ComboBox => mCombo;
	public TextField Field => mField;
	/// True while it lists a skeleton's bones; false for the text field.
	public bool ListsBones => mListing;

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mBinding = true;
		defer { mBinding = false; }
		let current = scope String(value.Mixed ? StringView() : value.Value.AsString);
		let skeleton = SkeletonAbove();
		mListing = skeleton != null;
		mCombo.Visible = mListing;
		mField.Visible = !mListing;
		if (mListing)
		{
			ClearAndDeleteItems!(mNames);
			mNames.Add(new String());
			mCombo.ItemsText = "";
			mCombo.AddItem(cNoneText);
			for (int32 i < skeleton.BoneCount)
			{
				mNames.Add(new String(skeleton.GetBone(i).Name));
				mCombo.AddItem(mNames.Back);
			}
			if (!current.IsEmpty && (skeleton.FindBone(current) < 0))
			{
				mNames.Add(new String(current));
				mCombo.AddItem(scope $"{current} (not in the skeleton)");
			}
			int32 selected = -1;
			if (!value.Mixed)
			{
				for (int i < mNames.Count)
				{
					if (mNames[i] == current)
						selected = (int32)i;
				}
			}
			mCombo.SelectedIndex = selected;
			mCombo.Enabled = !IsReadOnly;
		}
		else
		{
			mField.Placeholder = value.Mixed ? MixedValueText() : StringView();
			mField.Text = current;
			mField.IsReadOnly = IsReadOnly;
		}
	}

	public override void OnLayout()
	{
		mCombo.Arrange(ContentBounds);
		mField.Arrange(ContentBounds);
	}

	protected override void OnTextStyleChange()
	{
		ShareTextStyle(mCombo);
		ShareTextStyle(mField);
	}

	// The skeleton of the animator at or above the entity the inspector shows (its primary, for
	// several); null with none, or its skeleton not loaded.
	private Sedulous.Animation.Skeleton SkeletonAbove()
	{
		if ((mEdit == null) || mEdit.EntitySelection.IsEmpty)
			return null;
		let scene = mEdit.Scene;
		let entity = scene.FindEntity(mEdit.EntitySelection.Primary);
		if (!entity.IsAssigned)
			return null;
		if (IkScene.FindAuthoringAnimator(scene, entity, let animator) != .Found)
			return null;
		return animator.Skeleton;
	}
}
