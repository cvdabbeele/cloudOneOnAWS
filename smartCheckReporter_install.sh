git clone https://github.com/mawinkler/vulnerability-management.git
PREVIOUS_DIR=`pwd`
cd vulnerability-management/cloudone-image-security/scan-report
# cp config.yml.sample config.yml
# sudo apt install python3-pip -y
pip3 install -r requirements.txt
pip3 install  fpdf requests simplejson urllib3


cat <<EOF>config.yml
dssc:
  service: "${DSSC_HOST}:443"
  username: "${DSSC_USERNAME}"
  password: "${DSSC_PASSWORD}"

repository:
  name: "C101c1appsecmoneyx"   #NO PATH HERE, JUST THE REPO NAME
  image_tag: "latest"

criticalities:
  - defcon1
  - critical
  - high
  - medium
EOF
cat config.yml

python3 scan-report.py


cd $PREVIOUS_DIR
