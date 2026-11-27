// Docker comes with Omarchy; this is the machine's access to it.
import { script } from "loadout";
import { lazydocker } from "../lazydocker/lazydocker.loadout.ts";

// docker group membership: root-equivalent, so opted into per machine.
export const omarchySudolessDocker = script("omarchy-sudoless-docker", {
  description: "sudoless Docker (user in the docker group)",
  module: () => import("./.loadout/omarchy-sudoless-docker.ts"),
  needsSudo: true,
  runAfter: [lazydocker],
});
