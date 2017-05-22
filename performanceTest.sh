apt-get install libmagick9-dev, php5-dev
wget http://downloads.sourceforge.net/project/graphicsmagick/graphicsmagick/1.3.17/GraphicsMagick-1.3.17.tar.gz
tar -xvf GraphicsMagick-1.3.17.tar.gz
cd GraphicsMagick-1.3.17
#Choose on of these (read below for more information
./configure CFLAGS=-fPIC --enable-shared --without-x
./configure CFLAGS=-fPIC --enable-shared --disable-openmp --without-x
./configure CFLAGS=-fPIC --enable-shared --enable-openmp-slow --without-x
##
 
make
make check
checkinstall
apt-get install php-pear
pecl install gmagick-1.1.1RC1
 
echo "extension=gmagick.so" > /etc/php5/conf.d/gmagick.ini
/etc/init.d/apache2 restart


#!/bin/bash
#performance testing to find the optimal threading for your specific graphicsmagick workload
 
i=0
cpunumber=0
cpu2=$((cpunumber+1))
taskset=""
threads=$1
num_iter=10
dir="/some/dir/with/images/larger/than/975x548/in/it/"
array=(975x548 620x348 480x270 310x174 290x163 280x157 240x135 200x112 140x79 130x73 123x69)
last_cpu=$(grep "^processor" /proc/cpuinfo | awk '{print $3}' | tail -n1)
 
#these are equivalent, you only need to define one of them.
export OMP_NUM_THREADS="$threads"
export PARALLEL="$threads"
 
Convert() {
#echo "Converting $name into ${array[@]}"
 
###Choose one###
#
#Or time taskset -c $cpunumber,$cpu2 /usr/local/bin/gm convert "$x" +profile "*" -unsharp 1x1+1+0.05 \
#Or time numactl --physcpubind=$cpunumber,$cpu2 /usr/local/bin/gm convert "$x" +profile "*" -unsharp 1x1+1+0.05 \
#Or time taskset -c $cpunumber /usr/local/bin/gm convert "$x" +profile "*" -unsharp 1x1+1+0.05 \
#Or (default) time /usr/local/bin/gm convert "$x" +profile "*" -unsharp 1x1+1+0.05 \
################
 
time /usr/local/bin/gm convert "$x" +profile "*" -unsharp 1x1+1+0.05 \
 -resize "${array[0]}" -quality 85 -write Iteration_"$i"_s"${array[0]}"_"$name"\
 -resize "${array[1]}" -quality 85 -write Iteration_"$i"_s"${array[1]}"_"$name"\
 -resize "${array[2]}" -quality 85 -write Iteration_"$i"_s"${array[2]}"_"$name"\
 -resize "${array[3]}" -quality 85 -write Iteration_"$i"_s"${array[3]}"_"$name"\
 -resize "${array[4]}" -quality 85 -write Iteration_"$i"_s"${array[4]}"_"$name"\
 -resize "${array[5]}" -quality 85 -write Iteration_"$i"_s"${array[5]}"_"$name"\
 -resize "${array[6]}" -quality 85 -write Iteration_"$i"_s"${array[6]}"_"$name"\
 -resize "${array[7]}" -quality 85 -write Iteration_"$i"_s"${array[7]}"_"$name"\
 -resize "${array[8]}" -quality 85 -write Iteration_"$i"_s"${array[8]}"_"$name"\
 -resize "${array[9]}" -quality 85 -write Iteration_"$i"_s"${array[9]}"_"$name"\
 -resize "${array[10]}" -quality 85 Iteration_"$i"_s"${array[10]}"_"$name"
 
#echo "Iteration $i for $name completed"
 
}
 
#while loop calling number iterations ($num_iter)
while [ $i -lt $num_iter  ]
do
 
        for x in $(find "$dir" -type f); #runs
                        do
                                name="${x##*/}"
 
                                        if (($cpunumber == $last_cpu));
                                                then
                                                        cpunumber=0
                                        fi
 
                                Convert &> THREADS"$threads"taskset_yes_Or_no" &
 
                                        ((cpunumber++))
                                        cpu2=$(($cpunumber+1))
                        done
 
((i++))
done