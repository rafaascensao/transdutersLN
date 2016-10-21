import sys

inFile = sys.argv[1]

newDict = {}
result = ''

with open(inFile, 'r') as i:
    lines = i.readlines()

for line in lines:
    if line[0] != '0':
        newDict[line[0]] = line[4]

keysDecreasing = sorted(newDict.keys(), reverse=True)

for key in keysDecreasing:
    result += newDict[key]

if len(sys.argv) >=3:
    outFile = sys.argv[2]
    with open(outFile, 'a') as o:
        o.write(result + '\n')        
else:
    print(result + '\n')  
