module CHIP8

using StaticArrays

export Chip8, parseopcode

const memsize = 4096            # 4KiB of memory
const program_start = 0x200     # Starting address of programs in memory
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
  mem::SVector{memsize, UInt8}  # Main memory
  disp::SMatrix{32, 64, Bool}   # Display buffer

  # Stack
  stack::Vector{UInt16}
end

Chip8() = Chip8(zeros(SVector{16, UInt8}),        # General purpose registers
                0, 0, 0,                          # Address, timer, sound register
                program_start,                    # Program counter
                zeros(SVector{memsize, UInt8}),   # Main memory
                zeros(SMatrix{64, 32, Bool}),     # Display buffer
                Vector{UInt16}(),                 # Stack
                )

# Define our instructions

struct Instruction
  asm::String
  opcode::String
  description::String
end

instructions = [
  Instruction("CLS", "00E0", "Clear Screen")
  Instruction("RET", "00EE", "Return from subroutine")
  Instruction("SYS addr", "0nnn", "Call system subroutine")
  Instruction("JP addr", "1nnn", "Jump to address")
  Instruction("CALL addr", "2nnn", "Call subroutine at address")
  Instruction("SE Vx, val", "3xkk", "Jump over next instruction if (Vx == val)")
  Instruction("SNE Vx, val", "4xkk", "Jump over next instruction if (Vx != val)")
  Instruction("SE Vx, Vy", "5xy0", "Jump over next instruction if (Vx == Vy)")
  Instruction("LD Vx, val", "6xkk", "Vx = val")
  Instruction("ADD Vx, val", "7xkk", "Vx = Vx + val")
  Instruction("LD Vx, Vy", "8xy0", "Vx = Vy")
  Instruction("OR Vx, Vy", "8xy1", "Vx = Vx or Vy")
  Instruction("AND Vx, Vy", "8xy2", "Vx = Vx and Vy")
  Instruction("XOR Vx, Vy", "8xy3", "Vx = Vx xor Vy")
  Instruction("ADD Vx, Vy", "8xy4", "Vx = Vx + Vy")
  Instruction("SUB Vx, Vy", "8xy5", "Vx = Vx - Vy")
  Instruction("SHR Vx {, Vy}", "8xy6", "Vx = Vx >> 1")
  Instruction("SUBN Vx, Vy", "8xy7", "Vx = Vy - Vx")
  Instruction("SHL Vx {, Vy}", "8xyE", "Vx = Vx << 1")
  Instruction("SNE Vx, Vy", "9xy0", "Jump over next instruction if (Vx != Vy)")
  Instruction("LD I, addr", "Annn", "I = addr")
  Instruction("JP V0, addr", "Bnnn", "Jump to address: V0 + addr")
  Instruction("RND Vx, val", "Cxkk", "Vx = rand() and val")
  Instruction("DRW Vx, Vy, val", "Dxyn", "Display val rows of sprite at position Vx, Vy")
  Instruction("SKP Vx", "Ex9E", "Skip next instruction if key Vx is pressed")
  Instruction("SKNP Vx", "ExA1", "Skip next instruction if key Vx is not pressed")
  Instruction("LD Vx, DT", "Fx07", "Vx = DT")
  Instruction("LD Vx, K", "Fx0A", "Wait for key press and put pressed key into Vx")
  Instruction("LD DT, Vx", "Fx15", "DT = Vx")
  Instruction("LD ST, Vx", "Fx18", "ST = Vx")
  Instruction("ADD I, Vx", "Fx1E", "I = I + Vx")
  Instruction("LD F, Vx", "Fx29", "I = address to sprite representing number in Vx")
  Instruction("LD B, Vx", "Fx33", "BCD of Vx is saved to I, I+1, and I+2")
  Instruction("LD [I], Vx", "Fx55", "V0 to Vx are safed to memory beginning at I")
  Instruction("LD Vx, [I]", "Fx65", "V0 to Vx are read from memory beginning at I")
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
