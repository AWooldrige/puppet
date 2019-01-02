node /^hplaptop\d+$/ {
    include laptop
}
node /^desktop\d+$/ {
    include desktop
}

node /^pi\d{1,3}$/ {
    include pi
}
