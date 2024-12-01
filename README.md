# ministra-ubuntu-24.04

> This installation only works on a clean install of Ubuntu 24.04.

## Installation

1. Run the following in the terminal.

    ```sh
    sudo wget https://raw.githubusercontent.com/edik1963/ministra-ubuntu-24.04/refs/heads/main/install.sh && sudo chmod +x install.sh && sudo ./install.sh -y
    ```


## Change Admin Password

1. Change the password for *admin* user.

    ```sh
    mysql -u stalker -p <password-for-stalker-user>
    use stalker_db
    update administrators set pass=MD5('<new-password>') where login='admin';
    exit
    ```
    > Please replace <password-for-stalker-user> and <new-password> with your choices.

2. Restart mysql service.

    ```sh
    /etc/init.d/mysql restart
    ```


## Remove all test channels from the database.

1. Run the following commands in a terminal.

    ```sh
    mysql -u root -p stalker_db
    truncate ch_links;
    truncate itv;
    exit
    ```

2. Restart mysql service.

    ```sh
    /etc/init.d/mysql restart
    ```