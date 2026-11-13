// ghostscript: ImageMagick shells out to `gs` to rasterize PDFs, which snacks.nvim's image preview needs.
import { brew, omarchy, program } from "loadout";

export const ghostscript = program("ghostscript", { install: [brew, omarchy] });
