namespace Sedulous.Scene.Resource;

/// Which instance an entity belongs to, and where in its member list.
///
/// The state is BORROWED from the scene: valid until the instance is torn down, which is
/// exactly as long as the question was worth asking.
struct PrefabMemberInfo
{
	public PrefabInstanceState State = null;
	public int MemberIndex = 0;

	public this() {}
	public this(PrefabInstanceState state, int memberIndex)
	{
		State = state;
		MemberIndex = memberIndex;
	}
}
