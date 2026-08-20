#!/usr/bin/env node
/*
 * mandy-packet-html.cjs — render the ComeHomeAlabama posting-packet email HTML
 * from a JSON payload. Same layout language as the proven startaitools
 * blog-packet-html.cjs (greeting → live+canonical callout → checklist →
 * per-surface copy boxes → footer), skinned in the CHA brand palette
 * (sand #f5efe6 / ink #1c2530 / gulf #1f4d59 / sun #c8a96a).
 *
 * Usage:
 *   node mandy-packet-html.cjs --in payload.json --out packet.html
 *   node mandy-packet-html.cjs < payload.json > packet.html
 *
 * Payload:
 * {
 *   "mode": "post" | "digest",
 *   "post_title": "...", "canonical_url": "...", "tier": "T2", "date": "YYYY-MM-DD",
 *   "description": "...", "first_para": "...", "body_md": "full markdown body",
 *   "links": { "substack": url, "medium": url, "activerain": url, "nextdoor": url,
 *              "gbp": url, "pinterest": url, "linkedin": url, "facebook": url },
 *   "digest": { "intro": "...", "items": [{"title","url"}], "gbp_text": "..." }
 * }
 */
'use strict';
const fs = require('fs');

function arg(name) {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : null;
}
const raw = arg('--in') ? fs.readFileSync(arg('--in'), 'utf8') : fs.readFileSync(0, 'utf8');
const p = JSON.parse(raw);

const esc = (s) => String(s == null ? '' : s)
  .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

const INK = '#1c2530', INK_SOFT = '#4b5763', GULF = '#1f4d59', GULF_LT = '#2d6a7a',
      SAND = '#f5efe6', SUN = '#c8a96a', LINE = '#d8cdb8';

// Literal copy box — recipient copies exactly what's inside.
const box = (txt) =>
  `<pre style="white-space:pre-wrap;word-break:break-word;background:#ffffff;border:1px solid ${LINE};border-left:4px solid ${SUN};border-radius:6px;padding:14px;font-size:13px;line-height:1.5;font-family:ui-monospace,Menlo,Consolas,monospace;color:${INK}">${esc(txt)}</pre>`;

const h2 = (n, title, who) =>
  `<h2 style="font-size:17px;color:${GULF};margin:28px 0 6px;border-bottom:2px solid ${LINE};padding-bottom:6px">` +
  `<span style="display:inline-block;background:${GULF};color:${SAND};border-radius:999px;width:24px;height:24px;text-align:center;line-height:24px;font-size:13px;margin-right:8px">${n}</span>` +
  `${esc(title)} <span style="font-weight:400;color:${INK_SOFT};font-size:13px">· ${esc(who)}</span></h2>`;

const note = (html) =>
  `<div style="background:${SAND};border:1px solid ${LINE};border-radius:6px;padding:10px 14px;font-size:13px;color:${INK_SOFT};margin:8px 0">${html}</div>`;

const warn = (html) =>
  `<div style="border:2px solid #b42318;background:#fff4f2;border-radius:8px;padding:12px 14px;margin:8px 0"><strong style="color:#b42318">⚠ ${html}</strong></div>`;

const out = [];
out.push(`<div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;font-size:15px;line-height:1.55;color:${INK};max-width:720px;margin:0 auto">`);

// Brand masthead
out.push(`<div style="background:${GULF};border-radius:10px 10px 0 0;padding:18px 24px">
  <div style="color:${SAND};font-size:20px;font-family:Georgia,'Times New Roman',serif">Mandy <em>Longshore</em></div>
  <div style="color:${SUN};font-size:12px;letter-spacing:2px;text-transform:uppercase;margin-top:2px">ComeHomeAlabama · journal syndication packet</div>
</div>`);
out.push(`<div style="background:#fffdf9;border:1px solid ${LINE};border-top:0;border-radius:0 0 10px 10px;padding:22px 24px">`);

