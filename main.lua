FPS = 30 -- frames per second, the general speed of the program
WINDOWWIDTH = 640 -- size of window's width in pixels
WINDOWHEIGHT = 480 -- size of windows' height in pixels
REVEALSPEED = 8 -- speed boxes' sliding reveals and covers
BOXSIZE = 40 -- size of box height & width in pixels
GAPSIZE = 10 -- size of gap between boxes in pixels
BOARDWIDTH = 10 -- number of columns of icons
BOARDHEIGHT = 7 -- number of rows of icons
assert((BOARDWIDTH * BOARDHEIGHT) % 2 == 0, 'Board needs to have an even number of boxes for pairs of matches.')

XMARGIN = math.floor((WINDOWWIDTH - (BOARDWIDTH * (BOXSIZE + GAPSIZE))) / 2)
YMARGIN = math.floor((WINDOWHEIGHT - (BOARDHEIGHT * (BOXSIZE + GAPSIZE))) / 2)

--            R    G    B
GRAY     = {.39, .39, .39}--(100, 100, 100)
NAVYBLUE = {.23, .23, .39}--( 60,  60, 100)
WHITE    = {1. ,  1.,  1.}--(255, 255, 255)
RED      = {1. ,   0,   0}--(255,   0,   0)
GREEN    = {0  ,  1.,   0}--(  0, 255,   0)
BLUE     = {0  ,   0,  1.}--(  0,   0, 255)
YELLOW   = {1. ,  1.,   0}--(255, 255,   0)
ORANGE   = {1. , 0.5,  0.}--(255, 128,   0)
PURPLE   = {1. ,   0,  1.}--(255,   0, 255)
CYAN     = {0  ,  1.,  1.}--(  0, 255, 255)


BGCOLOR = NAVYBLUE
LIGHTBGCOLOR = GRAY
BOXCOLOR = WHITE
HIGHLIGHTCOLOR = BLUE

DONUT = 'donut'
SQUARE = 'square'
DIAMOND = 'diamond'
LINES = 'lines'
OVAL = 'oval'

ALLCOLORS = {RED, GREEN, BLUE, YELLOW, ORANGE, PURPLE, CYAN}
ALLSHAPES = {DONUT, SQUARE, DIAMOND, LINES, OVAL}

assert(#ALLCOLORS * #ALLSHAPES * 2 >= BOARDWIDTH * BOARDHEIGHT, 'Board is too big for the number of shapes/colors defined.')

function love.load()
    mainBoard = getRandomizedBoard()
    revealedBoxes = gener