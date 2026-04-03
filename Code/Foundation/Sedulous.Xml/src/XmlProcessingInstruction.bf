using System;

namespace Sedulous.Xml;

/// <summary>
/// Represents a processing instruction node (<?target data?>).
/// </summary>
class XmlProcessingInstruction : XmlNode
{
	private String mTarget = new .() ~ delete _;
	private String mData = new .() ~ delete _;

	public this() : base(.ProcessingInstruction)
	{
	}

	public this(StringView target, StringView data) : base(.ProcessingInstruction)
	{
		mTarget.Set(target);
		mData.Set(data);
	}

	/// <summary>
	/// Gets the processing instruction target.
	/// </summary>
	public StringView Target => mTarget;

	/// <summary>
	/// Gets the processing instruction data.
	/// </summary>
	public StringView Data => mData;

	/// <summary>
	/// Sets the processing instruction target.
	/// Note: The target cannot be "xml" (case-insensitive).
	/// </summary>
	public void SetTarget(StringView target)
	{
		mTarget.Set(target);
	}

	/// <summary>
	/// Sets the processing instruction data.
	/// Note: The data cannot contain "?>".
	/// </summary>
	public void SetData(StringView data)
	{
		mData.Set(data);
	}

	public override void GetInnerText(String output)
	{
		// Processing instructions do not contribute to inner text
	}

	public override void GetOuterXml(String output)
	{
		output.Append("<?");
		output.Append(mTarget);
		if (!mData.IsEmpty)
		{
			output.Append(' ');
			output.Append(mData);
		}
		output.Append("?>");
	}
}
