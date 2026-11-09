local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Neon Arcade: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#0d0d15',
    fg = hsluv '#d8dcf0',
    rose = hsluv '#ff5370',
    leaf = hsluv '#3ddc97',
    wood = hsluv '#ffd166',
    water = hsluv '#4f9cff',
    blossom = hsluv '#c774ff',
    sky = hsluv '#2fd6e0',
  }, 'dark'),
}
