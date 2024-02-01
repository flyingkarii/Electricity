-- NOTES TO OTHER DEVS:
-- Always use SingleSync, no matter what.
-- Events should only ever be listened to from one place inside a queue.
opt casing = "snake_case"
opt server_output = "remotes/server.luau"
opt client_output = "remotes/client.luau"
opt write_checks = false

-- Defined Types
type void = struct {} -- no existing alternative as of now

type UnitPacket = struct {
	id: u32,
	x: i16,
	y: i16,
	z: i16,
	rotation: u8
}

-- Remotes

-- * Client
event try_wire = {
	from: Client,
	type: Reliable,
	call: SingleSync,
	data: i16
}

-- * Server