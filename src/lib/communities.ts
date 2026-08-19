/**
 * Phase A canonical community list.
 *
 * Phase B replaces this with Sanity-driven content (`community` schema:
 * name, slug, region, tagline, hero image, hyperlocal copy, market data).
 * Until then this static list drives /communities/ + /communities/[slug]/
 * so the URLs are live and indexable.
 *
 * Service area is brokerage-portable — south of I-10 in Baldwin County
 * AL plus Perdido Key + west Pensacola FL. North-of-I-10 is out of scope.
 */
export interface Community {
  slug: string;
  name: string;
  region: "Baldwin County, AL" | "Escambia County, FL";
  tagline: string;
  zips: string[];
}

export const COMMUNITIES: Community[] = [
  {
    slug: "gulf-shores",
    name: "Gulf Shores",
    region: "Baldwin County, AL",
    tagline:
      "The flagship Alabama beach town — sugar-white sand, gulf-front condos, family vacation rentals.",
    zips: ["36542"],
  },
  {
    slug: "orange-beach",
    name: "Orange Beach",
    region: "Baldwin County, AL",
    tagline:
      "Higher-end resort community with deepwater access, marina culture, and Perdido Pass.",
    zips: ["36561"],
  },
  {
    slug: "foley",
    name: "Foley",
    region: "Baldwin County, AL",
    tagline:
      "Inland Baldwin County — outlet shopping, growing subdivisions, attainable price points.",
    zips: ["36535"],
  },
  {
    slug: "fairhope",
    name: "Fairhope",
    region: "Baldwin County, AL",
    tagline:
      "Eastern Shore artistic enclave — historic downtown, bayfront walks, Mobile Bay sunsets.",
    zips: ["36533", "36532"],
  },
  {
    slug: "spanish-fort",
    name: "Spanish Fort",
    region: "Baldwin County, AL",
    tagline:
      "Bay-bridge gateway to Mobile — newer master-planned communities, top schools, easy commute.",
    zips: ["36527"],
  },
  {
    slug: "perdido-key",
    name: "Perdido Key",
    region: "Escambia County, FL",
    tagline:
      "Quiet barrier-island stretch on the AL/FL line — gulf-front condos, state park, no high-rises east of Innerarity.",
    zips: ["32507"],
  },
  {
    slug: "pensacola",
    name: "Pensacola (West)",
    region: "Escambia County, FL",
    tagline:
      "Historic city, NAS Pensacola, the Blue Angels — west-side neighborhoods within Mandy's coverage.",
    zips: ["32507", "32506"],
  },
];
