using System;

namespace Sedulous.Xml;

/// A processing instruction: a target and an opaque payload for whatever handles it.
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

	public StringView Target => mTarget;
	public StringView Data => mData;

	public void SetTarget(StringView target) => mTarget.Set(target);
	public void SetData(StringView data) => mData.Set(data);

	public override void GetInnerText(String output)
	{
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
