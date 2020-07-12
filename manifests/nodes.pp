node /^hplaptop\d+$/ {
    include laptop
}
node /^laptop.+$/ {
    include laptop
}
node /^desktop\d+$/ {
    include desktop
}

node /^webpi$/ {
    include webpi
}
node /^epaperpi$/ {
    include epaperpi
}
