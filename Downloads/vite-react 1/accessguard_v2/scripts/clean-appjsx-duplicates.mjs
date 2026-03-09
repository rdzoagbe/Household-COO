// scripts/clean-appjsx-duplicates.mjs
import fs from "node:fs";
import path from "node:path";

// You need these dev deps:
//   npm i -D @babel/parser @babel/traverse
import { parse } from "@babel/parser";
import traverse from "@babel/traverse";

const APP_PATH = path.resolve(process.cwd(), "src", "App.jsx");

function ts() {
  const d = new Date();
  const pad = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}_${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`;
}

function isTopLevel(pathNode) {
  return pathNode.parent && pathNode.parent.type === "Program";
}

function getVarNameIfComponentDeclarator(decl) {
  // const X = () => {}
  // const X = function() {}
  if (!decl?.id || decl.id.type !== "Identifier") return null;
  const name = decl.id.name;
  const init = decl.init;
  if (!init) return null;

  const ok =
    init.type === "ArrowFunctionExpression" ||
    init.type === "FunctionExpression";

  return ok ? name : null;
}

function deleteRanges(source, ranges) {
  // ranges = [{start,end, reason, name, loc}]
  // Remove from bottom to top to preserve indices
  const sorted = [...ranges].sort((a, b) => b.start - a.start);
  let out = source;
  for (const r of sorted) {
    out = out.slice(0, r.start) + out.slice(r.end);
  }
  return out;
}

function main() {
  if (!fs.existsSync(APP_PATH)) {
    console.error(`❌ Could not find ${APP_PATH}`);
    process.exit(1);
  }

  const source = fs.readFileSync(APP_PATH, "utf8");

  const ast = parse(source, {
    sourceType: "module",
    plugins: ["jsx"],
    errorRecovery: false,
    ranges: true,
  });

  /** Map name -> array of {start,end, loc, kind} */
  const decls = new Map();

  traverse(ast, {
    FunctionDeclaration(p) {
      if (!isTopLevel(p.node)) return;
      if (!p.node.id?.name) return;

      const name = p.node.id.name;
      const start = p.node.start;
      const end = p.node.end;

      if (typeof start !== "number" || typeof end !== "number") return;
      const arr = decls.get(name) ?? [];
      arr.push({ name, start, end, loc: p.node.loc, kind: "function" });
      decls.set(name, arr);
    },

    VariableDeclaration(p) {
      if (!isTopLevel(p.node)) return;

      for (const d of p.node.declarations ?? []) {
        const name = getVarNameIfComponentDeclarator(d);
        if (!name) continue;

        // Remove only the declarator *if possible*, but simplest is remove whole var decl line.
        // However multiple declarators in one statement are rare here; we handle both:
        const start = p.node.start;
        const end = p.node.end;
        if (typeof start !== "number" || typeof end !== "number") continue;

        const arr = decls.get(name) ?? [];
        arr.push({ name, start, end, loc: p.node.loc, kind: "const" });
        decls.set(name, arr);
      }
    },
  });

  const removals = [];
  for (const [name, list] of decls.entries()) {
    if (list.length <= 1) continue;

    // Keep the last declaration (largest start)
    const sorted = [...list].sort((a, b) => a.start - b.start);
    const keep = sorted[sorted.length - 1];

    for (let i = 0; i < sorted.length - 1; i++) {
      removals.push({
        ...sorted[i],
        reason: `duplicate of "${name}" (keeping last at ${keep.loc?.start?.line ?? "?"}:${keep.loc?.start?.column ?? "?"})`,
      });
    }
  }

  if (removals.length === 0) {
    console.log("✅ No duplicate top-level component/page declarations found.");
    return;
  }

  const backupPath = `${APP_PATH}.bak.${ts()}`;
  fs.writeFileSync(backupPath, source, "utf8");

  const cleaned = deleteRanges(source, removals);

  const outPath = `${APP_PATH}.cleaned`;
  fs.writeFileSync(outPath, cleaned, "utf8");

  console.log(`✅ Wrote backup: ${backupPath}`);
  console.log(`✅ Wrote cleaned file: ${outPath}`);
  console.log("");
  console.log("Removed duplicates:");
  for (const r of removals.sort((a, b) => a.start - b.start)) {
    const line = r.loc?.start?.line ?? "?";
    console.log(`- ${r.kind.padEnd(8)} ${r.name} @ line ${line} → ${r.reason}`);
  }

  console.log("");
  console.log("Next step:");
  console.log(`1) Replace src/App.jsx with src/App.jsx.cleaned`);
  console.log(`   (or inspect differences first)`);
}

main();