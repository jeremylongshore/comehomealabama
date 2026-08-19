import { defineCollection, z } from "astro:content";
import { glob } from "astro/loaders";

/**
 * The journal — the canonical content home for the Mandy content machine.
 * Posts are MDX files committed by the deterministic lander
 * (scripts/journal/mandy-land.sh); frontmatter here is the contract the
 * producer skill and the lander both validate against.
 */
const journal = defineCollection({
  loader: glob({ pattern: "**/*.{md,mdx}", base: "./src/content/journal" }),
  schema: z.object({
    title: z.string().max(120),
    description: z.string().max(200),
    date: z.coerce.date(),
    // Community pages this post belongs to; slugs from src/lib/communities.ts,
    // or "coastal" for area-wide pieces.
    community: z.string().default("coastal"),
    topics: z.array(z.string()).default([]),
    // Content tier per the methodology: T1 Market Note / T2 Guide-Explainer / T3 Deep Guide.
    tier: z.enum(["T1", "T2", "T3"]).default("T2"),
    draft: z.boolean().default(false),
    ogImage: z.string().optional(),
  }),
});

export const collections = { journal };
