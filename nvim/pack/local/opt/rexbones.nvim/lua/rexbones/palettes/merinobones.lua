local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Merino Dark: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#0d1117',
    fg = hsluv '#e6edf3',
    rose = hsluv '#ff7b72',
    leaf = hsluv '#3fb950',
    wood = hsluv '#d29922',
    water = hsluv '#58a6ff',
    blossom = hsluv '#bc8cff',
    sky = hsluv '#39c5cf',
  }, 'dark'),
  -- Merino Light: original sRGB background, foreground, and six ANSI accents.
  light = util.palette_extend({
    bg = hsluv '#ffffff',
    fg = hsluv '#1f2328',
    rose = hsluv '#cf222e',
    leaf = hsluv '#116329',
    wood = hsluv '#9d5c00',
    water = hsluv '#0969da',
    blossom = hsluv '#8250df',
    sky = hsluv '#1b7c83',
  }, 'light'),
}
