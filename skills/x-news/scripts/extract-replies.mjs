#!/usr/bin/env node
// Compact reply extractor: opencli twitter thread -f json | node extract-replies.mjs
// Prints the root tweet line, a reply count, then one line per reply:
//   @author |♥likes |text
let s = '';
process.stdin.on('data', d => (s += d)).on('end', () => {
  let j;
  try { j = JSON.parse(s); } catch { console.log('PARSE_FAIL: ' + s.slice(0, 200)); return; }
  const arr = Array.isArray(j) ? j : (j.data || j.results || j.items || []);
  const root = arr[0];
  if (root) {
    const sum = (root.likes || 0) + (root.retweets || 0) + (root.replies || 0);
    console.log('ROOT @' + root.author + ' Σ' + sum + '♥' + root.likes);
  }
  const replies = arr.slice(1);
  console.log('REPLIES ' + replies.length);
  for (const r of replies) {
    const txt = String(r.text || '').replace(/\s+/g, ' ').trim().slice(0, 240);
    console.log('@' + r.author + ' |♥' + (r.likes ?? 0) + ' |' + txt);
  }
});
