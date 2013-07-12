#!/bin/bash

if ! [ -d data ]
then
	echo "Error: directory data not found!" >&2
	exit 1
fi

if ! [ -e prepare.c ]
then
	echo "Error: program prepare.c not found!" >&2
	exit 1
fi

echo "   ============= Compiling Phrase ============="
make prepare || exit 1

if ! [ -x multisvm_1.0 ]
then
	echo "Error: excutable multisvm_1.0 not found!" >&2
	exit 1
fi

# tname=( adult web mnist usps usps shuttle letter )  #  mnist ) mnist_ova case crashed
# tstag=(  bin  bin  bin   bin  ova   ova    ova   )  #   ova  )
# tcode=(   2    2    2     2    0     0      0    )  #    0   )
tname=( mnist adult web usps usps shuttle letter adult web usps shuttle )
tstag=(  bin   bin  bin  bin  ova   ova    ova    ava  ava  ava   ava   )
tcode=(   2     2    2    2    0     0      0      1    1    1     1    )
ncase=${#tname[@]}

pref=( RBF1 RBF2 POLY )
kern=(    0    0    2 )
beta=(  0.5 0.25    0 )
   a=(    0    0    1 )
   b=(    0    0    1 )
   d=(    0    0    2 )
nker=${#pref[@]}

for k in `seq 0 $(( nker - 1 ))`
do
	cmddir="${pref[$k]}_cmd"
	outdir="${pref[$k]}_out"
	[ -d "$cmddir" ] || mkdir "$cmddir"
	[ -d "$outdir" ] || mkdir "$outdir"

	for i in `seq 0 $(( ncase - 1 ))`
	do
		testfilename="data/${tname[$i]}/"`ls "data/${tname[$i]}" | grep '\.t$'`
		trainfilename=${testfilename:0:-2}
		tmp=( `./prepare "$trainfilename"` )
		ntraining=${tmp[0]}; nfeatures=${tmp[1]}; nclasses=${tmp[2]}
		ntesting=`wc -l "$testfilename" | cut -d " " -f 1`

		if [ "${tstag[$i]}" == "bin" ]
		then
			ntasks=1
		elif [ "${tstag[$i]}" == "ova" ]
		then
			ntasks=$nclasses
		elif [ "${tstag[$i]}" == "ava" ]
		then
			ntasks=$(( nclasses * (nclasses - 1) / 2 ))
		else
			echo "Error: unexpected strategy code ${tstag[$i]}" >&2
			continue
		fi

		printf "\n   ============= Running Test ${tname[$i]} (${pref[$k]},${tstag[$i]}) ==============\n\n"
		echo "./multisvm_1.0 "$trainfilename" $ntraining $nfeatures $testfilename \
			$ntesting ${tcode[$i]} $nclasses $ntasks 100.00 0.001 ${kern[$k]} \
			 ${beta[$k]} ${a[$k]} ${b[$k]} ${d[$k]}" | tee "$cmddir/${tname[$i]}_${tstag[$i]}.cmd"
		`cat "$cmddir/${tname[$i]}_${tstag[$i]}.cmd"` | tee "$outdir/${tname[$i]}_${tstag[$i]}.out"
			# execuate multisvm program
	done
done

rm prepare -f
echo "done!"
