import assert from "node:assert/strict";
const origin = "https://saperror-analytics.vergil1705200.workers.dev";
const password = process.env.DASHBOARD_PASSWORD;
assert.ok(password && password.length >= 32, "Dashboard password missing or too short");
const auth = "Basic " + Buffer.from("admin:" + password).toString("base64");
console.log("::add-mask::" + auth);
console.log("::add-mask::" + auth.slice(6));
const request = (path, options = {}) => fetch(origin + path, {
  ...options, redirect: "error", signal: AbortSignal.timeout(15000)
});
const status = (r, expected, label) => {
  assert.equal(r.status, expected, label);
  console.log("PASS: " + label);
};
let r = await request("/health");
status(r, 200, "public health");
assert.deepEqual(await r.json(), {ok:true,schema:2}, "health schema");
r = await request("/");
status(r, 401, "dashboard requires authentication");
r = await request("/api/summary");
status(r, 401, "summary requires authentication");
r = await request("/api/summary", {headers:{Authorization:auth}});
status(r, 200, "authorized D1 summary");
const d = await r.json();
assert.ok(d.totals && Number.isInteger(d.totals.sessions) && d.totals.sessions >= 0, "D1 summary shape");
r = await request("/", {headers:{Authorization:auth}});
status(r, 200, "authorized dashboard");
assert.ok((await r.text()).includes("SAPERROR"), "dashboard content");
r = await request("/v2/session", {method:"POST",headers:{"Content-Type":"application/json"},body:"{}"});
status(r, 503, "ingestion disabled");
console.log("Live smoke passed; no sessions written.");
