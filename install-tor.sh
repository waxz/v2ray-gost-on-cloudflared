UBUNTU_RELEASE=$(bash <(cat /etc/os-release; echo 'echo ${VERSION_ID/*, /}'))
UBUNTU_CODENAME=$(bash <(cat /etc/os-release; echo 'echo ${UBUNTU_CODENAME/*, /}'))
ARCH=$(dpkg --print-architecture)

sudo rm /etc/apt/sources.list.d/tor.list 
cat << EOF | sudo tee -a /etc/apt/sources.list.d/tor.list
deb     [signed-by=/usr/share/keyrings/deb.torproject.org-keyring.gpg] https://deb.torproject.org/torproject.org $UBUNTU_CODENAME main
deb-src [signed-by=/usr/share/keyrings/deb.torproject.org-keyring.gpg] https://deb.torproject.org/torproject.org $UBUNTU_CODENAME main
EOF

wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | sudo tee /usr/share/keyrings/deb.torproject.org-keyring.gpg >/dev/null
sudo apt update
sudo apt install tor deb.torproject.org-keyring
sudo apt --fix-broken install
sudo apt install tor deb.torproject.org-keyring



# setup tor

hashpass=$(tor --hash-password "$TOR_PASSWORD")
sudo sed -i "s/.*HashedControlPassword.*/HashedControlPassword $hashpass/" /etc/tor/torrc

cat << EOF | sudo tee -a /etc/tor/torrc
SocksPort 0.0.0.0:9060
ControlPort 0.0.0.0:9061
CookieAuthentication 0

ExcludeNodes {cn},{hk},{mo},{kp},{ir},{sy},{pk},{cu},{vn}
MiddleNodes {GE},{IT},{HU},{AT},{HR},{RO},{PL},{FR},{FI},{SE},{IS},{NO},{IE},{EE},{DK},{LT},{CZ},{BE},{GR},{RS},{BG},{TR},{ES},{NL}
ExitNodes {GE},{IT},{HU},{AT},{HR},{RO},{PL},{FR},{FI},{SE},{IS},{NO},{IE},{EE},{DK},{LT},{CZ},{BE},{GR},{RS},{BG},{TR},{ES},{NL}

EOF

