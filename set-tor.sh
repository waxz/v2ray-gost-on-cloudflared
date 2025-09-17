# setup tor

hashpass=$(tor --hash-password "$TOR_PASSWORD")
sudo sed -i "s/.*HashedControlPassword.*/HashedControlPassword $hashpass/" /etc/tor/torrc

cat << EOF | sudo tee -a /etc/tor/torrc
SocksPort 0.0.0.0:9060
ControlPort 0.0.0.0:9061
CookieAuthentication 0

ExcludeNodes {cn},{hk},{mo},{kp},{ir},{sy},{pk},{cu},{vn}
MiddleNodes {GE},{IT},{HU},{AT},{HR},{RO},{PL},{FR},{FI},{SE},{IS},{NO},{IE},{EE},{DK},{LT},{CZ},{BE},{GR},{RS},{BG},{TR},{ES},{NL}
ExitNodes {GB}
#ExitNodes {GE},{IT},{HU},{AT},{HR},{RO},{PL},{FR},{FI},{SE},{IS},{NO},{IE},{EE},{DK},{LT},{CZ},{BE},{GR},{RS},{BG},{TR},{ES},{NL}

EOF
