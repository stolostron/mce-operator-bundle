FROM scratch

COPY ./manifests /manifests
COPY ./metadata /metadata
COPY ./extras /extras

LABEL com.redhat.delivery.operator.bundle="true" \ \
      operators.operatorframework.io.bundle.mediatype.v1="registry+v1" \
      operators.operatorframework.io.bundle.manifests.v1="manifests/" \
      operators.operatorframework.io.bundle.metadata.v1="metadata/" \
      operators.operatorframework.io.bundle.package.v1="multicluster-engine" \
      operators.operatorframework.io.bundle.channels.v1="stable-2.8" \
      com.redhat.openshift.versions="v4.15-v4.19"
      cpe="cpe:/a:redhat:multicluster_engine:2.8::el9"

LABEL com.redhat.component="multicluster-engine-operator-bundle-container" \
      name="multicluster-engine/mce-operator-bundle" \
      version="2.8.5-186" \
      summary="multicluster-engine-operator-bundle" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="multicluster-engine-operator-bundle" \
      io.k8s.description="Operator bundle for Red Hat Multicluster engine" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="multicluster-engine-operator-bundle" \
      konflux.additional-tags="v2.8.5-186,snapshot-release-mce-28-2kxdk" \
      vendor="Red Hat, Inc." \
      url="https://github.com/stolostron/mce-operator-bundle" \
      release="2.8.5-186" \
      distribution-scope="public" \
      cpe="cpe:/a:redhat:multicluster_engine:2.8::el9"
