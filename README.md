## Description:
This is a base Magento image. For simplicity, the usage guide below will assume that you run it on your local machine. However, the resulted image can be deployed to the server easily with little modification. Magento2 installation on Ubunu based on: https://linuxize.com/post/how-to-install-magento-2-on-ubuntu-18-04/

## Prereq:
To be able to access to the Magento 2 code repository you’ll need to generate authentication keys. If you don’t have a Magento Marketplace account, you can create one [here](https://www.magentocommerce.com/products/applications/customer/create/). Once you create the account, please check [these instructions](https://devdocs.magento.com/guides/v2.3/install-gde/prereq/connect-auth.html) on how to generate a new set of authentication keys.

## Usage:

Set up a dev environment with Magento and DB running on docker with docker compose file below:

```
version: '3.3'

services:
  db:
    image: mysql:5.7
    ports:
      - "3306:3306"
    volumes:
      - ./db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: magento
      MYSQL_USER: magento
      MYSQL_PASSWORD: magento
  magento:
    image: deanzaka/magento-base:2.0.0
    volumes:
      - ./magento_data:/var/www/html/magento2
    ports:
      - "80:80"
      - "443:443"
    restart: always
```
If you run it for the first time it will say:

```
Composer project not found, please follow instruction at:
https://cloud.docker.com/u/deanzaka/repository/docker/deanzaka/magento-base
```

It means you need to create a new Composer project using the Magento Open Source or Magento Commerce metapackage. Run one of these two commands below corresponds to your magento account. Don't forget to change [YOUR_CONTAINER_ID] to your container id.

### Magento Open Source (Community Edition)
```
CONTAINER_ID=[YOUR_CONTAINER_ID]
docker exec -it ${CONTAINER_ID} composer create-project --repository=https://repo.magento.com/ magento/project-community-edition /var/www/html/magento2 
```

### Magento Commerce (Enterprise Edition)
```
CONTAINER_ID=[YOUR_CONTAINER_ID]
docker exec -it ${CONTAINER_ID} composer create-project --repository=https://repo.magento.com/ magento/project-enterprise-edition /var/www/html/magento2
```

please run one of the commands above corresponds to your Magento account.
You’ll be prompted to enter the access keys, copy the keys from your Magento marketplace account and store them in the auth.json file, so later when updating your installation you don’t have to add the same keys again. The command above will fetch all required PHP packages. The process may take a few minutes.

After the downloads complete. Start your Magento installation by getting inside the docker container and set read-write permissions for the web server group before you install the Magento software. This is necessary so that the Setup Wizard and command line can write files to the Magento file system.

```
docker exec -it {CONTAINER_ID} /bin/bash
cd magento2
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
sudo chown -R :www-data . # Ubuntu
chmod u+x bin/magento
```

still inside the container, run the installation. Don't forget to change [YOUR_DB_HOST] to your db host. If you are using deployed docker db from provided compose file, then your db host will be `db`.
```
DB_HOST=[YOUR_DB_HOST]
php bin/magento setup:install \
  --admin-firstname="admin" \
  --admin-lastname="admin" \
  --admin-email="admin@local.domain.com" \
  --admin-user="admin" \
  --admin-password="admin123" \
  --base-url=http://local.domain.com/ \
  --base-url-secure=https://local.domain.com/ \
  --db-host=${DB_HOST} \
  --db-name=magento \
  --db-user=magento \
  --db-password=magento \
  --language=en_US \
  --currency=IDR \
  --timezone=Asia/Jakarta \
  --use-rewrites=1
```

switch to developer mode
```
bin/magento deploy:mode:set developer
```


## Configure nginx:

Create a new virtual host configuration for your Magento site:
```
sudo nano /var/www/html/config/magento
```

Add the following configuration:
```
upstream fastcgi_backend {
  server  unix:/run/php/php7.2-fpm.sock;
}

server {
  listen 80;
  server_name local.domain.com;
  set $MAGE_ROOT /var/www/html/magento2;
  include /var/www/html/magento2/nginx.conf.sample;
}
```

Create a symlink for newly created configuration to nginx sites available folder
```
sudo ln -sf /var/www/html/config/magento /etc/nginx/sites-available
```

Activate the newly created virtual host by creating a symlink to it in the /etc/nginx/sites-enabled directory:
```
sudo ln -sf /var/www/html/config/magento /etc/nginx/sites-enabled
```

Verify that the syntax is correct:
```
sudo nginx -t
```

Restart nginx
```
sudo service nginx restart
```

The reason why we created the configuration in our current folder is to store the configuration on the mounted path and retain the value. On the first creation or modification, we need to create a symlink of the config file to nginx folder manually. But, in the next container spin up, the config will be copied and activated automatically as part of the image default command.

Exit the container by running:
```
exit
```

In your local machine, add local.domain.com to your /etc/host by running
```
sudo -- sh -c "echo '127.0.0.1 local.domain.com' >> /etc/hosts"
```

Now, on your browser go to **http://local.domain.com** to check your site