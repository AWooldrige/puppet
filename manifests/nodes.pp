node /^hplaptop\d+$/ {
    include laptop
}
node /^desktop\d+$/ {
    include desktop
}

# Note that I haven't got round to changing the hostname of that
# actual PI to fit the convention
node /^pi-\d{1,3}.woolie.co.uk$/ {
    include raspi
}
node /^pi-\d{1,3}.(phys|virt).woolie.co.uk$/ {
    include raspi
}
