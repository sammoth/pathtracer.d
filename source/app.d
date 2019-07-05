import std.stdio;
import std.conv;
import std.datetime;
import std.concurrency;
import derelict.sdl2.sdl;
import renderer;

const int RENDER_THREADS = 4;
const int SCREEN_WIDTH = 2000;
const int SCREEN_HEIGHT = 1000;

SDL_Window* window = null;
SDL_Renderer* sdl_renderer = null;
SDL_Texture* texture = null;

bool init() {
  DerelictSDL2.load();
  if (SDL_Init(SDL_INIT_VIDEO) < 0) {
    writeln(stderr, "could not initialize sdl2: %s\n", SDL_GetError());
    return false;
  }
  window = SDL_CreateWindow("pathtracer",
			    SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
			    SCREEN_WIDTH, SCREEN_HEIGHT,
			    SDL_WINDOW_SHOWN
			    );
  if (window == null) {
    writeln(stderr, "could not create window: %s\n", SDL_GetError());
    return false;
  }

  sdl_renderer = SDL_CreateRenderer(window, -1,
				SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
  if (sdl_renderer == null) {
    writeln(stderr, "could not create renderer: %s\n", SDL_GetError());
    return false;
  }

  texture = SDL_CreateTexture(sdl_renderer, SDL_PIXELFORMAT_ARGB8888,
			      SDL_TEXTUREACCESS_STATIC, SCREEN_WIDTH, SCREEN_HEIGHT);
  if (texture == null) {
    writeln(stderr, "could not create texture: %s\n", SDL_GetError());
    return false;
  }

  return true;
}

void close() {
  SDL_DestroyTexture(texture);
  texture = null;
  SDL_DestroyRenderer(sdl_renderer);
  sdl_renderer = null;
  SDL_DestroyWindow(window);
  window = null;
  SDL_Quit();
}

void render_thread(Tid tid)
{
  shared uint[] * pixels;
  int thread_index;
  receive((int t) { thread_index = t; });
  receive((shared(shared(uint)[])* p) { pixels = p; });

  int min_row = thread_index*(SCREEN_HEIGHT/RENDER_THREADS);
  int max_row = (thread_index+1)*(SCREEN_HEIGHT/RENDER_THREADS);
  if (thread_index == RENDER_THREADS-1) { max_row = SCREEN_HEIGHT; }

  for (int y = min_row; y < max_row; y++)
    for (int x = 0; x < SCREEN_WIDTH; x++)
      {
	{
	  if (x % 5 == 0 && receiveTimeout(-1.msecs, (bool){}))
	    {
	      send(tid, true);
	      return;
	    }

	  float unit_x = 1.0 * x / SCREEN_WIDTH;
	  float unit_y = 1.0 * y / SCREEN_HEIGHT;
	  renderer.colour_pixel(&(*pixels)[y * SCREEN_WIDTH + x], unit_x, unit_y);
	}
      }

  send(tid, true);
}

void main()
{
  init();

  Tid[RENDER_THREADS] tids;
  shared uint[] pixels = new uint[SCREEN_WIDTH*SCREEN_HEIGHT];
  int used_rows = 0;

  for (int i = 0; i < RENDER_THREADS; i++) {
    tids[i] = spawn(&render_thread, thisTid);
    send(tids[i], i);
    send(tids[i], &pixels);
  }

  bool running = true;
  SDL_Event event;

  while (running)
    {
      while(SDL_PollEvent(&event))
        {
      	  if((SDL_QUIT == event.type) ||
      	     (SDL_KEYDOWN == event.type && SDL_SCANCODE_Q == event.key.keysym.scancode))
            {
      	      running = false;
	      for (int i = 0; i < RENDER_THREADS; i++) {
		send(tids[i], true);
		receiveOnly!(bool);
	      }
      	      break;
            }
        }

      SDL_UpdateTexture(texture, null, cast(void*)pixels, cast(int)(SCREEN_WIDTH*uint.sizeof));
      SDL_RenderClear(sdl_renderer);
      SDL_RenderCopy(sdl_renderer, texture, null, null);
      SDL_RenderPresent(sdl_renderer);
    }

  close();
}
