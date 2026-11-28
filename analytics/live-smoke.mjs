import assert from "node:assert/strict";
const enabled=process.env.EXPECT_INGEST==="true";
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
const html=await r.text();
assert.ok(html.includes("SAPERROR"), "dashboard content");
assert.ok(!html.includes("pilot-token"),"pilot retired");
assert.ok(html.includes("Win rate"),"dashboard upgrade");
r = await request("/v2/session", {method:"POST",headers:{"Content-Type":"application/json"},body:"{}"});
status(r,enabled?400:503,enabled?"invalid payload rejected":"ingestion disabled");
if(enabled){const retired={schema:2,id:"0".repeat(32),version:"0.9.0-rc.7.pilot",mode:"classic",difficulty:0,seconds:1,wins:0,losses:0,sector:0};r=await request("/v2/session",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(retired)});status(r,403,"retired pilot blocked");}
r=await request("/api/summary?days=7&version=0.0.0",{headers:{Authorization:auth}});status(r,200,"filtered summary");assert.equal((await r.json()).daily.length,7);
console.log("Live smoke passed; no sessions written.");
