// Where the local LLM's pieces live (docs/local-llm.md), shared by llm-model,
// llama-server and bench.
const HOME = process.env.HOME!;
const DATA = process.env.XDG_DATA_HOME || `${HOME}/.local/share`;
const CONFIG = process.env.XDG_CONFIG_HOME || `${HOME}/.config`;

/** The GGUF models llm-model downloads. */
export const MODEL_DIR = `${DATA}/llm-models`;

/** model's path: a bare file name is one of MODEL_DIR's. */
export const modelPath = (model: string) => (model.includes("/") ? model : `${MODEL_DIR}/${model}`);

/** The user units llama-server writes. */
export const UNITS = `${CONFIG}/systemd/user`;
export const SERVER_UNIT = `${UNITS}/llama-server.service`;
export const WARMUP_UNIT = `${UNITS}/llama-warmup.service`;

/**
 * Prompts llama-server logs (--log-prompts-dir): in the user's runtime dir
 * (tmpfs, gone at logout), so conversations never reach the disk. %t is
 * systemd's name for it in a unit.
 */
export const PROMPTS_UNIT_PATH = "%t/llama-server/prompts";
export const promptsDir = () => `${process.env.XDG_RUNTIME_DIR || `/run/user/${process.getuid?.()}`}/llama-server/prompts`;

/** Agent Chat's setup prompt, without any conversation: what the warm-up replays. */
export const WARMUP_PROMPT = `${MODEL_DIR}/warmup/opencode-prompt.txt`;
