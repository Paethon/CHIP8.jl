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

function render_pixels(w::Window)
  SDL.UpdateTexture(w.framebuffer,
                    C_NULL,
                    w.pixels,
                    Int32(w.xsize*sizeof(eltype(w.pixels))))
  
  SDL.RenderClear(w.renderer)
  SDL.RenderCopy(w.renderer, w.framebuffer , C_NULL, C_NULL)
  SDL.RenderPresent(w.renderer)
end

function render_chip8_disp_buffer(c::Chip8, w::Window)
  white = 0xFFFFFF
  black = 0x000000
  framex = framey = 0

  for x in 1:size(c.disp,1)
    for dx in 1:5
      for y in 1:size(c.disp,2)
        for dy in 1:5
          framey += 1
        end
      end
      framey = 0
    end
    framex = 0
  end
end

destroy(w::Window) = SDL.DestroyWindow(w.win)
