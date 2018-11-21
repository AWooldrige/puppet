node /^hplaptop\d+$/ {
    include basenode::laptop
}

# Note that I haven't got round to changing the hostname of that
# actual PI to fit the convention
node /^pi-\d{1,3}.woolie.co.uk$/ {
    include basenode::desktop::raspi
}
node /^pi-\d{1,3}.(phys|virt).woolie.co.uk$/ {
    include basenode::desktop::raspi
}
