RELEASE=1.9

SVER=3.0.29
PACKAGERELEASE=2pve1
ARCH=amd64

PACKAGE=vzctl
DEB=${PACKAGE}_${SVER}-${PACKAGERELEASE}_${ARCH}.deb

VZCTL_BRANCH=vzctl-3.0.29.2

all: ${DEB}

vzctl-${SVER}.org/COPYING:
	git clone git://git.openvz.org/pub/vzctl vzctl-${SVER}.org
	# git branch -D local
	cd vzctl-${SVER}.org; git checkout -b local ${VZCTL_BRANCH}	
	touch $@

vzctl-${SVER}.tgz: vzctl-${SVER}.org/COPYING
	tar czf $@.tmp vzctl-${SVER}.org
	mv $@.tmp $@


vzctl-${SVER}/debian/control: vzctl-${SVER}.org/COPYING
	rm -rf vzctl-${SVER}
	rsync -av vzctl-${SVER}.org/ vzctl-${SVER}
	rsync -av --exclude .svn debian/ vzctl-${SVER}/debian
	cd vzctl-${SVER}; ./autogen.sh
	touch $@

${DEB}: vzctl-${SVER}/debian/control
	chmod +x vzctl-${SVER}/debian/rules
	cd vzctl-${SVER}; dpkg-buildpackage -b -rfakeroot -us -uc
	lintian ${DEB}

.PHONY: upload
upload: vzctl-${SVER}.tgz ${DEB}
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw 
	mkdir -p /pve/${RELEASE}/extra
	rm -f /pve/${RELEASE}/extra/${PACKAGE}_*.deb
	rm -f /pve/${RELEASE}/install/vzctl-*.tgz
	rm -f /pve/${RELEASE}/extra/Packages*
	cp ${DEB} /pve/${RELEASE}/extra
	cp vzctl-${SVER}.tgz /pve/${RELEASE}/install
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

.PHONY: distclean
distclean: clean
	rm -rf vzctl-${SVER}.tgz  vzctl-${SVER}.org

.PHONY: clean
clean:
	rm -rf vzctl-${SVER} vzctl_${SVER}* *~ debian/*~ debian/patches/*~ *.tmp a.out
