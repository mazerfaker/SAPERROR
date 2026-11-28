const modes = new Set(["campaign","free","endless","classic","lab"]);
const fields = ["schema","id","version","mode","difficulty","seconds","wins","losses","sector"];
const integer = (x,min,max) => Number.isInteger(x) && x>=min && x<=max;
export function valid(x) {
 return x && typeof x==="object" && !Array.isArray(x) &&
 Object.keys(x).length===fields.length && fields.every(k=>Object.hasOwn(x,k)) &&
 x.schema===2 && typeof x.id==="string" && /^[a-f0-9]{32}$/.test(x.id) &&
 typeof x.version==="string" && /^\d{1,3}\.\d{1,3}\.\d{1,3}(?:-[a-z0-9.]{1,24})?$/.test(x.version) &&
 modes.has(x.mode) && integer(x.difficulty,0,4) && integer(x.seconds,0,86400) &&
 integer(x.wins,0,10000) && integer(x.losses,0,10000) && integer(x.sector,0,10000);
}
