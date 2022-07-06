## Preparations

*How to set up your system for our **OBS** repositories.*

<br>

***Make sure to use the correct version for your distribution.***

<br>

### Debian Bullseye

```shell
echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Debian_Bullseye/ /'    \
    | sudo tee /etc/apt/sources.list.d/home-ungoogled_chromium.list                                 \
    > /dev/null
```

```shell
curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Debian_Bullseye/Release.key'   \
    | gpg --dearmor                                                                                         \
    | sudo tee /etc/apt/trusted.gpg.d/home-ungoogled_chromium.gpg                                           \
    > /dev/null
```

<br>

### Debian Sid

```shell
echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Debian_Sid/ /' \
    | sudo tee /etc/apt/sources.list.d/home-ungoogled_chromium.list                         \
    > /dev/null
```

```shell
curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Debian_Sid/Release.key'    \
    | gpg --dearmor                                                                                     \
    | sudo tee /etc/apt/trusted.gpg.d/home-ungoogled_chromium.gpg                                       \
    > /dev/null
```

<br>

### Ubuntu Focal

```shell
echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Ubuntu_Focal/ /'   \
    | sudo tee /etc/apt/sources.list.d/home-ungoogled_chromium.list                             \
    > /dev/null
```

```shell
curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Ubuntu_Focal/Release.key'  \
    | gpg --dearmor                                                                                     \
    | sudo tee /etc/apt/trusted.gpg.d/home-ungoogled_chromium.gpg                                       \
    > /dev/null
```
<br>

### Ubuntu Impish

```shell
echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Ubuntu_Impish/ /'  \
    | sudo tee /etc/apt/sources.list.d/home-ungoogled_chromium.list                             \
    > /dev/null
```

```shell
curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Ubuntu_Impish/Release.key' \
    | gpg --dearmor                                                                                     \
    | sudo tee /etc/apt/trusted.gpg.d/home-ungoogled_chromium.gpg                                       \
    > /dev/null
```
  
  
<br>

## Installation

*Once you have set up your system, you* <br>
*can install the **Ungoogled Chromium**.*

```shell
sudo apt update
```

```shell
sudo apt install -y ungoogled-chromium
```