RELEASE=3.2

SVER=4.0
PACKAGERELEASE=1pve6
ARCH=amd64

PACKAGE=vzctl
DEB=${PACKAGE}_${SVER}-${PACKAGERELEASE}_${ARCH}.deb

VZCTL_BRANCH=master  # vzctl-4.0 does not exist

all: ${DEB}

vzctl-${SVER}.org/COPYING: vzctl-${SVER}.org.tgz
	tar xzf $<
	touch $@

.PHONY: download
vzctl-${SVER}.org.tgz download:
	rm -rf vzctl-${SVER}.org vzctl-${SVER}.org.tgz
	git clone git://git.openvz.org/pub/vzctl -b ${VZCTL_BRANCH} vzctl-${SVER}.org
	tar czf vzctl-${SVER}.org.tgz vzctl-${SVER}.org


vzctl-${SVER}/debian/control: vzctl-${SVER}.org/COPYING
	rm -rf vzctl-${SVER}
	rsync -av vzctl-${SVER}.org/ vzctl-${SVER}
	rsync -av --exclude .svn debian/ vzctl-${SVER}/debian
	cd vzctl-${SVER}; ./autogen.sh
	touch $@


.PHONY: deb
${DEB} deb: vzctl-${SVER}/debian/control
	chmod +x vzctl-${SVER}/debian/rules
	cd vzctl-${SVER}; dpkg-buildpackage -b -rfakeroot -us -uc
	lintian ${DEB}

.PHONY: upload
upload: ${DEB}
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw 
	mkdir -p /pve/${RELEASE}/extra
	rm -f /pve/${RELEASE}/extra/${PACKAGE}_*.deb
	rm -f /pve/${RELEASE}/extra/Packages*
	cp ${DEB} /pve/${RELEASE}/extra
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

.PHONY: distclean
distclean: clean
	rm -rf vzctl-${SVER}.tgz  vzctl-${SVER}.org

.PHONY: clean
clean:
	rm -rf vzctl-${SVER} vzctl_${SVER}* *~ debian/*~ debian/patches/*~ *.tmp a.out

.PHONY: dinstall
dinstall: deb
	dpkg -i ${DEB}

