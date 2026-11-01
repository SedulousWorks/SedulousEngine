using System;
using System.Collections;
using Sedulous.Core;
using mbedtls_Beef;

namespace Sedulous.Net.Tls.MbedTLS;

#if !BF_PLATFORM_WASM
/// One connection's TLS through Mbed TLS, over the wrapper's in-memory buffers.
class MbedTlsSession : ITlsSession
{
	/// OWNED: the wrapper's session, freed with this.
	private void* mSession = null;
	private TlsState mState = .Handshaking;
	private String mFailure = new .() ~ delete _;
	private String mAlpn = new .() ~ delete _;
	/// Plaintext written before Open.
	private List<uint8> mPending = new .() ~ delete _;

	public ~this()
	{
		if (mSession != null)
			mbedtlsc_session_destroy(mSession);
	}

	public TlsState State => mState;
	public StringView Failure => mFailure;
	public StringView AlpnChosen => mAlpn;
	public TlsVersion Version => ((mSession != null) && (mbedtlsc_session_version(mSession) == 3)) ? .Tls13 : .Tls12;

	/// Mbed TLS's words for an error code ("SSL - ..."), for a failure's message.
	public static void ErrorText(int32 code, String outText)
	{
		if (code == MBEDTLSC_NOT_STARTED)
		{
			outText.Append("the crypto library did not start");
			return;
		}
		char8[200] buffer = default;
		mbedtlsc_strerror(code, &buffer[0], (uint)buffer.Count);
		outText.Append(StringView(&buffer[0]));
	}

	private void Fail(StringView what, int32 code)
	{
		mState = .Failed;
		mFailure.Set(what);
		mFailure.Append(": ");
		ErrorText(code, mFailure);
	}

	private void Fail(StringView why)
	{
		mState = .Failed;
		mFailure.Set(why);
	}

	private static int32 ToMbed(TlsVersion version) => (version == .Tls13) ? 3 : 2;

	private bool Common(int32 server, TlsVersion minimum, TlsVersion maximum, List<String> alpn)
	{
		let names = scope List<char8*>();
		for (let protocol in alpn)
			names.Add(protocol.CStr());
		int32 code = 0;
		mSession = mbedtlsc_session_create(server, ToMbed(minimum), ToMbed(maximum), names.Ptr, (int32)names.Count, &code);
		if (mSession == null)
		{
			Fail("the TLS session could not be made: out of memory");
			return false;
		}
		if (code == MBEDTLSC_NOT_STARTED)
		{
			Fail("the crypto library did not start");
			return false;
		}
		if (code != 0)
		{
			Fail("the TLS configuration could not be made", code);
			return false;
		}
		return true;
	}

	private bool Setup()
	{
		let code = mbedtlsc_session_setup(mSession);
		if (code != 0)
		{
			Fail("the TLS session could not be made", code);
			return false;
		}
		return true;
	}

	public void SetUpClient(TlsClientConfig config)
	{
		if (!Common(0, config.Minimum, config.Maximum, config.Alpn))
			return;
		if (config.Trust == .InsecureForTests)
			mbedtlsc_session_verify(mSession, 0);
		else
		{
			let rootsFrom = scope String();
			let system = scope TlsRoots();
			if (config.Trust == .System)
				TlsSystemRoots.Load(system, rootsFrom);
			let roots = (config.Trust == .System) ? system : config.Roots;
			// A bundle may hold a certificate this build cannot read: the rest still count.
			if (!roots.Pem.IsEmpty)
				mbedtlsc_session_add_roots_pem(mSession, (uint8*)roots.Pem.Ptr, (uint)roots.Pem.Length);
			for (let der in roots.Der)
				mbedtlsc_session_add_root_der(mSession, der.Ptr, (uint)der.Count);
			if (mbedtlsc_session_root_count(mSession) == 0)
			{
				if (config.Trust == .System)
					Fail(scope $"no trusted roots: the system's were not found ({rootsFrom})");
				else
					Fail("no trusted roots: none of the given certificates could be read");
				return;
			}
			mbedtlsc_session_verify(mSession, 1);
		}
		if (!Setup())
			return;
		if (config.ServerName.IsEmpty && (config.Trust != .InsecureForTests))
		{
			Fail("a client needs the server's name to check its certificate against");
			return;
		}
		if (!config.ServerName.IsEmpty)
		{
			let code = mbedtlsc_session_set_hostname(mSession, config.ServerName.CStr());
			if (code != 0)
			{
				Fail("the server name was refused", code);
				return;
			}
		}
		Advance(); // the ClientHello
	}

