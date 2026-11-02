import QtQuick
import qs.Common

Canvas {
    id:root
    property string profile:"normal"
    property var curves:({
        normal:[0.5,0.5,0.5,0.5,0.5], bass:[0.78,0.65,0.5,0.48,0.46],
        soft:[0.56,0.56,0.52,0.48,0.46], dynamic:[0.7,0.6,0.48,0.39,0.64],
        clear:[0.38,0.43,0.5,0.61,0.72], treble:[0.3,0.4,0.52,0.66,0.8]
    })
    onProfileChanged:requestPaint()
    onWidthChanged:requestPaint()
    onHeightChanged:requestPaint()
    Accessible.name:"Illustrative profile shape for "+root.profile+"; not a measured frequency response"

    onPaint: {
        const ctx=getContext("2d");
        ctx.clearRect(0,0,width,height);
        const values=curves[profile] || curves.normal;
        const inset=8, plotWidth=width-inset*2, plotHeight=height-14;
        ctx.strokeStyle=Theme.withAlpha(Theme.outline,0.24).toString();
        ctx.lineWidth=1;
        for(let i=1;i<=3;i++) {
            const y=plotHeight*i/4;
            ctx.beginPath(); ctx.moveTo(inset,y); ctx.lineTo(width-inset,y); ctx.stroke();
        }
        ctx.beginPath();
        values.forEach((value,index)=>{
            const x=inset+plotWidth*index/(values.length-1);
            const y=5+value*plotHeight;
            if(index===0) ctx.moveTo(x,y);
            else {
                const px=inset+plotWidth*(index-1)/(values.length-1);
                const py=5+values[index-1]*plotHeight;
                const mid=(px+x)/2;
                ctx.bezierCurveTo(mid,py,mid,y,x,y);
            }
        });
        ctx.lineWidth=2.4;
        ctx.lineCap="round";
        ctx.lineJoin="round";
        ctx.strokeStyle=Theme.primary.toString();
        ctx.stroke();
        values.forEach((value,index)=>{
            const x=inset+plotWidth*index/(values.length-1), y=5+value*plotHeight;
            ctx.beginPath(); ctx.arc(x,y,3,0,Math.PI*2);
            ctx.fillStyle=Theme.primary.toString(); ctx.fill();
            ctx.beginPath(); ctx.arc(x,y,1.2,0,Math.PI*2);
            ctx.fillStyle=Theme.surface.toString(); ctx.fill();
        });
    }
}
