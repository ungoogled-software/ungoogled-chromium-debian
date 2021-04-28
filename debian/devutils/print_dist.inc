print_dist()
{
    (
        . /etc/os-release
        case "$ID" in
            debian) ID=Debian ;;
            ubuntu) ID=Ubuntu ;;
        esac
        echo "$ID $VERSION_CODENAME/$VERSION_ID"
    )
}