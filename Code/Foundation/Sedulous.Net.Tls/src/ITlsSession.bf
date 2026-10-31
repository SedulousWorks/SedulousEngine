using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Net.Tls;

enum TlsState : uint8
{
	/// Keys not yet agreed: plaintext written now waits for Open.
	Handshaking,
	/// Data flows both ways.
	Open,
	/// The peer closed (close_notify), or Close was called.
	Closed,
	/// It failed; Failure says why.
	Failed,
}

/// One connection's TLS, either end, over whatever carries its bytes.
///
/// A session is a byte engine that never touches a socket (a "memory BIO"): the caller hands it
/// what arrived from the peer, takes what it must send, and reads and writes plaintext. So any
/// transport carries it (a TcpSocket, a test's in-memory pipe), two sessions wired together run a
/// whole handshake headlessly, and a backend is only the crypto. Single-threaded.
interface ITlsSession
{
	/// Bytes that arrived from the peer; the handshake moves on with them. An error when the
	/// session has failed (Failure says why).
	Result<void, ErrorCode> Receive(Span<uint8> fromPeer);
	/// Appends what must go to the peer to `toPeer`; answers how many bytes.
	int TakeOutgoing(List<uint8> toPeer);
	/// Up to `plaintext.Length` bytes the peer sent, decrypted; nought when none are ready.
	int Read(Span<uint8> plaintext);
	/// Plaintext to send: encrypted into the outgoing bytes once Open (held until then).
	Result<void, ErrorCode> Write(Span<uint8> plaintext);
	/// Tells the peer the connection ends (close_notify); the session is Closed after.
	void Close();

	TlsState State { get; }
	/// Why it failed, said for a person ("the certificate is not for example.com"); empty
	/// otherwise.
	StringView Failure { get; }
	/// The protocol ALPN agreed on; empty when none was.
	StringView AlpnChosen { get; }
	/// The TLS version agreed on (valid once Open).
	TlsVersion Version { get; }
}

/// Makes sessions; the caller owns each. A session made from a configuration that cannot work (a
/// key that does not parse, no roots to trust) comes back Failed, saying why, rather than null.
/// One thread at a time.
interface ITlsBackend
{
	ITlsSession CreateClient(TlsClientConfig config);
	ITlsSession CreateServer(TlsServerConfig config);
	StringView Name { get; }
}
