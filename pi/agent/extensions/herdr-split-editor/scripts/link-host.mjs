import { access, lstat, mkdir, readFile, realpath, symlink } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

// Development only: use the installed Pi host, never install a second runtime into the package.
try {
  const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
  const agentDir = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
  const install = process.env.PI_MANAGED_INSTALL_ROOT ?? join(agentDir, "install");
  const hostModules = process.argv[2] ?? join(install, "releases", (await readFile(join(install, "current-version"), "utf8")).trim(), "node_modules");
  for (const name of ["pi-coding-agent", "pi-tui"]) {
    const target = await realpath(join(hostModules, "@earendil-works", name));
    await access(join(target, "package.json"));
    const link = join(root, "node_modules", "@earendil-works", name);
    await mkdir(dirname(link), { recursive: true });
    const existing = await lstat(link).catch((error) => {
      if (error.code === "ENOENT") return undefined;
      throw error;
    });
    if (existing !== undefined) {
      if ((await realpath(link)) !== target) {
        console.error(`Remove the stale host link or installed copy first: ${link}`);
        process.exitCode = 1;
        break;
      }
    } else await symlink(target, link, "dir");
    console.log(`${name}: ${target}`);
  }
} catch (error) {
  console.error(`Cannot link Pi host packages: ${error instanceof Error ? error.message : String(error)}`);
  process.exitCode = 1;
}
