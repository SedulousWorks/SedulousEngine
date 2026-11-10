using System;
using System.Collections;
using Sedulous.Net;

namespace Sedulous.Editor.ProjectManager.Tests;

/// A loopback HTTP server for the tests, pumped on the test's thread: it answers each connection
/// once with the file its path names (200, the bytes) or a 404, then closes.
class LoopbackFiles
{
	private class File
	{
		public String Path = new .() ~ delete _;
		public List<uint8> Body = new .() ~ delete _;
	}

	private class Connection
	{
		public TcpSocket Socket ~ delete _;
		public String Request = new .() ~ delete _;
		public List<uint8> Reply = new .() ~ delete _;
		public int Sent = 0;
	}

	private TcpListener mListener = new .(0, true) ~ delete _;
	private List<File> mFiles = new .() ~ DeleteContainerAndItems!(_);
	private List<Connection> mConnections = new .() ~ DeleteContainerAndItems!(_);

	public uint16 Port => mListener.BoundPort;

	/// The URL `path` is served at ("/samples.json").
	public void Url(StringView path, String outUrl)
	{
		outUrl.AppendF("http://127.0.0.1:{}{}", Port, path);
	}

	public void Serve(StringView path, Span<uint8> body)
	{
		let file = new File();
		file.Path.Set(path);
		file.Body.AddRange(body);
		mFiles.Add(file);
	}

	public void Serve(StringView path, StringView text) => Serve(path, Span<uint8>((uint8*)text.Ptr, text.Length));

	public void Pump()
	{
		for (var socket = mListener.Accept(); socket != null; socket = mListener.Accept())
		{
			let c = new Connection();
			c.Socket = socket;
			mConnections.Add(c);
		}
		uint8[4096] buffer = ?;
		for (let c in mConnections)
		{
			if (c.Socket == null)
				continue;
			for (var n = c.Socket.Receive(.(&buffer[0], buffer.Count)); n > 0; n = c.Socket.Receive(.(&buffer[0], buffer.Count)))
				c.Request.Append(StringView((char8*)&buffer[0], (int)n));
			if (c.Reply.IsEmpty && c.Request.Contains("\r\n\r\n"))
				Answer(c);
			while (c.Sent < c.Reply.Count)
			{
				let n = c.Socket.Send(.(c.Reply.Ptr + c.Sent, c.Reply.Count - c.Sent));
				if (n <= 0)
					break;
				c.Sent += (int)n;
			}
			if (!c.Reply.IsEmpty && (c.Sent == c.Reply.Count))
				DeleteAndNullify!(c.Socket); // closed: the body is all there
		}
	}

	private void Answer(Connection c)
	{
		// "GET /path HTTP/1.1": the path between the first two spaces.
		StringView line = c.Request;
		int start = 0;
		while ((start < line.Length) && (line[start] != ' '))
			start++;
		int end = start + 1;
		while ((end < line.Length) && (line[end] != ' '))
			end++;
		let path = (start < line.Length) ? StringView(line, start + 1, end - start - 1) : StringView();
		File found = null;
		for (let f in mFiles)
		{
			if (f.Path == path)
				found = f;
		}
		let head = scope String();
		if (found != null)
			head.AppendF("HTTP/1.1 200 OK\r\nContent-Length: {}\r\nConnection: close\r\n\r\n", found.Body.Count);
		else
			head.Append("HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
		c.Reply.AddRange(Span<uint8>((uint8*)head.Ptr, head.Length));
		if (found != null)
			c.Reply.AddRange(found.Body);
	}
}
