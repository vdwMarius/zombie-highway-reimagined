from pathlib import Path
import numpy as np
from PIL import Image,ImageFilter,ImageDraw
out=Path(__file__).resolve().parents[1] / 'assets' / 'surfaces';out.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(429); n=1024

def octave(size,scale):
 a=Image.fromarray(rng.integers(0,255,(scale,scale),dtype=np.uint8))
 return np.asarray(a.resize((size,size),Image.Resampling.BICUBIC),dtype=float)/255
noise=sum(octave(n,s)*w for s,w in [(8,.26),(32,.24),(128,.2),(512,.2),(1024,.1)])
fine=rng.normal(0,1,(n,n));yy,xx=np.mgrid[:n,:n]
# Original tileable aggregate asphalt, roughness and micro-surface normal.
base=30+noise*25+fine*3.2
for name,channels in [('asphalt',[.91,.98,1.05]),('concrete',[1.03,1.0,.94])]:
 v=base if name=='asphalt' else 85+noise*53+fine*1.8
 im=np.stack([v*c for c in channels],axis=-1).clip(0,255).astype('uint8')
 if name=='concrete':
  lines=((xx%512<2)|(yy%512<2));im[lines]=(im[lines]*.62).astype('uint8')
 Image.fromarray(im).save(out/(name+'_color.jpg'),quality=94)
 rough=(.68+noise*.22) if name=='asphalt' else (.3+noise*.3)
 Image.fromarray((rough*255).clip(0,255).astype('uint8')).save(out/(name+'_rough.jpg'),quality=94)
 height=Image.fromarray((noise*255).astype('uint8')).filter(ImageFilter.GaussianBlur(.7))
 h=np.asarray(height,dtype=float)/255
 dx=(np.roll(h,-1,axis=1)-np.roll(h,1,axis=1))*3;dy=(np.roll(h,-1,axis=0)-np.roll(h,1,axis=0))*3
 normal=np.stack([-dx,-dy,np.ones_like(dx)],axis=-1);normal/=np.linalg.norm(normal,axis=-1)[...,None]
 Image.fromarray(((normal*.5+.5)*255).astype('uint8')).save(out/(name+'_normal.png'))
# Layered plaster and stained wood, all generated from original noise.
plaster=np.stack([(125+noise*46)*c for c in [1.0,.99,.94]],axis=-1)
Image.fromarray(plaster.clip(0,255).astype('uint8')).save(out/'plaster.jpg',quality=92)
grain=(np.sin(xx*.14+octave(n,16)*18)+1)*.5; wood=grain*14+noise*45+60
Image.fromarray(np.stack([wood*1.12,wood*.72,wood*.42],axis=-1).clip(0,255).astype('uint8')).save(out/'wood.jpg',quality=94)
rock=65+noise*66
Image.fromarray(np.stack([rock*1.14,rock*.98,rock*.8],axis=-1).clip(0,255).astype('uint8')).save(out/'rock.jpg',quality=93)
print('Generated original PBR surface textures')
# Original cutout evergreen. Many small needle strokes retain detail at distance.
import random,math
prng=random.Random(1947)
tree=Image.new('RGBA',(512,1024));d=ImageDraw.Draw(tree)
d.line((256,990,252,70),fill=(66,60,45,255),width=15)
for y in range(140,960,13):
 extent=int((y/1024)**.8*205*(.9+prng.random()*.1))
 for side in [-1,1]:
  endx=256+side*extent;endy=y+prng.randint(5,38)
  d.line((256,y,endx,endy),fill=(46,55,41,255),width=4)
  for step in range(7,extent,5):
   bx=256+side*step;by=y+(endy-y)*step/max(1,extent)
   for needle in range(7):
    ox=prng.randint(-22,22);oy=prng.randint(-27,19)
    c=prng.randint(35,66)
    d.line((bx,by,bx+ox,by+oy),fill=(int(c*.72),c,int(c*.67),255),width=prng.randint(1,3))
tree.save(out/'evergreen.png')
