local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Juniper Smoke: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#171b18',
    fg = hsluv '#ccd5cd',
    rose = hsluv '#d59090',
    leaf = hsluv '#99bd9b',
    wood = hsluv '#d3bb8b',
    water = hsluv '#8ea8c0',
    blossom = hsluv '#b39cbb',
    sky = hsluv '#92bab2',
  }, 'dark'),
}
