all: organization contact log misc

organization: outfolder
	cd OrganizationServer/ && pub get && pub upgrade
	dart2js --output-type=dart --checked --verbose --out=out/OrganizationServer.dart --categories=Server OrganizationServer/bin/organizationserver.dart

contact: outfolder
	cd ContactServer/ && pub get && pub upgrade
	dart2js --output-type=dart --checked --verbose --out=out/ContactServer.dart --categories=Server ContactServer/bin/contactserver.dart

log: outfolder
	cd LogServer/ && pub get && pub upgrade
	dart2js --output-type=dart --checked --verbose --out=out/LogServer.dart --categories=Server LogServer/bin/logserver.dart

misc: outfolder
	cd MiscServer/ && pub get && pub upgrade
	dart2js --output-type=dart --checked --verbose --out=out/MiscServer.dart --categories=Server MiscServer/bin/miscserver.dart

outfolder:
	-mkdir out

clean: 
	-rm out
