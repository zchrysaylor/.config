local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Ember Hollow: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#171210',
    fg = hsluv '#e0cfc4',
    rose = hsluv '#e06c4f',
    leaf = hsluv '#a3b06a',
    wood = hsluv '#e8a75a',
    water = hsluv '#8e9fb3',
    blossom = hsluv '#c98a8e',
    sky = hsluv '#8fb0a2',
  }, 'dark'),
}
