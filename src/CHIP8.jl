module CHIP8

using StaticArrays

include("sprites.jl")           # Defines sprites for all hex digits

export Chip8, parseopcode

const memsize = 4096            # 4KiB of memory
const program_start = 0x200 + 1 # Starting address of programs in memory (+1 because of Julia 1 indexing ...)
const disp_columns = 64         # Number of horizontal pixels
const disp_rows = 32            # Number of vertical pixels

"Holds the state of a CHIP8 system"
mutable struct Chip8
  # Registers
  V::SVector{16, UInt8}         # General purpose registers
  I::UInt16                     # Address register
  DT::UInt8                     # Timer register
  ST::UInt8                     # Sound register
  PC::UInt16                    # Program counter
  # Stack pointer is only needed if the stack is managed manually
  # PC::UInt16                  # Stack pointer
  
  # Memory
  mem::MVector{memsize, UInt8}  # Main memory
  disp::MMatrix{32, 64, Bool}   # Display buffer

  # Stack
  stack::Vector{UInt16}
end

Chip8() = Chip8(zeros(SVector{16, UInt8}),        # General purpose registers
                0, 0, 0,                          # Address, timer, sound register
                program_start,                    # Program counter
                zeros(MVector{memsize, UInt8}),   # Main memory
                zeros(MMatrix{64, 32, Bool}),     # Display buffer
                Vector{UInt16}(),                 # Stack
                )

# Define our instructions

struct Instruction
  asm::String
  opcode::String
  description::String
  f::Function
end

