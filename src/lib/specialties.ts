/**
 * The five footer specialties, each with a real page at /specialties/[slug]/.
 * Copy follows the confirmed brand voice: honest numbers, hyperlocal precision,
 * no hype. Fair-housing rule for every word here: describe the property, the
 * place, and the numbers — never the people who "belong" somewhere.
 */
export interface SpecialtySection {
  title: string;
  body: string;
}

export interface Specialty {
  slug: string;
  name: string;
  headline: string;
  intro: string;
  sections: SpecialtySection[];
  related: { title: string; href: string }[];
  heroAlt: string;
}

export const SPECIALTIES: Specialty[] = [
  {
    slug: "relocation",
    name: "Relocation",
    headline: "New to the coast? Come home to it.",
    intro:
      "PCS orders to NAS Pensacola, a retirement you've been planning for years, or a remote job that finally cut the cord — moving to the coast is a hundred decisions made from far away. My job is making them with you, with real numbers, before the moving truck is loaded.",
    sections: [
      {
        title: "One agent, both states",
        body: "The Alabama–Florida line runs right through this market: Orange Beach and Perdido Key are ten minutes apart and in different states, with different taxes, insurance markets, and closing customs. I'm licensed in both, so the search doesn't stop at the state line and you don't get handed off mid-move.",
      },
      {
        title: "The honest orientation",
        body: "Before we look at a single house, we compare towns the way locals actually do: true monthly cost with insurance included, commute in July traffic (not February traffic), what's near the hospital, where new construction keeps prices reasonable. You get the spreadsheet, not the brochure.",
      },
      {
        title: "Long-distance help that actually works",
        body: "Video walkthroughs where I point the camera at the breaker box and the water heater, not just the view. A local bench of lenders, inspectors, and movers who answer their phones. And when you land, you know where the good grocery store is.",
      },
    ],
    related: [
      {
        title: "Foley is where the math works",
        href: "/journal/foley-is-where-the-math-works/",
      },
    ],
    heroAlt: "Quiet coastal Alabama neighborhood street at golden hour",
  },
  {
    slug: "luxury",
    name: "Luxury",
    headline: "Waterfront, gulf-front, and the quiet end of the market.",
    intro:
      "High-end coastal property is its own market, with its own rules: many of the best homes trade quietly, and the real questions are below the waterline. I work that end of the market the same way I work every deal — honest numbers first.",
    sections: [
      {
        title: "Discretion first",
        body: "Sellers at this level often don't want a circus, and buyers don't want their search discussed at the marina. Quiet conversations, careful showings, and a short list of serious parties beat a spectacle every time.",
      },
      {
        title: "The numbers behind the view",
        body: "Wind and flood insurance layering, elevation certificates, seawall and dock condition, deep-water access at low tide — this is where waterfront deals are actually won or lost. I'll get you the real carrying cost before you fall in love with the sunset.",
      },
      {
        title: "Both sides of the line",
        body: "From Ono Island and Orange Beach across to Perdido Key, the premium waterfront market straddles two states. Dual licensing means the whole market is on your table, compared honestly, tax treatment and all.",
      },
    ],
    related: [
      {
        title: "What a special assessment really means",
        href: "/journal/what-a-special-assessment-really-means/",
      },
    ],
    heroAlt: "Private dock and boat lift on a calm bay at dusk",
  },
  {
    slug: "vacation-resorts",
    name: "Vacation & Resorts",
    headline: "The second home that pays its way. Or doesn't — let's find out first.",
    intro:
      "Half the people who call me about a beach place are really asking an investment question. Good. Let's treat it like one: real rental history, real seasonality, real management fees — before you write an offer, not after.",
    sections: [
      {
        title: "Rental honesty",
        body: "Projected rental income is a sales tool; trailing twelve months of actual bookings is a fact. We underwrite on facts: gross rents, management cut, cleaning, insurance, dues, and the quiet months. If the numbers only work in July, you'll know that in writing.",
      },
      {
        title: "Resort communities, compared",
        body: "Lazy rivers and beach shuttles are wonderful and they show up in the dues. We compare amenity packages against their carrying cost and against what actually drives bookings in this market, community by community.",
      },
      {
        title: "Owning from three states away",
        body: "Storm prep, seasonal maintenance, a property manager who sends photos instead of excuses — I'll connect you with the local bench that keeps second homes from becoming second jobs.",
      },
    ],
    related: [
      {
        title: "What a special assessment really means",
        href: "/journal/what-a-special-assessment-really-means/",
      },
    ],
    heroAlt: "Sugar-white dunes and gulf-front towers in morning haze",
  },
  {
    slug: "condominiums",
    name: "Condominiums",
    headline: "Condos, with the paperwork actually read.",
    intro:
      "A condo purchase is really two purchases: the unit, and a share of a building with its own budget, insurance, and repair history. Most surprises live in the second one. I read it before you buy it.",
    sections: [
      {
        title: "The documents most people skip",
        body: "Budget, reserve study, master insurance policy, meeting minutes. Twenty minutes with the minutes tells you more about a building than an hour at the open house — what's been argued about, what's been deferred, and what letter might be coming.",
      },
      {
        title: "True monthly cost, not list price",
        body: "Dues plus your HO-6 policy plus the realistic assessment risk for a building of that age and exposure. Two units at the same price can be hundreds apart per month once you do this math. We do it on every candidate.",
      },
      {
        title: "When trading up beats staying",
        body: "Sometimes the honest math says your equity works harder in a newer home minutes off the water. Sometimes it says stay — your building is sound and the balcony is the whole point. I'll run both columns and you decide.",
      },
    ],
    related: [
      {
        title: "What a special assessment really means",
        href: "/journal/what-a-special-assessment-really-means/",
      },
    ],
    heroAlt: "Condo balcony over the gulf at sunrise",
  },
  {
    slug: "new-construction",
    name: "New Construction",
    headline: "Brand-new, minutes off the water.",
    intro:
      "South Baldwin builds more new homes than almost anywhere on the coast, and a brand-new house often costs less per month than a decades-old condo two blocks from the sand. The catch: the builder's sales office works for the builder. I work for you.",
    sections: [
      {
        title: "The builder's contract, your side of the table",
        body: "Builder contracts are written by the builder's lawyers, and the friendly person in the model home is paid by the builder. Bringing your own agent costs you nothing in most builder communities and gets the incentives, upgrades, and timelines negotiated by someone on your side.",
      },
      {
        title: "From dirt to done",
        body: "My family clears land and builds on it, so this isn't theory to me. Lot evaluation, perc tests, land loans, construction-to-permanent financing — if your version of new construction starts with an empty parcel, that's a lane we know from the seat of the equipment.",
      },
      {
        title: "Walk-throughs and warranties",
        body: "Pre-drywall walk, blue-tape walk, the eleventh-month warranty walk before it expires — new homes come with real protections that only help if someone tracks the calendar and writes the punch list. I do both.",
      },
    ],
    related: [
      {
        title: "Buying land in Baldwin County: the honest checklist",
        href: "/journal/buying-land-in-baldwin-county-the-honest-checklist/",
      },
      {
        title: "Foley is where the math works",
        href: "/journal/foley-is-where-the-math-works/",
      },
    ],
    heroAlt: "Newly built coastal cottage in morning light",
  },
];
