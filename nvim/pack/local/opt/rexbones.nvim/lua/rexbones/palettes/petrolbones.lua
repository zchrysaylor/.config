local hsluv = require('lush').hsluv
local util = require 'zenbones.util'

-- Petrol Lagoon's original sRGB background, foreground, and six ANSI accents.
return {
  dark = util.palette_extend({
    bg = hsluv '#0c1618',
    fg = hsluv '#c2d8d8',
    rose = hsluv '#e0736e',
    leaf = hsluv '#6cc48e',
    wood = hsluv '#d1b366',
    water = hsluv '#5b9fc4',
    blossom = hsluv '#9d8ccc',
    sky = hsluv '#3fc4b7',
  }, 'dark'),
}