if (p.mode === 'digest') {
  const d = p.digest || {};
  out.push(`<p style="margin-top:0">This week's <strong>“Notes from the Coast”</strong> digest — one Substack post + one Google Business Profile post.</p>`);
  out.push(h2(1, 'Substack — weekly digest', 'Ezekiel'));
  out.push(note(`Suggested subject: <strong>Notes from the coast, this week</strong>`));
  out.push(box(`${d.intro || ''}\n\n${(d.items || []).map((it) => `${it.title}\n${it.url}`).join('\n\n')}\n\nCall or text me anytime — (251) 597-5809. I answer my phone.`));
  out.push(h2(2, 'Google Business Profile — week post', 'Ezekiel'));
  out.push(note(`Add post → paste text → button <strong>Learn more</strong> → the link inside the box.`));
  out.push(box(d.gbp_text || ''));
} else {
  const L = p.links || {};
  out.push(`<p style="margin-top:0">The post <strong>“${esc(p.post_title)}”</strong> (${esc(p.tier || '')}) is <strong>live and canonical</strong>:</p>`);
  out.push(`<p style="font-size:16px">👉 <a href="${esc(p.canonical_url)}" target="_blank" style="color:${GULF_LT};font-weight:600">${esc(p.canonical_url)}</a></p>`);
  out.push(`<p>Six places, top to bottom. Every link is already UTM-tagged per surface — no placeholders. Paste copy exactly as boxed: no added emojis, no extra hashtags, no hype. It should sound like Mandy, because it is.</p>`);
  out.push(`<ol style="color:${INK_SOFT}">
    <li><strong style="color:${INK}">Substack</strong> — full article</li>
    <li><strong style="color:${INK}">Medium</strong> — full article, canonical URL REQUIRED</li>
    <li><strong style="color:${INK}">ActiveRain</strong> — full article</li>
    <li><strong style="color:${INK}">Nextdoor</strong> — short neighborly note</li>
    <li><strong style="color:${INK}">Google Business Profile</strong> — post</li>
    <li><strong style="color:${INK}">Pinterest</strong> — pin</li>
  </ol>
  <p style="color:${INK_SOFT};font-size:13px">Section 7 is <strong>Mandy's own</strong> LinkedIn + Facebook copy — nothing for you to do there.</p>`);

  out.push(h2(1, 'Substack — “Notes from the Coast”', 'Ezekiel'));
  out.push(note(`Title: <strong>${esc(p.post_title)}</strong>. Paste the full body (bottom of this email), then add this closing:`));
  out.push(box(`Originally published on the journal: ${L.substack}\nNo pressure, just honest numbers. Call or text Mandy: (251) 597-5809.`));

  out.push(h2(2, 'Medium', 'Ezekiel'));
  out.push(warn(`Set the canonical link BEFORE publishing — Story settings → Advanced → canonical link. Never publish on Medium without it.`));
  out.push(box(`Canonical URL (exact): ${p.canonical_url}`));
  out.push(note(`Then paste the full body and close with: <em>Full version on the journal:</em> ${esc(L.medium || '')}`));

  out.push(h2(3, 'ActiveRain', 'Ezekiel'));
  out.push(note(`Title as above; paste the full body, then close with:`));
  out.push(box(`Full version on the journal: ${L.activerain}\nMandy Longshore · RE/MAX of Gulf Shores · Licensed in AL & FL`));

  out.push(h2(4, 'Nextdoor', 'Ezekiel'));
  out.push(box(`${p.description}\n\nFull note here: ${L.nextdoor}\nQuestions? Call or text Mandy: (251) 597-5809.`));

  out.push(h2(5, 'Google Business Profile', 'Ezekiel'));
  out.push(note(`Add post → paste → button <strong>Learn more</strong> → the link in the box. (Manual until the Posts API approval lands.)`));
  out.push(box(`${p.description}\n\nLearn more → ${L.gbp}`));

  out.push(h2(6, 'Pinterest', 'Ezekiel'));
  out.push(note(`Board: the matching community/pillar board. Destination link is the tracked one in the box.`));
  out.push(box(`Pin title: ${p.post_title}\nPin description: ${p.description}\nDestination: ${L.pinterest}`));

  out.push(`<div style="background:${SAND};border:1px solid ${SUN};border-radius:10px;padding:4px 18px 14px;margin-top:30px">`);
  out.push(`<h2 style="font-size:17px;color:${GULF};margin:14px 0 6px">7 · Mandy's section — <span style="color:#b45309">she posts these herself</span></h2>`);
  out.push(`<p style="font-size:13px;color:${INK_SOFT};margin:0 0 8px">LinkedIn:</p>`);
  out.push(box(`${p.first_para}\n\nI wrote the whole thing up here: ${L.linkedin}`));
  out.push(`<p style="font-size:13px;color:${INK_SOFT};margin:10px 0 8px">Facebook (page and/or groups, her call):</p>`);
  out.push(box(`${p.first_para}\n\nFull note: ${L.facebook}\nCall or text me anytime: (251) 597-5809.`));
  out.push(`</div>`);

  out.push(`<hr style="border:none;border-top:1px solid ${LINE};margin:26px 0">`);
  out.push(`<h2 style="font-size:16px;color:${GULF}">Full post body — for sections 1–3</h2>`);
  out.push(box(p.body_md || ''));
}

out.push(`<p style="color:${INK_SOFT};font-size:12px;border-top:1px solid ${LINE};padding-top:12px;margin-top:22px">Automated packet from the ComeHomeAlabama journal pipeline · Intent Solutions. Reply to this email with DONE + surface names as you post; problems → Jeremy.</p>`);
out.push(`</div></div>`);

const html = out.join('\n');
if (arg('--out')) fs.writeFileSync(arg('--out'), html);
else process.stdout.write(html);
