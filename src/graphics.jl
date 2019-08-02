using SimpleDirectMediaLayer

const SDL = SimpleDirectMediaLayer

struct Window
  win
  renderer
  framebuffer
  pixels
  xsize
  ysize
end

function SDL_create(xsize, ysize)
  win = SDL.CreateWindow("CHIP8.jl",
                         Int32(100),
                         Int32(100),
                         Int32(xsize),
                         Int32(ysize), 
                         UInt32(SDL.WINDOW_SHOWN))
  
  renderer = SDL.CreateRenderer(win,
                                Int32(-1),
                                UInt32(SDL.RENDERER_ACCELERATED | SDL.RENDERER_PRESENTVSYNC))
  
  framebuffer = framebuffer = SDL.CreateTexture(renderer,
                                                SDL.PIXELFORMAT_ARGB8888,
                                                Int32(SDL.TEXTUREACCESS_STREAMING),
                                                Int32(xsize),
                                                Int32(ysize))
  
  pixels = Matrix{UInt32}(undef, xsize, ysize)
  
  return Window(win, renderer, framebuffer, pixels, xsize, ysize)
end

"""
`_render_pixels(w::Window)`

Renders the content of the pixel buffer in w to the screen
"""
function _render_pixels(w::Window)
  SDL.UpdateTexture(w.framebuffer,
                    C_NULL,
                    w.pixels,
                    Int32(w.xsize*sizeof(eltype(w.pixels))))
  
  SDL.RenderClear(w.renderer)
  SDL.RenderCopy(w.renderer, w.framebuffer , C_NULL, C_NULL)
  SDL.RenderPresent(w.renderer)
end

"""
`render_chip8_disp_buffer(ch8::Chip8, w::Window; scale::Integer)`

Renders the content of the display buffer of ch8 to the window w

ch8::Chip8     ... The chip8 system to render from

w::Window      ... The window to render to

scale::Integer ... One pixel of the diplay buffer should be how many pixels
                   on the screen (if not specified is calculated using display 
                   buffer and screen size)
"""
function render_chip8_disp_buffer(ch8::Chip8, w::Window; scale::Integer = size(w.pixels, 1)÷size(ch8.disp, 1))
  white = 0xFFFFFF
  black = 0x000000

  for x in 0:size(ch8.disp,1)-1
    for y in 0:size(ch8.disp,2)-1
      w.pixels[x*scale+1:(x+1)*scale, y*scale+1:(y+1)*scale] .= ch8.disp[x+1, y+1] ? white : black
    end
  end

  _render_pixels(w)
end

destroy(w::Window) = SDL.DestroyWindow(w.win)
