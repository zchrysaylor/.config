local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Static Noir: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#0a0a0a',
    fg = hsluv '#ededed',
    rose = hsluv '#ff4d42',
    leaf = hsluv '#9fd08a',
    wood = hsluv '#e6c15c',
    water = hsluv '#7fb2e8',
    blossom = hsluv '#d093d0',
    sky = hsluv '#74cfd1',
  }, 'dark'),
}
