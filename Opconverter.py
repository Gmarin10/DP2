r = open("codes.txt", 'r')
count = 1
doc = ""
newline = ""
for line in r:
    if(count%2 == 1):
        newline=line
        newline=newline.replace(" ", "")
        newline=newline.replace("s", "_s")
        newline=newline.replace("a","_a")
        newline=newline.replace("a,x","_a,x")
        newline=newline.replace("a,y","_a,y")
        newline=newline.replace("al","_al")
        newline=newline.replace("al,x","_al,x")
        newline=newline.replace("(a)","_(a)")
        newline=newline.replace("(a,x)","_(a,x)")
        newline=newline.replace("d","_d")
        newline=newline.replace("d,s","_d,s")
        newline=newline.replace("d,x","_d,x")
        newline=newline.replace("d,y","_d,y")
        newline=newline.replace("(d)","_(d)")
        newline=newline.replace("[d]","_[d]")
        newline=newline.replace("(d,s),y","_(d,s),y")
        newline=newline.replace("(d,x)","_(d,x)")
        newline=newline.replace("(d),y","_(d),y") 
        newline=newline.replace("[d],y","_[d],y")
        newline=newline.replace("i","_i")
        newline=newline.replace("r","_r")
        newline=newline.replace("rl","_rl")
        newline=newline.replace("xyc","_xyc")
        newline=newline.replace("#", "_#")
        newline=newline.replace(",", "/")
        doc+=newline[:-1]+',\n'
    count+=1

n = open("codes2.txt",'w')
n.write(doc)
n.close()
