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
import {summary,dashboard,filters} from "./dashboard.mjs";
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
    if(x.version.endsWith(".pilot"))return json({error:"pilot retired"},403);
    await env.DB.prepare(UPSERT).bind(x.id,x.version,x.mode,x.difficulty,x.seconds,x.wins,x.losses,x.sector,now,now).run();
    return reply(null,204);
   }
   if((url.pathname==="/"||url.pathname==="/api/summary")&&req.method==="GET"){
    if(!env.ADMIN_LIMIT || !(await env.ADMIN_LIMIT.limit({key:req.headers.get("CF-Connecting-IP")||"unknown"})).success)return reply("Rate limited",429);
    if(!await authorized(req,env))return reply("Authentication required",401,{"WWW-Authenticate":'Basic realm="SAPERROR Analytics", charset="UTF-8"'});
    const filter=filters(url.searchParams);const d=await summary(env.DB,now,filter);
    return url.pathname==="/" ? reply(dashboard(d,filter,env.INGEST_ENABLED==="true"),200,{"Content-Type":"text/html; charset=utf-8"}) : json(d);
   }
   return reply("Not found",404);
  }catch{return json({error:"service unavailable"},503)}
 },
 async scheduled(_event,env,ctx){ctx.waitUntil(env.DB.prepare("DELETE FROM sessions WHERE updated < ?").bind(Math.floor(Date.now()/1000)-30*86400).run())}
};
