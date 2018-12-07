node /^desktop\d+$/ {
    include basenode::desktop
}

node /^hplaptop\d+$/ {
    include basenode::laptop::lowpwr
}

node /^pi\d+$/ {
    include basenode::raspi
}
