/^#/ && !/^# RG/ {
    header = header $0 "\n"
    next
}

/^ST/ {
    file = $2 ".st"

    if (!(file in seen)) {
        printf "%s", header > file
        seen[file] = 1
    }

    print >> file
}
