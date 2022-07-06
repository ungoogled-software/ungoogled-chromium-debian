
# Ubuntu Impish

*Execute the following commands to set up your system.*

<br>

```shell
echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Ubuntu_Impish/ /'  \
    | sudo tee /etc/apt/sources.list.d/home-ungoogled_chromium.list                             \
    > /dev/null
```

<br>

```shell
curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Ubuntu_Impish/Release.key' \
    | gpg --dearmor                                                                                     \
    | sudo tee /etc/apt/trusted.gpg.d/home-ungoogled_chromium.gpg                                       \
    > /dev/null
```

<br>