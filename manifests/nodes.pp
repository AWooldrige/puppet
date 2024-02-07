node /^hplaptop\d+/ {
    include laptop
}
node /^laptop.+/ {
    include laptop
}
node /^desktop\d+/ {
    include desktop
}
node /^lenovoaio\d+/ {
    include desktop
}

node /^webpi/ {
    include webpi
}
node /^epaperpi/ {
    include epaperpi
}
node /^boilerpi/ {
    include boilerpi
}
node /^webprimary/ {
    include webprimary
}
