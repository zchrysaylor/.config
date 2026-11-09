local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Porcelain Morning: original sRGB background, foreground, and six ANSI accents.
  light = util.palette_extend({
    bg = hsluv '#f7f9fa',
    fg = hsluv '#2e3a42',
    rose = hsluv '#c74e42',
    leaf = hsluv '#3d8a4e',
    wood = hsluv '#b07c22',
    water = hsluv '#2c6fbe',
    blossom = hsluv '#8455a8',
    sky = hsluv '#22808a',
  }, 'light'),
}
