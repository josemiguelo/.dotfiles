// Runs a module's function as loadout does, for the tests:
// loadout bun tests/run-module.ts <module> check|install ['<options as JSON>']
// loadout bun tests/run-module.ts <module> listOutdated | newerVersion | update [<item>]
import { resolve } from "node:path";
import { fail, formatOutdatedItem, reason } from "loadout/script";

const [file, name, argument] = process.argv.slice(2);
try {
  const call = (await import(resolve(file)))[name];
  if (name === "update") await call(argument);
  else if (name === "listOutdated") for (const item of await call()) console.log(formatOutdatedItem(item));
  else if (name === "newerVersion") console.log((await call()) ?? "");
  else {
    const options = argument === undefined ? undefined : JSON.parse(argument);
    const wrong = options !== undefined && (await import(resolve(file.replace(/\.ts$/, ".rules.ts")))).validate(options);
    if (wrong) throw new Error(wrong);
    const result = await call(options);
    if (name === "check") process.exit(result ? 0 : 1);
  }
} catch (error) {
  fail(reason(error));
}
