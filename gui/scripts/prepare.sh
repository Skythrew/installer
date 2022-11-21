#! /bin/sh

# This is an example preparation script. For OS-Installer to use it, place it at:
# /etc/os-installer/scripts/prepare.sh
# The script gets called when an active internet connection was established.

echo 'Preparation started.'

# Install squirrel
echo "Installing squirrel on the host system..."
git clone --branch 1.0.2 https://github.com/stock-linux/squirrel.git
ln -s $PWD/squirrel/squirrel /bin/squirrel
echo "Done"

echo "Configuring squirrel..."
echo -e "#!/bin/sh\npython3 $PWD/squirrel/main.py \$@" > squirrel/squirrel
chmod +x squirrel/squirrel
mkdir -p $PWD/squirrel/dev/etc/squirrel/ $PWD/squirrel/dev/var/squirrel/repos/dist/ $PWD/squirrel/dev/var/squirrel/repos/local/ $PWD/squirrel/dev/var/squirrel/repos/local/main/
echo "Done"

echo "Installing squirrel dependencies..."
pip3 install docopt pyaml requests packaging
echo "Done"

echo "Final configuration for squirrel..."
echo "configPath = '$PWD/squirrel/dev/etc/squirrel/'" > squirrel/utils/config.py
echo "distPath = '$PWD/squirrel/dev/var/squirrel/repos/dist/'" >> squirrel/utils/config.py
echo "localPath = '$PWD/squirrel/dev/var/squirrel/repos/local/'" >> squirrel/utils/config.py

echo "main http://stocklinux.hopto.org:8080/45w22/main" > squirrel/dev/etc/squirrel/branches
echo "cli http://stocklinux.hopto.org:8080/45w22/cli" >> squirrel/dev/etc/squirrel/branches
echo "gui http://stocklinux.hopto.org:8080/45w22/gui" >> squirrel/dev/etc/squirrel/branches
echo "extra http://stocklinux.hopto.org:8080/45w22/extra" >> squirrel/dev/etc/squirrel/branches

touch $PWD/squirrel/dev/var/squirrel/repos/local/main/INDEX
echo "Done"

echo "Everything is configured !"

exit 0
