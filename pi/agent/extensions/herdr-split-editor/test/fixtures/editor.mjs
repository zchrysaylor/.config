import { readFile, writeFile } from "node:fs/promises";
import { setTimeout } from "node:timers/promises";

const file = process.argv[2];
if (!file) process.exit(2);
await setTimeout(Number(process.env.TEST_EDITOR_DELAY ?? "0"));
if (process.env.TEST_EDITOR_REPORT_SHELL) {
  await writeFile(process.env.TEST_EDITOR_REPORT_SHELL, JSON.stringify({ shell: process.env.SHELL ?? null }), "utf8");
}
const original = await readFile(file, "utf8");
await writeFile(file, `${original}\n한글 edited\n`, "utf8");
process.exit(Number(process.env.TEST_EDITOR_EXIT ?? "0"));
