import rss from "@astrojs/rss";
import { getCollection } from "astro:content";

// The free-syndication substrate: Ezekiel's packet, future automations, and
// any reader tool consume this feed. Full canonical URLs, no tracking params.
export async function GET(context) {
  const posts = (await getCollection("journal", ({ data }) => !data.draft)).sort(
    (a, b) => b.data.date.valueOf() - a.data.date.valueOf(),
  );
  return rss({
    title: "Notes from the Coast · Mandy Longshore",
    description:
      "Neighborhood updates, market observations, and honest numbers from coastal Alabama and northwest Florida. Mandy Longshore, RE/MAX of Gulf Shores.",
    site: context.site,
    items: posts.map((post) => ({
      title: post.data.title,
      description: post.data.description,
      pubDate: post.data.date,
      link: `/journal/${post.id}/`,
      categories: [post.data.community, ...post.data.topics],
    })),
    customData: "<language>en-us</language>",
  });
}
