/^#/ && !/^# ST/ {
    header = header $0 "\n"
    next
}

/^RG/ {
    file = $2 ".rg"

    if (!(file in seen)) {
        printf "%s", header > file
        seen[file] = 1
    }

    print >> file
}
