import {valid} from "./validation.mjs";
const headers={"Cache-Control":"no-store","X-Content-Type-Options":"nosniff","Referrer-Policy":"no-referrer","X-Frame-Options":"DENY","Content-Security-Policy":"default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'"};
function reply(body,status=200,extra={}) {return new Response(body,{status,headers:{...headers,...extra}})}
function json(x,status=200){return reply(JSON.stringify(x),status,{"Content-Type":"application/json; charset=utf-8"})}
async function authorized(req,env) {
 if(typeof env.DASHBOARD_PASSWORD!=="string" || env.DASHBOARD_PASSWORD.length<32) return false;
 let input="";try{const h=req.headers.get("Authorization")||"";if(h.startsWith("Basic "))input=atob(h.slice(6));}catch{}
 const enc=new TextEncoder();const digest=async s=>new Uint8Array(await crypto.subtle.digest("SHA-256",enc.encode(s)));
 const a=await digest(input),b=await digest("admin:"+env.DASHBOARD_PASSWORD);
 let diff=0;for(let i=0;i<a.length;i++)diff|=a[i]^b[i];return diff===0;
}
async function boundedJson(req) {
 if(!req.body || !/^application\/json(?:;|$)/i.test(req.headers.get("content-type")||""))return null;
 const reader=req.body.getReader();let n=0;const parts=[];
 try{while(true){const {done,value}=await reader.read();if(done)break;n+=value.length;if(n>2048){await reader.cancel();return null}parts.push(value)}
 const bytes=new Uint8Array(n);let pos=0;for(const part of parts){bytes.set(part,pos);pos+=part.length}
 return JSON.parse(new TextDecoder("utf-8",{fatal:true}).decode(bytes));}catch{return null}finally{reader.releaseLock()}
}
const UPSERT=`INSERT INTO sessions(id,version,mode,difficulty,seconds,wins,losses,sector,started,updated)
 VALUES(?,?,?,?,?,?,?,?,?,?)
 ON CONFLICT(id) DO UPDATE SET seconds=MAX(sessions.seconds,excluded.seconds), wins=MAX(sessions.wins,excluded.wins),
 losses=MAX(sessions.losses,excluded.losses),sector=MAX(sessions.sector,excluded.sector),updated=excluded.updated
 WHERE sessions.version=excluded.version AND sessions.mode=excluded.mode AND sessions.difficulty=excluded.difficulty
 AND sessions.started >= excluded.updated-86400`;
