local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Phosphor Archive: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#0a120c',
    fg = hsluv '#a8e5a8',
    rose = hsluv '#cf9a5f',
    leaf = hsluv '#4fd24f',
    wood = hsluv '#a5dc5f',
    water = hsluv '#55b884',
    blossom = hsluv '#8fce74',
    sky = hsluv '#5fdcb0',
  }, 'dark'),
}