instructions = [
  Instruction("CLS", "00E0", "Clear Screen",
              function (c)
              c.disp .= 0
              end)
  Instruction("RET", "00EE", "Return from subroutine",
              function (c)
              c.PC = pop(c.stack)
              end)
  Instruction("SYS addr", "0nnn", "Call system subroutine",
              function (c, nnn)
              error("Tried to call system subroutine on address $nnn. Not possible in emulation!")
              end)
  Instruction("JP addr", "1nnn", "Jump to address",
              function (c, nnn)
              c.PC = nnn - 2    # -2 because the address is going to be advanced by 2 bytes later
              end)
  Instruction("CALL addr", "2nnn", "Call subroutine at address",
              function (c, nnn)
              push!(c.stack, c.PC)
              c.PC = nnn - 2
              end)
  Instruction("SE Vx, val", "3xkk", "Jump over next instruction if (Vx == val,)",
              function (c, x, kk)
              c.V[x] == kk && c.PC += 2
              end)
  Instruction("SNE Vx, val", "4xkk", "Jump over next instruction if (Vx != val)",
              function (c, x, kk)
              c.V[x] != kk && c.PC += 2
              end)
  Instruction("SE Vx, Vy", "5xy0", "Jump over next instruction if (Vx == Vy)",
              function (c, x, y)
              c.V[x] == c.V[y] && c.PC += 2
              end)
  Instruction("LD Vx, val", "6xkk", "Vx = val",
              function (c, x, kk)
              c.V[x] == kk
              end)
  Instruction("ADD Vx, val", "7xkk", "Vx = Vx + val",
              function (c, x, kk)
              c.V[x] += kk
              end)
  Instruction("LD Vx, Vy", "8xy0", "Vx = Vy",
              function (c, x, y)
              c.V[x] = c.V[y]
              end)
  Instruction("OR Vx, Vy", "8xy1", "Vx = Vx or Vy",
              function (c, x, y)
              c.V[x] = c.V[x] | c.V[y]
              end)
  Instruction("AND Vx, Vy", "8xy2", "Vx = Vx and Vy",
              function (c, x, y)
              c.V[x] = c.V[x] & c.V[y]
              end)
  Instruction("XOR Vx, Vy", "8xy3", "Vx = Vx xor Vy",
              function (c, x, y)
              c.V[x] = c.V[x] ⊻ c.V[y]
              end)
  Instruction("ADD Vx, Vy", "8xy4", "Vx = Vx + Vy",
              function (c, x, y)
              c.V[16] = (UInt(c.V[x]) + UInt(x.V[y])) > 255 # Set carry flag
              c.V[x] += c.V[y]
              end)
  Instruction("SUB Vx, Vy", "8xy5", "Vx = Vx - Vy",
              function (c, x, y)
              c.V[16] = c.V[x] > x.V[y] # Set carry flag
              c.V[x] -= c.V[y]
              end)
  Instruction("SHR Vx {, Vy}", "8xy6", "Vx = Vx >> 1",
              function (c, x, y)
              c.V[16] = c.V[x] & 0x01
              c.V[x] >>=  1
              end)
  Instruction("SUBN Vx, Vy", "8xy7", "Vx = Vy - Vx",
              function (c, x, y)
              c.V[16] = c.V[y] > c.V[x]
              c.V[x] = c.V[y] - c.V[x]
              end)
  Instruction("SHL Vx {, Vy}", "8xyE", "Vx = Vx << 1",
              function (c, x, y)
              c.V[16] = c.V[x] & 0x01 != 0x01
              c.V[x] <<= 1
              end)
  Instruction("SNE Vx, Vy", "9xy0", "Jump over next instruction if (Vx != Vy)",
              function (c, x, y)
              if c.V[x] != c.V[y]
              end)
  Instruction("LD I, addr", "Annn", "I = addr",
              function (c, nnn)
              c.I = nnn
              end)
  Instruction("JP V0, addr", "Bnnn", "Jump to address: V0 + addr",
              function (c, nnn)
              c.I = c.V[1] + nnn
              end)
  Instruction("RND Vx, kk", "Cxkk", "Vx = rand() and kk",
              function (c, x, kk)
              x.V[x] = rand(UInt8) & kk
              # Do we have to set V[16] here?
              end)
  Instruction("DRW Vx, Vy, n", "Dxyn", "Display n rows of sprite at position Vx, Vy",
              function (c, x, y, n)
              c.V[16] = 0
              for line in 1:n
              
              end
              end)
  Instruction("SKP Vx", "Ex9E", "Skip next instruction if key Vx is pressed",
              function (c, x)
              
              end)
  Instruction("SKNP Vx", "ExA1", "Skip next instruction if key Vx is not pressed",
              function (c, x)
              
              end)
  Instruction("LD Vx, DT", "Fx07", "Vx = DT",
              function (c, x)
              
              end)
  Instruction("LD Vx, K", "Fx0A", "Wait for key press and put pressed key into Vx",
              function (c, x)
              
              end)
  Instruction("LD DT, Vx", "Fx15", "DT = Vx",
              function (c, x)
              
              end)
  Instruction("LD ST, Vx", "Fx18", "ST = Vx",
              function (c, x)
              
              end)
  Instruction("ADD I, Vx", "Fx1E", "I = I + Vx",
              function (c, x)
              
              end)
  Instruction("LD F, Vx", "Fx29", "I = address to sprite representing number in Vx",
              function (c, x)
              
              end)
  Instruction("LD B, Vx", "Fx33", "BCD of Vx is saved to I, I+1, and I+2",
              function (c, x)
              
              end)
  Instruction("LD [I], Vx", "Fx55", "V0 to Vx are safed to memory beginning at I",
              function (c, x)
              
              end)
  Instruction("LD Vx, [I]", "Fx65", "V0 to Vx are read from memory beginning at I",
              function (c, x)
              
              end)
]

"Parses the opcode description and returns mask, pattern to match and mask, type and name of parameters"
function parseopcode(op::String)
  mask = 0x0000
  match = 0x0000
  parameters = Dict{Symbol, Int}()
  
  for c in op
    mask <<= 4
    match <<= 4
    if isxdigit(c)  # We have a valid hex digit 
      mask |= 0xF
      match |= parse(UInt8, c, base = 16)
    else            # We have something else (i.e. a parameter)
      parameters[Symbol(c)] = get(parameters, Symbol(c), 0) + 1
      # Shift mask and match one nibble to the left to set next hex digit
    end
  end

  # Convert number of occurences of parameter into correct type
  parameters = Dict(s => c < 3 ? UInt8 : UInt16 for (s,c) in parameters)
  
  return mask, match, parameters
end

end # module
