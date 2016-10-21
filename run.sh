#!/bin/bash

usage="$(basename "$0") [-h] [-c] [-n] [-t] [-w=word] -- runs the magic trick called transdutores
where:
    -h show this help message
    -c cleans the directory with the outputs
    -n doesn't compile the 'transdutores'
    -t tests with a input file in the directory
    -w=word gives the output with word as input"

. config.sh
#################################### HELPFUL FUNCTIONS #####################################
function compile {
    rm -rf target/
    mkdir ./target/

    fstcompile --isymbols=syms.txt --osymbols=syms.txt  step4/step4.txt | fstarcsort > target/step4.fst
    fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt  target/step4.fst | dot -Tpdf  > target/step4.pdf 

    fstcompile --isymbols=syms.txt --osymbols=syms.txt  step2/step2.txt | fstarcsort > target/step2.fst
    fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt  target/step2.fst | dot -Tpdf  > target/step2.pdf 

    fstcompile --isymbols=syms.txt --osymbols=syms.txt  step1/s2z.txt | fstarcsort > target/s2z.fst

    fstcompile --isymbols=syms.txt --osymbols=syms.txt step1/x2zs.txt | fstarcsort > target/x2zs.fst

    fstcompose target/s2z.fst target/x2zs.fst > target/step1.fst
    fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt  target/step1.fst | dot -Tpdf  > target/step1.pdf 

    fstcompile --isymbols=syms.txt --osymbols=syms.txt  step3/rule1-3.txt | fstarcsort > target/rule1-3.fst
    fstcompile --isymbols=syms.txt --osymbols=syms.txt  step3/rule4-and-7.txt | fstarcsort > target/rule4-and-7.fst
    fstcompile --isymbols=syms.txt --osymbols=syms.txt  step3/rule5-6.txt | fstarcsort > target/rule5-6.fst

    fstcompose target/rule1-3.fst target/rule4-and-7.fst > target/step3-aux.fst
    fstcompose target/step3-aux.fst target/rule5-6.fst > target/step3.fst
    fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt  target/step3.fst | dot -Tpdf  > target/step3.pdf 
    rm target/step3-aux.fst

    #gerar o final

    fstcompose target/step1.fst target/step2.fst > target/step1-2.fst
    fstcompose target/step1-2.fst target/step3.fst > target/step12-3.fst
    fstcompose target/step12-3.fst target/step4.fst > target/transdutorFinal.fst
    fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt  target/transdutorFinal.fst | dot -Tpdf  > target/transdutorFinal.pdf 
    
}

function generate_inputs {
    mkdir -p target/tests
    rm -f target/tests/*
    while IFS='' read -r line || [[ -n "$line" ]]; do
        python scripts/word2fst.py $line >target/tests/word-$line.txt
        fstcompile --isymbols=syms.txt --osymbols=syms.txt target/tests/word-$line.txt | fstarcsort > target/tests/word-$line.fst
    done < "$INPUT"
}

function run_tests {
    while IFS='' read -r line || [[ -n "$line" ]]; do
        fstcompose target/tests/word-$line.fst target/transdutorFinal.fst | fstshortestpath  > target/resultado-Final.fst
        fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt  target/resultado-Final.fst | dot -Tpdf  > target/tests/out-$line.pdf 
        fstproject --project_output target/resultado-Final.fst | fstrmepsilon | fstprint --acceptor --isymbols=./syms.txt > target/tests/resultado-$line.txt
        python scripts/fst2word.py target/tests/resultado-$line.txt $OUTPUT
    done < "$INPUT"
    rm target/resultado-Final.fst
}

function get_value {
    echo $WORD
    python scripts/word2fst.py $WORD > target/$WORD.txt
    fstcompile --isymbols=syms.txt --osymbols=syms.txt target/$WORD.txt | fstarcsort > target/$WORD.fst
    fstcompose target/$WORD.fst target/transdutorFinal.fst | fstshortestpath | fstproject --project_output | fstrmepsilon | fstprint --acceptor --isymbols=./syms.txt > target/$WORD-transf.txt
    python scripts/fst2word.py target/$WORD-transf.txt    
}
################################################################################################

for i in "$@"; do
    case $i in
        -n|--nocompile)
           COMPILE=0
            shift
        ;;
        -t|--test)
            TEST=1
            shift
        ;;
        -h|--help)
            HELP=1
            shift
        ;;
        -c|--clean)
            CLEAN=1
            shift
        ;;
        -w=*|--word=*)
            GETVALUE=1
            WORD="${i#*=}"
            shift
        ;;
    esac
done

if [ $HELP -eq 1 ]; then
    echo "$usage"
    exit 0
fi

if [ $CLEAN -eq 1 ]; then   
    rm -rf target/
    exit 0 
fi

if [ $COMPILE -eq 1 ]; then
    compile
fi

if [ $TEST -eq 1 ]; then
    generate_inputs
    run_tests
fi

if [ $GETVALUE -eq 1 ]; then
    get_value
fi
# obligatory testing (last name of the elements of the group)
fstcompile --isymbols=syms.txt --osymbols=syms.txt ascensao.txt | fstarcsort > target/ascensao.fst
fstcompile --isymbols=syms.txt --osymbols=syms.txt rebelo.txt | fstarcsort > target/rebelo.fst

fstcompose target/ascensao.fst target/transdutorFinal.fst | fstshortestpath | fstrmepsilon > target/ascensao-transf.fst
fstcompose target/rebelo.fst target/transdutorFinal.fst | fstshortestpath | fstrmepsilon > target/rebelo-transf.fst

fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt  target/ascensao-transf.fst | dot -Tpdf  > target/ascensao.pdf 
fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt  target/rebelo-transf.fst | dot -Tpdf  > target/rebelo.pdf 

