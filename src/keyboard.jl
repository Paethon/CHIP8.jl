using SimpleDirectMediaLayer
const SDL = SimpleDirectMediaLayer


chip82key = Dict(0x01 => SDL.SCANCODE_1, 0x02 => SDL.SCANCODE_2, 0x03 => SDL.SCANCODE_3,
                 0x0C => SDL.SCANCODE_4, 0x04 => SDL.SCANCODE_Q, 0x05 => SDL.SCANCODE_W,
                 0x06 => SDL.SCANCODE_E, 0x0D => SDL.SCANCODE_R, 0x07 => SDL.SCANCODE_A,
                 0x08 => SDL.SCANCODE_S, 0x09 => SDL.SCANCODE_D, 0x0E => SDL.SCANCODE_F,
                 0x0A => SDL.SCANCODE_Z, 0x00 => SDL.SCANCODE_X, 0x0B => SDL.SCANCODE_C,
                 0x0F => SDL.SCANCODE_V)

key2chip8 = Dict(b => a for (a,b) in chip82key)
