--[[

This file contains serializerse to allow components to be converted into a
format that is smaller and can be sent over the network

]]

type Serializer<Original, Serialized> = {
	serialize: (Original) -> Serialized,
	deserialize: (Serialized) -> Original,
}

return {} :: { [string]: Serializer<any, any> }
