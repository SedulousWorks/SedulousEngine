using System;
using System.Collections;

namespace Sedulous.Integration.ShaderBlocks;

/// A block's member as DXC compiled it: its name and byte offset.
class SpirvMember
{
	public String Name = new .() ~ delete _;
	public uint32 Offset = 0;
	public bool HasOffset = false;
}

/// The debug names and the member offsets of every named struct type in a SPIR-V module. Only
/// OpName (5), OpMemberName (6) and OpMemberDecorate (72) with Offset (35) are read; the
/// annotations all precede the first function, so the walk stops there (OpFunction, 54).
class SpirvBlocks
{
	private class TypeMembers
	{
		public uint32 Type;
		public List<SpirvMember> Members = new .() ~ DeleteContainerAndItems!(_);
	}

	private List<(uint32 Id, String Name)> mTypeNames = new .() ~ { for (let t in _) delete t.Name; delete _; };
	private List<TypeMembers> mMembers = new .() ~ DeleteContainerAndItems!(_);

	public this(Span<uint8> blob)
	{
		let count = blob.Length / 4;
		if (count < 5)
			return;
		uint32 Word(int at) => *(uint32*)&blob[at * 4];
		if (Word(0) != 0x07230203)
			return;
		int i = 5;
		while (i < count)
		{
			let head = Word(i);
			let op = head & 0xFFFF;
			let length = (int)(head >> 16);
			if ((length == 0) || (i + length > count) || (op == 54))
				break;
			// A literal string from word `at`, nul terminated within the instruction.
			void Text(int at, String outText)
			{
				let start = (char8*)&blob[at * 4];
				let limit = (i + length - at) * 4;
				int n = 0;
				while ((n < limit) && (start[n] != '\0'))
					n++;
				outText.Append(start, n);
			}
			if ((op == 5) && (length >= 3))
			{
				let name = new String();
				Text(i + 2, name);
				mTypeNames.Add((Word(i + 1), name));
			}
			else if ((op == 6) && (length >= 4))
				Text(i + 3, Member(Word(i + 1), Word(i + 2)).Name);
			else if ((op == 72) && (length >= 5) && (Word(i + 3) == 35))
			{
				let member = Member(Word(i + 1), Word(i + 2));
				member.Offset = Word(i + 4);
				member.HasOffset = true;
			}
			i += length;
		}
	}

	/// The members of the struct named `name` (DXC's names: `type.<cbuffer>`,
	/// `type.ConstantBuffer.<struct>`, or a structured buffer element's own name); null if absent.
	public List<SpirvMember> Find(StringView name)
	{
		for (let type in mTypeNames)
		{
			if (type.Name != name)
				continue;
			for (let members in mMembers)
			{
				if (members.Type == type.Id)
					return members.Members;
			}
		}
		return null;
	}

	private SpirvMember Member(uint32 type, uint32 index)
	{
		TypeMembers found = null;
		for (let members in mMembers)
		{
			if (members.Type == type)
			{
				found = members;
				break;
			}
		}
		if (found == null)
		{
			found = new TypeMembers();
			found.Type = type;
			mMembers.Add(found);
		}
		while (found.Members.Count <= (int)index)
			found.Members.Add(new SpirvMember());
		return found.Members[(int)index];
	}
}
