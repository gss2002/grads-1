#!/bin/csh -f
#########################################################
#THIS IS THE HOLY GRAIL OF RUNNER SCRIPTS				#		
#########################################################
#PURPOSE: RUN MODELS PROMPTLY!							#
#DESCRIPTION: THIS SCRIPT KICKS OFF MODEL RUNNERS		#
#LAST EDIT:  01/20/2016  GENSINI						#
#########################################################
#CHANGE TO WORKING DIRECTORY
cd /home/scripts/grads/kickers
#FIND CORRECT MODEL TIME
set modtime = $1
#PATH AND NAME OF MODEL RUNNER SCRIPT:
set Runner = "/home/scripts/grads/runners/rap_runner.csh"
if (`date -u +%H` < $modtime) then
	set dtstr = `date -u --date="yesterday" +%y%m%d`
else
	set dtstr = `date -u +%y%m%d`
endif
set datadir = "/home/data/models/rap"
###############################################
#BEGIN SNAKE LOOP TO CHECK FOR AVAILABLE TIMES#
###############################################
foreach FHour (000 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020 021)
	set filename = ${datadir}/${dtstr}${modtime}00F${FHour}.rap
	set filegrids = `/usr/local/bin/wgrib2 ${filename} | tail -n1 | sed 's/ *:.*//'`
	set filegrids = `/usr/bin/printf '%.0f' ${filegrids}` # To make sure it's an integer
	#CHECK TO SEE IF FILE EXISTS AND IT IS GREATER THAN xx SIZE. IF NO NEW, SLEEP FOR 10s
	@ count = 0
	echo "count='${count}'"
	echo "filegrids='${filegrids}'"
	if ($FHour == 000) then
		while (($count < 222) && ($filegrids < 280))
			sleep 10
			set filegrids = `/usr/local/bin/wgrib2 ${filename} | tail -n1 | sed 's/ *:.*//'`
			set filegrids = `/usr/bin/printf '%.0f' ${filegrids}` # To make sure it's an integer
			@ count = $count + 1
			echo "count='${count}'"
			echo "filegrids='${filegrids}'"
		end
	else
		while (($count < 150) && ($filegrids < 275))
			sleep 3
			set filegrids = `/usr/local/bin/wgrib2 ${filename} | tail -n1 | sed 's/ *:.*//'`
			set filegrids = `/usr/bin/printf '%.0f' ${filegrids}` # To make sure it's an integer
			@ count = $count + 1
		end
	endif
	if ($FHour == 021) then
		nice +10 /usr/local/bin/wgrib2 ${filename} -small_grib -140:-55 17:60 ${filename}c
		csh $Runner $modtime RAP $FHour
		ssh -p31950 climate /usr/bin/php /home/scripts/models/blister.php RAP $modtime $FHour
		echo `date` ": ${modtime}Z RAP Finished" >> /home/apache/atlas/data/forecast/text/raptimes.txt
	else
		if ($FHour == 000) then
			echo `date` ": ${modtime}Z RAP Starting" >> /home/apache/atlas/data/forecast/text/raptimes.txt
			nice +10 /usr/local/bin/wgrib2 ${filename} -small_grib -140:-55 17:60 ${filename}c
			csh $Runner $modtime RAP $FHour
			perl /home/scripts/models/newclearmodeldir.pl $modtime RAP
		else
			nice +10 /usr/local/bin/wgrib2 ${filename} -small_grib -140:-55 17:60 ${filename}c
			csh $Runner $modtime RAP $FHour
		endif			
		ssh -p31950 climate /usr/bin/php /home/scripts/models/blister.php RAP $modtime $FHour
	endif
end	
exit
