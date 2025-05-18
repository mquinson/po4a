define diff_pod_and_simplepod
diff-$1:
	-diff ../pod/$1.norm $1.norm
	-diff ../pod/$1.pot $1.pot
	-diff ../pod/$1.po $1.po
	-diff ../pod/$1.trans $1.trans
.PHONY: diff-$1

endef

diff: diff-basic diff-issues diff-podlators
.PHONY: diff

$(eval $(call diff_pod_and_simplepod,basic))
$(eval $(call diff_pod_and_simplepod,issues))
$(eval $(call diff_pod_and_simplepod,podlators))
$(eval $(call diff_pod_and_simplepod,misc))

update:
	touch po4a.cfg
	po4a po4a.cfg
.PHONY: update
