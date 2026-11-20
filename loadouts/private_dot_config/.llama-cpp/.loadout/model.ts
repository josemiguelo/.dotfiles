#!/usr/bin/env bun
// The local LLM's GGUF from Hugging Face, at a pinned commit (so a re-upload
// can't change what a new machine gets), checked against its SHA-256. The
// hash is checked once, after the download (or for a file already there), and
// written beside it as <file>.sha256-ok: check reads that marker instead of
// hashing ~21 GB on every status.
// usage: model.ts [check|install] <hf repo> <commit> <file> <sha256>
import { mkdirSync, renameSync, statSync } from "node:fs";
import { $, fail, main, readTrimmed } from "loadout/script";
import { MODEL_DIR } from "#llama-cpp";

const USAGE = "usage: model.ts [check|install] <hf repo> <commit> <file> <sha256>";

function parse(args: string[]) {
  const [repo, commit, file, sha256] = args;
  if (!repo || !/^[0-9a-f]{40}$/.test(commit ?? "") || !file || !/^[0-9a-f]{64}$/.test(sha256 ?? "")) fail(USAGE);
  return { repo, commit, file, sha256, path: `${MODEL_DIR}/${file}`, marker: `${MODEL_DIR}/${file}.sha256-ok` };
}

const exists = (path: string) => statSync(path, { throwIfNoEntry: false })?.isFile() ?? false;

async function ready(...args: string[]) {
  const { path, marker, sha256 } = parse(args);
  return exists(path) && (await readTrimmed(marker)) === sha256;
}

/** path's SHA-256, streamed: the file is far bigger than memory wants. */
async function sha256Of(path: string) {
  const hasher = new Bun.CryptoHasher("sha256");
  for await (const chunk of Bun.file(path).stream()) hasher.update(chunk);
  return hasher.digest("hex");
}

async function install(...args: string[]) {
  const { repo, commit, file, sha256, path, marker } = parse(args);
  mkdirSync(MODEL_DIR, { recursive: true });
  if (!exists(path)) {
    const part = `${path}.part`;
    // curl, not fetch: ~21 GB wants resuming (-C -) and retries.
    await $`curl -fL --retry 5 -C - -o ${part} ${`https://huggingface.co/${repo}/resolve/${commit}/${file}`}`;
    renameSync(part, path);
  }
  console.error(`llm-model: checking ${file}'s SHA-256`);
  const got = await sha256Of(path);
  if (got !== sha256) fail(`${path} doesn't match its SHA-256 (got ${got}); delete it to download it again`);
  await Bun.write(marker, `${sha256}\n`);
}

await main(ready, install);
