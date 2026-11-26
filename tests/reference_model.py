"""Independent Python mathematical check, NOT execution of GDScript.
Uses Python PRNG (not Godot's), same design constraints; validates proof soundness.
"""
import random
from itertools import combinations
from collections import deque

def neighbors(i):
    x,y=i%8,i//8
    return frozenset(8*(y+dy)+x+dx for dx in (-1,0,1) for dy in (-1,0,1)
                     if (dx or dy) and 0<=x+dx<8 and 0<=y+dy<8)
N=[neighbors(i) for i in range(64)]
ALL=frozenset(range(64))

def certify(mask,first):
    opened=set(); known=set(); steps=0
    def reveal(i):
        q=deque([i])
        while q:
            i=q.popleft()
            if i in opened: continue
            assert i not in mask
            opened.add(i)
            if not N[i]&mask: q.extend(N[i]-opened)
    reveal(first)
    while len(opened)<54:
        unknown=ALL-opened-known
        raw=[(N[i],len(N[i]&mask)) for i in sorted(opened)]+[(ALL,10)]
        cs=[(s&unknown,k-len(s&known)) for s,k in raw]
        assert all(0<=k<=len(s) for s,k in cs)
        proof=next(((s,k) for s,k in cs if s and k in (0,len(s))),None)
        if proof is None:
            for a,ka in cs:
                for b,kb in cs:
                    if a<b and kb-ka in (0,len(b-a)):
                        proof=(b-a,kb-ka);break
                if proof: break
        if proof is None:return False,steps
        s,k=proof
        assert len(s&mask)==k, 'unsound deduction'
        if k:known.update(s)
        else:
            for i in sorted(s):reveal(i)
        steps+=1
        assert steps<=64
    return True,steps

def fallback(first):
    safe=N[first]|{first}
    for side in range(4):
        for offset in range(7):
            mask={ [j,56+j,j*8,j*8+7][side] for j in range(8) }
            mask.update([8+j,48+j,j*8+1,j*8+6][side] for j in range(offset,offset+2))
            if mask&safe:continue
            if certify(mask,first)[0]:return True
    return False

def generate(seed,first):
    rng=random.Random(seed)
    allowed=sorted(ALL-N[first]-{first})
    for attempt in range(64):
        mask=set(rng.sample(allowed,10))
        ok,steps=certify(mask,first)
        if ok:return attempt+1,steps
    assert fallback(first)
    return 65,0

if __name__=='__main__':
    assert all(fallback(i) for i in range(64))
    results=[generate(seed,(seed*37)%64) for seed in range(1000)]
    print('Independent Python reference, not Godot runtime')
    print('Fallback patterns certified for first-click positions: 64/64')
    print('Python seed cases certified: 1000/1000')
    print('Unsound accepted deductions: 0 (assertions enabled)')
    print('Fallback uses:',sum(a==65 for a,_ in results))
    print('Maximum candidate attempts:',max(a for a,_ in results))
    print('Maximum proof batches:',max(s for _,s in results))
