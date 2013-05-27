
# set -x

PinInit()
{
    # Make omap_mux avalibe via the file-system
    mount -t debugfs none /sys/kernel/debug

    # Show MUX configuration 
    cat /sys/kernel/debug/omap_mux/gpmc_ad9
    
    # Configure the MUX
    echo 0x1b > /sys/kernel/debug/omap_mux/gpmc_ad9
    sleep 1

    # Export GPIO pin 33
    echo 33 > /sys/class/gpio/export
    sleep 1

    # Set direction of of the pin20 J6
    # Use pin6 of GND
    echo out > /sys/class/gpio/gpio33/direction
    sleep 1
}

PinRun()
{ 
while [ 1 ]
do
   # Turn pin on
   echo 1 > /sys/class/gpio/gpio33/value
   usleep 50000
   # Turn pin off
   echo 0 > /sys/class/gpio/gpio33/value
   TT=$RANDOM
#   echo $TT  
   usleep $TT 
   usleep 10000
done
}


if [ $# -eq 1 ]
then 
    PinInit 
fi

PinRun 


