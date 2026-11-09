local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Polar Aurora: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#0b1016',
    fg = hsluv '#cfdae2',
    rose = hsluv '#ee7189',
    leaf = hsluv '#55dfa2',
    wood = hsluv '#e5c568',
    water = hsluv '#5fa5e8',
    blossom = hsluv '#a888ef',
    sky = hsluv '#47d3d6',
  }, 'dark'),
}
