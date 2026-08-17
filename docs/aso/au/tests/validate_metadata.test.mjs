import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { validateMetadata } from "../scripts/validate-metadata.mjs";

const approvedPromo =
  "Built for solo Australian pool techs: offline routes, service logs, LSI dosing and per-pool profit—without fleet-software overhead. Free for 5 pools.";

test("the checked-in AU metadata file is valid", () => {
  const here = path.dirname(fileURLToPath(import.meta.url));
  const metadata = JSON.parse(
    fs.readFileSync(path.resolve(here, "../metadata.json"), "utf8"),
  );

  assert.deepEqual(validateMetadata(metadata).errors, []);
});

test("accepts the approved English (Australia) listing", () => {
  const result = validateMetadata({
    locale: "en-AU",
    name: "PoolFlow: Pool Service Pro",
    subtitle: "Routes, Logs & Water Testing",
    promotionalText: approvedPromo,
    keywords:
      "maintenance,cleaning,technician,software,planner,LSI,calculator,dosing,offline",
    description:
      "A local AU description with route optimisation, 50,000 litres and A$175.50.",
    whatsNew:
      "Stability fixes and polish for the field workflow, with the same offline route management, LSI chemistry, dosing, inventory, and profit tools built for pool service pros.",
  });

  assert.deepEqual(result.errors, []);
  assert.equal(result.keywordBytes, 78);
});

test("rejects keyword duplication and a non-approved promotional text", () => {
  const result = validateMetadata({
    locale: "en-AU",
    name: "PoolFlow: Pool Service Pro",
    subtitle: "Routes, Logs & Water Testing",
    promotionalText: "PoolFlow is free forever.",
    keywords: "pool,route,water,calculator",
    description: "Australian spelling.",
    whatsNew: "Maintenance update.",
  });

  assert.match(result.errors.join("\n"), /approved price-free copy/i);
  assert.match(result.errors.join("\n"), /duplicates indexed token/i);
});

test("enforces UTF-8 byte limits instead of JavaScript character counts", () => {
  const result = validateMetadata({
    locale: "en-AU",
    name: "PoolFlow: Pool Service Pro",
    subtitle: "Routes, Logs & Water Testing",
    promotionalText: approvedPromo,
    keywords: "é".repeat(51),
    description: "Australian spelling.",
    whatsNew: "Maintenance update.",
  });

  assert.equal(result.keywordBytes, 102);
  assert.match(result.errors.join("\n"), /100 UTF-8 bytes/i);
});
