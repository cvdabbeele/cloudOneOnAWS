mkdir dssc${C1PROJECT}logs
cd dssc${C1PROJECT}logs
wget -q https://raw.githubusercontent.com/deep-security/smartcheck-helm/master/collect-logs.sh
chmod 755 collect-logs.sh
export NAMESPACE='smartcheck' 
echo 'Collecting logs from SmartCheck in namespace smartcheck'
echo '-------------------------------------------------------'
./collect-logs.sh
echo after script
zip -r smartcheck.logs.zip /tmp/smartcheck-*
mv smartcheck.logs.zip ../.
cd ..
rm -rf dssc${C1PROJECT}logs

echo 'All the SmartCheck logfiles can be found in smartcheck.logs.zip in the current directory'
echo '----------------------------------------------------------------------------------------'