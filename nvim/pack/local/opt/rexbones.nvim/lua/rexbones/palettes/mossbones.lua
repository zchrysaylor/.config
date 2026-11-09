local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Moss Cathedral: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#0f1710',
    fg = hsluv '#c6d5c2',
    rose = hsluv '#d4756b',
    leaf = hsluv '#74bd74',
    wood = hsluv '#cdb35e',
    water = hsluv '#6d9cba',
    blossom = hsluv '#a488bd',
    sky = hsluv '#6bb8a0',
  }, 'dark'),
}
