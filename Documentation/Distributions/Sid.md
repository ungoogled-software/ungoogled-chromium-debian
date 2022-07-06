
# Debian Sid

*Execute the following commands to set up your system.*

<br>

```shell
echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Debian_Sid/ /' \
    | sudo tee /etc/apt/sources.list.d/home-ungoogled_chromium.list                         \
    > /dev/null
```

<br>

```shell
curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Debian_Sid/Release.key'    \
    | gpg --dearmor                                                                                     \
    | sudo tee /etc/apt/trusted.gpg.d/home-ungoogled_chromium.gpg                                       \
    > /dev/null
```

<br>