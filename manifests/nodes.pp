node /^hplaptop\d+$/ {
    include laptop
}
node /^laptop.+$/ {
    include laptop
}
node /^desktop\d+$/ {
    include desktop
}

node /^pi2$/ {
    include kitchentvpi
}
node /^pi3$/ {
    include livingroomtvpi
}
