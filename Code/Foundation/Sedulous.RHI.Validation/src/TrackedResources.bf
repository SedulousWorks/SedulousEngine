using System;
using System.Collections;

namespace Sedulous.RHI.Validation;

/// The live objects of ONE kind that a device handed out.
///
/// Tracking is what turns two silent mistakes into reported ones: destroying something
/// twice, or through the wrong device, and letting a device go while it still owns things.
/// Both are invisible without a list of what is outstanding.
///
/// One of these per resource kind, so the leak report can name what leaked.
///
/// Each entry carries the LABEL it was created with, which is what turns a leak report from
/// a count nobody can chase into a line a reader can grep for.
class TrackedResources
{
	public const String cUnlabelled = "(unlabelled)";

	private String mName = new .() ~ delete _;
	private List<Object> mLive = new .() ~ delete _;
	/// Aligned with mLive, and OWNED.
	private List<String> mLabels = new .() ~ DeleteContainerAndItems!(_);

	public this(StringView name) => mName.Set(name);

	public StringView Name => mName;
	public int Count => mLive.Count;

	/// The creation label of the entry at `index`, for the leak report.
	public StringView LabelAt(int index) => mLabels[index];

	public void Add(Object resource, StringView label = cUnlabelled)
	{
		if (resource == null)
			return;
		mLive.Add(resource);
		mLabels.Add(new String(label.IsEmpty ? cUnlabelled : label));
	}

	/// The label a tracked resource was created with, or nothing when it is not tracked.
	public bool TryGetLabel(Object resource, String outLabel)
	{
		for (int i < mLive.Count)
		{
			if (mLive[i] === resource)
			{
				outLabel.Set(mLabels[i]);
				return true;
			}
		}
		return false;
	}

	/// Removes it, reporting whether it was actually there. FALSE means a double destroy,
	/// or an object from another device.
	public bool Remove(Object resource)
	{
		for (int i < mLive.Count)
		{
			if (mLive[i] === resource)
			{
				mLive.RemoveAt(i);
				delete mLabels[i];
				mLabels.RemoveAt(i);
				return true;
			}
		}
		return false;
	}

	public bool Contains(Object resource)
	{
		for (let live in mLive)
		{
			if (live === resource)
				return true;
		}
		return false;
	}
}
