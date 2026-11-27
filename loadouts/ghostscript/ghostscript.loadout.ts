// ghostscript: ImageMagick shells out to `gs` to rasterize PDFs, which snacks.nvim's image preview needs.
import { program, withBrew, withOmarchy } from "loadout";

export const ghostscript = program("ghostscript", { canBeInstalled: [withBrew, withOmarchy] });
