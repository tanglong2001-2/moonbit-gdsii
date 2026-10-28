"""Independent file-to-Node-consumer check. Test-only: pip install gdstk==1.0.2."""
from pathlib import Path
import json,sys,subprocess,struct,random,tempfile
import gdstk
ROOT=Path(__file__).resolve().parent.parent

def canonical(points):
    p=[tuple(x) for x in points]
    if p and p[0]==p[-1]:p.pop()
    return min([p[i:]+p[:i] for i in range(len(p))]+[p[::-1][i:]+p[::-1][:i] for i in range(len(p))])
def consume(data,**kw):
    req=dict(hex=data.hex(),cell='top',layer=7,datatype=2,width=3,spacing=5);req.update(kw)
    result=subprocess.run(['node',str(ROOT/'_build/js/debug/build/cmd/inspect/inspect.js')],input=json.dumps(req),capture_output=True,text=True)
    assert result.returncode==0,(result.stdout,result.stderr)
    return json.loads(result.stdout)
def xy_from_file(data):
    out=[];pos=0;layer=dtype=0
    while pos+4<=len(data):
        n,k,t=struct.unpack_from('>HBB',data,pos)
        if n<4:break
        d=data[pos+4:pos+n];pos+=n
        if k==13:layer=struct.unpack('>H',d)[0]
        if k==14:dtype=struct.unpack('>H',d)[0]
        if k==16:
            a=struct.unpack('>'+'i'*(len(d)//4),d)
            out.append((layer,dtype,canonical(zip(a[::2],a[1::2]))))
    return sorted(out)

def main():
    checks=[]
    for name in ['nested','arbitrary','array']:
        path=ROOT/'testdata'/f'{name}.gds'
        response=consume(path.read_bytes());assert 'error' not in response,response
        lib=gdstk.read_gds(path);lib['top'].flatten()
        flat=gdstk.Library(unit=1,precision=1);flat.add(lib['top'])
        with tempfile.TemporaryDirectory() as td:
            f=Path(td)/'flat.gds';flat.write_gds(f)
            expected=xy_from_file(f.read_bytes())
        actual=sorted((s['layer'],s['datatype'],canonical((p['x'],p['y']) for p in s['points'])) for s in response['flattened']['shapes'])
        assert actual==expected,(name,actual,expected)
        checks.append(dict(case=name,polygons=len(actual),exact_dbu=True))
    # Original licensed caller-owned file with boxes, triangles, PATH and label.
    with tempfile.TemporaryDirectory() as td:
        lib=gdstk.Library(unit=1,precision=1);top=lib.new_cell('top')
        boxes=[(0,0,10,10),(10,0,20,10),(5,5,15,15),(21,11,22,12)]
        for x0,y0,x1,y1 in boxes:top.add(gdstk.rectangle((x0,y0),(x1,y1),layer=7,datatype=2))
        top.add(gdstk.Polygon([(30,0),(40,0),(35,4)],layer=7,datatype=2))
        top.add(gdstk.FlexPath([(50,0),(60,0)],2,layer=7,datatype=2,simple_path=True))
        top.add(gdstk.Label('retained',(70,0),layer=7,texttype=2))
        f=Path(td)/'mixed.gds';lib.write_gds(f);data=f.read_bytes()
        out=consume(data,width=3,spacing=2)
        assert len(out['selection']['rects'])==4,out
        assert len(out['selection']['warnings'])==3,out
        # Decimal-free arbitrary precision arithmetic; independent of sweep/index.
        pairs=set();width_ids=set()
        for i,a in enumerate(boxes):
            if min(a[2]-a[0],a[3]-a[1])<3:width_ids.add(i)
            for j,b in enumerate(boxes[:i]):
                dx=max(a[0]-b[2],b[0]-a[2],0);dy=max(a[1]-b[3],b[1]-a[3],0)
                if dx*dx+dy*dy<4:pairs.add((j,i))
        got_pairs=set();got_width=set()
        for v in out['drc']['violations']:
            if v[0]=='MinimumWidth':got_width.add(v[1])
            elif v[0]=='MinimumSpacing':got_pairs.add((v[1],v[2]))
        assert got_pairs==pairs and got_width==width_ids,(out['drc'],pairs,width_ids)
        checks.append(dict(case='mixed_file_consumer',rectangles=4,skip_findings=3,spacing_pairs=len(pairs),width_findings=len(width_ids)))
        bad=consume(data[:-1]);assert 'error' in bad
        bad=consume(data,cell='missing');assert 'error' in bad
        bad=consume(data,width=-1);assert 'error' in bad
        checks.append(dict(case='consumer_failures',checked=['truncated stream','missing cell','invalid threshold']))
    print(json.dumps(dict(gdstk=gdstk.__version__,checks=checks,status='PASS'),indent=2))

if __name__=='__main__':main()
