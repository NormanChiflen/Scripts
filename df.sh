DF=df

mock_df_with_eols() {
    cat <<- EOF
    Filesystem           1K-blocks      Used Available Use% Mounted on
    /very/long/device/path
                         124628916  23063572 100299192  19% /
    EOF
}

test_disk_size() {
    returns 1000 "disk_size /dev/sda1"

    DF=mock_df_with_eols
    returns 124628916 "disk_size /very/long/device/path"
}

df_column() {
    local disk_device=$1
    local column=$2

    $DF $disk_device \
        | grep -v 'Use%' \
        | tr '\n' ' ' \
        | awk "{print \$$column}"
}

disk_size() {
    local disk_device=$1

    df_column $disk_device 2
}