const esc=s=>String(s??"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
async function summary(db,now) {
 const since=now-30*86400;
 const totals=await db.prepare("SELECT COUNT(*) AS sessions,COALESCE(SUM(seconds),0) AS seconds,COALESCE(SUM(wins),0) AS wins,COALESCE(SUM(losses),0) AS losses,COALESCE(SUM(CASE WHEN updated>=? THEN 1 ELSE 0 END),0) AS recent FROM sessions WHERE updated>=?").bind(now-120,since).first();
 const groups=await db.prepare("SELECT mode,difficulty,COUNT(*) AS sessions,SUM(seconds) AS seconds,SUM(wins) AS wins,SUM(losses) AS losses,MAX(sector) AS sector FROM sessions WHERE updated>=? GROUP BY mode,difficulty ORDER BY sessions DESC").bind(since).all();
 const daily=await db.prepare("SELECT date(started,'unixepoch') AS day,COUNT(*) AS sessions,SUM(seconds) AS seconds FROM sessions WHERE updated>=? GROUP BY day ORDER BY day DESC LIMIT 31").bind(since).all();
 const versions=await db.prepare("SELECT version,COUNT(*) AS sessions FROM sessions WHERE updated>=? GROUP BY version ORDER BY sessions DESC LIMIT 30").bind(since).all();
 return {totals,groups:groups.results,daily:daily.results,versions:versions.results};
}
const table=(head,rows)=>"<table><thead><tr>"+head.map(s=>"<th>"+esc(s)+"</th>").join("")+"</tr></thead><tbody>"+rows.map(row=>"<tr>"+row.map(s=>"<td>"+esc(s)+"</td>").join("")+"</tr>").join("")+"</tbody></table>";
function dashboard(d) {
 const t=d.totals;const card=(label,value)=>"<section><small>"+esc(label)+"</small><strong>"+esc(value)+"</strong></section>";
 return '<!doctype html><html lang="uk"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><meta http-equiv="refresh" content="60"><title>SAPERROR // ANALYTICS</title><style>body{background:#09150e;color:#b6edb1;font:15px Consolas,monospace;max-width:1120px;margin:32px auto;padding:0 20px}h1{letter-spacing:.1em;font-size:26px;border-bottom:1px solid #54785b;padding-bottom:18px}h2{font-size:17px;margin-top:28px}small,p{color:#91b39a}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:12px}section{border:1px solid #42654a;padding:18px;background:#0e2116}strong{display:block;font-size:28px;margin-top:12px}table{width:100%;border-collapse:collapse}td,th{text-align:left;padding:10px;border-bottom:1px solid #294b35}th{color:#e5b86c}.scroll{overflow:auto}a{color:inherit}</style><h1>SAPERROR // ANALYTICS ▌</h1><p>Закрита панель · останні 30 днів · оновлення щохвилини</p><div class="cards">'+card("Сесії",t.sessions)+card("Нещодавня активність (2 хв)",t.recent)+card("Години гри",(t.seconds/3600).toFixed(1))+card("Перемоги",t.wins)+card("Поразки",t.losses)+'</div><p>Сесії не дорівнюють унікальним гравцям. Дані добровільні, клієнтські й приблизні.</p><h2>Режими та складність</h2><div class="scroll">'+table(["Режим","Складність","Сесії","Хвилини","Перемоги","Поразки","Макс. сектор"],d.groups.map(r=>[r.mode,["Story","Standard","Expert","Hardcore","N/A"][r.difficulty],r.sessions,Math.round(r.seconds/60),r.wins,r.losses,r.sector]))+'</div><h2>Сесії за днем початку (UTC)</h2>'+table(["Дата","Сесії","Хвилини"],d.daily.map(r=>[r.day,r.sessions,Math.round(r.seconds/60)]))+'<h2>Версії</h2>'+table(["Версія","Сесії"],d.versions.map(r=>[r.version,r.sessions]))+'<p>Дані оновлюються не миттєво; короткі або офлайн-сесії можуть бути відсутні.</p></html>';
}
export default {
 async fetch(req,env) {
  try {
   const url=new URL(req.url);const now=Math.floor(Date.now()/1000);
   if(url.pathname==="/health" && req.method==="GET")return json({ok:true,schema:2});
   if(url.pathname==="/v2/session" && req.method==="POST"){
    if(env.INGEST_ENABLED!=="true")return json({error:"disabled"},503);
    if(!env.INGEST_LIMIT)return json({error:"disabled"},503);
    const ip=req.headers.get("CF-Connecting-IP")||"unknown";
    if(!(await env.INGEST_LIMIT.limit({key:ip})).success)return json({error:"rate limit"},429);
    const x=await boundedJson(req);if(!valid(x))return json({error:"invalid payload"},400);
    await env.DB.prepare(UPSERT).bind(x.id,x.version,x.mode,x.difficulty,x.seconds,x.wins,x.losses,x.sector,now,now).run();
    return reply(null,204);
   }
   if((url.pathname==="/"||url.pathname==="/api/summary")&&req.method==="GET"){
    if(!env.ADMIN_LIMIT || !(await env.ADMIN_LIMIT.limit({key:req.headers.get("CF-Connecting-IP")||"unknown"})).success)return reply("Rate limited",429);
    if(!await authorized(req,env))return reply("Authentication required",401,{"WWW-Authenticate":'Basic realm="SAPERROR Analytics", charset="UTF-8"'});
    const d=await summary(env.DB,now);
    return url.pathname==="/" ? reply(dashboard(d),200,{"Content-Type":"text/html; charset=utf-8"}) : json(d);
   }
   return reply("Not found",404);
  }catch{return json({error:"service unavailable"},503)}
 },
 async scheduled(_event,env,ctx){ctx.waitUntil(env.DB.prepare("DELETE FROM sessions WHERE updated < ?").bind(Math.floor(Date.now()/1000)-30*86400).run())}
};