	public void SetUpServer(TlsServerConfig config)
	{
		if (!Common(1, config.Minimum, config.Maximum, config.Alpn))
			return;
		int32 stage = 0;
		let code = mbedtlsc_session_own_certificate(mSession, (uint8*)config.CertificateChainPem.Ptr,
			(uint)config.CertificateChainPem.Length, (uint8*)config.PrivateKeyPem.Ptr, (uint)config.PrivateKeyPem.Length, &stage);
		if (code != 0)
		{
			switch (stage)
			{
			case 0: Fail("the certificate chain could not be read", code);
			case 1: Fail("the private key could not be read", code);
			default: Fail("the certificate and key were refused", code);
			}
			return;
		}
		Setup(); // the server waits for the ClientHello
	}

	public Result<void, ErrorCode> Receive(Span<uint8> fromPeer)
	{
		if (mState == .Failed)
			return .Err(.Internal);
		if (!fromPeer.IsEmpty)
			mbedtlsc_session_receive(mSession, fromPeer.Ptr, (uint)fromPeer.Length);
		Advance();
		return (mState == .Failed) ? .Err(.Internal) : .Ok;
	}

	public int TakeOutgoing(List<uint8> toPeer)
	{
		if (mSession == null)
			return 0;
		let count = (int)mbedtlsc_session_outgoing(mSession);
		if (count == 0)
			return 0;
		let start = toPeer.Count;
		toPeer.GrowUninitialized(count);
		return (int)mbedtlsc_session_take_outgoing(mSession, &toPeer[start], (uint)count);
	}

	public int Read(Span<uint8> plaintext)
	{
		if ((mState != .Open) || plaintext.IsEmpty)
			return 0;
		int32 code = 0;
		let read = mbedtlsc_session_read(mSession, plaintext.Ptr, (uint)plaintext.Length, &code);
		if (read > 0)
			return read;
		if (code == MBEDTLSC_READ_CLOSED)
			mState = .Closed;
		else if (code != MBEDTLSC_READ_NONE)
			Fail("reading failed", code);
		return 0;
	}

	public Result<void, ErrorCode> Write(Span<uint8> plaintext)
	{
		if ((mState == .Failed) || (mState == .Closed))
			return .Err(.Internal);
		if (mState == .Handshaking)
		{
			mPending.AddRange(plaintext);
			return .Ok;
		}
		return WriteNow(plaintext);
	}

	public void Close()
	{
		if (mState == .Open)
			mbedtlsc_session_close_notify(mSession);
		if (mState != .Failed)
			mState = .Closed;
	}

	private Result<void, ErrorCode> WriteNow(Span<uint8> plaintext)
	{
		if (plaintext.IsEmpty)
			return .Ok;
		let code = mbedtlsc_session_write(mSession, plaintext.Ptr, (uint)plaintext.Length);
		if (code != 0)
		{
			Fail("writing failed", code);
			return .Err(.Internal);
		}
		return .Ok;
	}

	/// The handshake as far as the bytes so far take it; held plaintext goes once Open.
	private void Advance()
	{
		if (mState != .Handshaking)
			return;
		let step = mbedtlsc_session_handshake(mSession);
		if (step == MBEDTLSC_HANDSHAKE_WANTS)
			return;
		if (step == MBEDTLSC_HANDSHAKE_REFUSED)
		{
			char8[512] info = default;
			mbedtlsc_session_verify_info(mSession, &info[0], (uint)info.Count);
			// One reason a line from Mbed TLS: said on one line, joined by semicolons.
			let reasons = scope String(StringView(&info[0]));
			while (reasons.EndsWith('\n'))
				reasons.RemoveFromEnd(1);
			reasons.Replace('\n', ';');
			Fail(scope $"the server's certificate was refused: {reasons}");
			return;
		}
		if (step != MBEDTLSC_HANDSHAKE_DONE)
		{
			Fail("the handshake failed", step);
			return;
		}
		mState = .Open;
		let alpn = mbedtlsc_session_alpn(mSession);
		if (alpn != null)
			mAlpn.Set(StringView(alpn));
		if (!mPending.IsEmpty)
		{
			let held = scope List<uint8>();
			held.AddRange(mPending);
			mPending.Clear();
			WriteNow(held).IgnoreError();
		}
	}
}
#endif
