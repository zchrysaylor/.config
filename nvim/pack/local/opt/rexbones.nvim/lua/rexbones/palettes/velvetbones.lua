local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Velvet Dusk: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#171122',
    fg = hsluv '#d6cbe6',
    rose = hsluv '#e07396',
    leaf = hsluv '#83bb8d',
    wood = hsluv '#dcae76',
    water = hsluv '#7f95dc',
    blossom = hsluv '#b98ae0',
    sky = hsluv '#7fb8c4',
  }, 'dark'),
}
