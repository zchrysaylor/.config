local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Buttercream Diner: original sRGB background, foreground, and six ANSI accents.
  light = util.palette_extend({
    bg = hsluv '#fbf3dd',
    fg = hsluv '#4d3f33',
    rose = hsluv '#c8432f',
    leaf = hsluv '#5c8a3c',
    wood = hsluv '#ac7c14',
    water = hsluv '#3f74a8',
    blossom = hsluv '#a2538c',
    sky = hsluv '#38857a',
  }, 'light'),
}
