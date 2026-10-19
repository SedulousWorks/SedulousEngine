using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;

namespace Sedulous.Content.Tests;

/// A mount that passes everything to another and counts the reads reaching its files.
class CountingMount : IFileSystem, IEnumerableFileSystem
{
	private class Counted : IStream
	{
		private IStream mInner ~ delete _;
		private CountingMount mOwner;

		public this(IStream inner, CountingMount owner)
		{
			mInner = inner;
			mOwner = owner;
		}

		public override bool IsValid => mInner.IsValid;

		public override int Read(Span<uint8> destination)
		{
			mOwner.Reads++;
			return mInner.Read(destination);
		}

		public override int Write(Span<uint8> source) => mInner.Write(source);
		public override int64 Seek(int64 offset, SeekOrigin origin) => mInner.Seek(offset, origin);
		public override int64 Tell() => mInner.Tell();
		public override int64 Size() => mInner.Size();
	}

	private NativeFileSystem mInner;

	public int Reads;

	public this(NativeFileSystem inner)
	{
		mInner = inner;
	}

	public IStream Open(StringView path, FileMode mode)
	{
		let stream = mInner.Open(path, mode);
		return (stream != null) ? new Counted(stream, this) : null;
	}

	public bool Exists(StringView path) => mInner.Exists(path);

	public Result<void, ErrorCode> Enumerate(StringView folder, List<DirEntry> outEntries) => mInner.Enumerate(folder, outEntries);
}
