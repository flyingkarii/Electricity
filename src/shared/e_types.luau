export type Base = {
	e_type: string,
}

export type Light = {
	brightness: number,
	required_charge: number,
} & Base

export type Generator = {
	output: number,
} & Base

export type Switch = {
	required_charge: number,
} & Base

return nil
