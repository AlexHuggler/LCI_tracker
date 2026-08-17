import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const APPROVED_PRICE_FREE_PROMOTIONAL_TEXT =
  "Built for solo Australian pool techs: offline routes, service logs, LSI dosing and per-pool profit—without fleet-software overhead. Free for 5 pools.";

const limits = {
  name: 30,
  subtitle: 30,
  promotionalText: 170,
  description: 4000,
  whatsNew: 4000,
};

function characterCount(value) {
  return [...value].length;
}

function indexedTokens(value) {
  return new Set(
    value
      .toLocaleLowerCase("en-AU")
      .match(/[a-z0-9]+/g)
      ?.filter((token) => token.length > 1) ?? [],
  );
}

export function validateMetadata(metadata) {
  const errors = [];
  const required = [
    "locale",
    "name",
    "subtitle",
    "promotionalText",
    "keywords",
    "description",
    "whatsNew",
  ];

  for (const field of required) {
    if (typeof metadata[field] !== "string" || metadata[field].trim() === "") {
      errors.push(`${field} is required.`);
    }
  }

  if (metadata.locale !== "en-AU") {
    errors.push("locale must be en-AU.");
  }

  for (const [field, limit] of Object.entries(limits)) {
    if (typeof metadata[field] === "string" && characterCount(metadata[field]) > limit) {
      errors.push(`${field} exceeds the ${limit}-character App Store limit.`);
    }
  }

  const keywordBytes = Buffer.byteLength(metadata.keywords ?? "", "utf8");
  if (keywordBytes > 100) {
    errors.push(`keywords exceeds the 100 UTF-8 bytes App Store limit (${keywordBytes}).`);
  }

  const indexed = new Set([
    ...indexedTokens(metadata.name ?? ""),
    ...indexedTokens(metadata.subtitle ?? ""),
  ]);
  const duplicateKeywords = (metadata.keywords ?? "")
    .split(",")
    .map((keyword) => keyword.trim().toLocaleLowerCase("en-AU"))
    .filter((keyword) => indexed.has(keyword));
  if (duplicateKeywords.length > 0) {
    errors.push(
      `keywords duplicates indexed token(s) from name/subtitle: ${[...new Set(duplicateKeywords)].join(", ")}.`,
    );
  }

  if (metadata.promotionalText !== APPROVED_PRICE_FREE_PROMOTIONAL_TEXT) {
    errors.push("promotionalText must use the approved price-free copy exactly.");
  }

  const description = metadata.description ?? "";
  for (const marker of ["optimisation", "litres", "A$"]) {
    if (!description.includes(marker)) {
      errors.push(`description must include AU marker: ${marker}.`);
    }
  }

  return { errors, keywordBytes };
}

function main() {
  const here = path.dirname(fileURLToPath(import.meta.url));
  const metadataPath = process.argv[2] ?? path.resolve(here, "../metadata.json");
  const metadata = JSON.parse(fs.readFileSync(metadataPath, "utf8"));
  const result = validateMetadata(metadata);

  if (result.errors.length > 0) {
    console.error(`AU ASO metadata failed (${result.keywordBytes} keyword bytes):`);
    for (const error of result.errors) console.error(`- ${error}`);
    process.exitCode = 1;
    return;
  }

  console.log(`AU ASO metadata valid (${result.keywordBytes}/100 keyword bytes).`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main();
