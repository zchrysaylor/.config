local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

return {
  -- Cinder Peak: original sRGB background, foreground, and six ANSI accents.
  dark = util.palette_extend({
    bg = hsluv '#151011',
    fg = hsluv '#ddccc6',
    rose = hsluv '#f25c4a',
    leaf = hsluv '#97ad72',
    wood = hsluv '#f0a04f',
    water = hsluv '#9188c4',
    blossom = hsluv '#d47a94',
    sky = hsluv '#8fb2a8',
  }, 'dark'),
}
